defmodule Shophawk.Jobboss_db_job do
  import Ecto.Query, warn: false
  import Shophawk.Jobboss_db
  alias DateTime
  alias Shophawk.Jb_job
  alias Shophawk.Jb_job_operation
  alias Shophawk.Jb_material_req
  alias Shophawk.Jb_job_operation_time
  alias Shophawk.Jb_user_values
  alias Shophawk.Jb_attachment
  alias Shophawk.Jb_delivery

  def load_all_active_jobs() do
    job_numbers =
      Jb_job
      |> where([j], j.status == "Active")
      |> where([j], not is_nil(j.customer))
      |> select([j], j.job)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()

    Cachex.put_many(:active_jobs, load_job_history(job_numbers))
  end

  def load_part_history_jobs() do
    job_numbers =
      Jb_job
      |> where([j], j.status == "Closed" or j.status == "Complete")
      |> where([j], not is_nil(j.customer))
      |> order_by([j], desc: j.last_updated)
      |> select([j], [j.job, j.last_updated])
      |> distinct(true)
      |> limit(10000)
      |> Shophawk.Repo_jb.all()
      |> Enum.map(fn entry -> List.first(entry) end)

    Cachex.put_many(:temporary_runlist_jobs_for_history, load_job_history(job_numbers))
  end

  def job_exists?(job_number), do: Shophawk.Repo_jb.exists?(from r in Jb_job, where: r.job == ^job_number)

  def load_job_history(full_job_numbers_list) when is_list(full_job_numbers_list) do #loads all routing operations with a matching job
    full_job_numbers_list =
      full_job_numbers_list
      |> Enum.reject(fn j -> j == nil end)
      |> Enum.reject(fn j -> j == "" end)

    Enum.chunk_every(full_job_numbers_list, 50)
    |> Enum.map(fn job_numbers ->
      #NEED TO MERGE DELIVERIES TO JOB MAPS AND THEN CLEAN UP UNESED FUNCTIONS IN THIS AND SHOW_JOB PAGES
      {jobs_map, mats_map, user_values_map, deliveries_map, operation_time_map, job_operation_numbers, operations_map, attachments_map} = jobboss_queries_for_jobs(job_numbers)
      #operations show up
      operations = #merge all operation data from JB
        operations_map
        |> merge_job_data(jobs_map)
        |> merge_material_data(mats_map)
        |> merge_operation_time_data(operation_time_map)
        |> merge_jb_user_values(user_values_map)
        |> add_runlist_user_values()
        |> Enum.reject(fn op -> op.job_sched_end == nil end)
        #merge data from shophawk db into routing operations (ie. assignments, mat_waiting)
        |> merge_shophawk_runlist_db(job_operation_numbers)
        |> Enum.group_by(&{&1.job})
        |> Enum.map(fn {{job}, job_ops} ->
          updated_job_ops =
            set_current_op(job_ops)
            |> set_material_waiting()
            |> set_assignment_from_note_text_if_op_started()
            |> convert_nil_values_to_empty_strings_for_ops()
            |> Enum.sort_by(&(&1.sequence))
          {job, updated_job_ops}
        end)

      Enum.map(job_numbers, fn job_number ->

        matching_operations =
          case Enum.find(operations, fn {job_key, _data} -> job_key == job_number end) do
            nil -> []
            {_job, found_ops} -> found_ops
          end

        first_op_job_map = Enum.find(jobs_map, fn {jn, _} -> jn == job_number end) |> elem(1) |> List.first() || %{}
        user_value = first_op_job_map[:user_values]

        user_values_map =
          user_values_map
          |> Enum.find(%{dots: nil}, &(&1.user_values == user_value))

        mats_reqs = Map.get(mats_map, job_number, %{})

        merged_first_op_job_map =
          Map.merge(first_op_job_map, user_values_map)
          |> Map.put(:material_reqs, mats_reqs)

        job_info = create_job_info(merged_first_op_job_map, deliveries_map, matching_operations, attachments_map)

        {job_number, %{
          job: job_number,
          id: "id-" <> job_number,
          job_status: merged_first_op_job_map[:job_status],
          job_ops: matching_operations,
          job_info: job_info
        }}
      end)
    end)
    |> List.flatten()
  end

  defp jobboss_queries_for_jobs(job_numbers) do
    job_query = fn ->
      failsafed_query(from r in Jb_job, where: r.job in ^job_numbers)
      |> Enum.group_by(& &1.job)
      |> Enum.map(fn {job_number, jobs} ->
        {job_number, Enum.map(jobs, fn op ->
          Map.from_struct(op)
          |> Map.drop([:__meta__])
          |> rename_key(:sched_end, :job_sched_end)
          |> rename_key(:sched_start, :job_sched_start)
          |> rename_key(:status, :job_status)
          |> rename_key(:customer_po_ln, :customer_po_line)
          |> sanitize_map()
        end)}
      end)
    end

    operation_query = fn ->
      query = from r in Jb_job_operation, where: r.job in ^job_numbers
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> rename_key(:note_text, :operation_note_text)
        |> sanitize_map()
      end)
    end

    material_query = fn ->
      failsafed_query(from r in Jb_material_req, where: r.job in ^job_numbers)
      |> Enum.group_by(& &1.job)
      |> Enum.map(fn {job_number, mats} ->
        {job_number, Enum.map(mats, fn op ->
          Map.from_struct(op)
          |> Map.drop([:__meta__, :job])
          |> rename_key(:status, :mat_status)
          |> rename_key(:description, :mat_description)
          |> sanitize_map()
        end)}
      end)
      |> Map.new()
    end


    deliveries_query = fn ->
      query = from r in Jb_delivery, where: r.job in ^job_numbers and r.promised_quantity > 0
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.put(:deliveryo, Integer.to_string(op.delivery))
        |> Map.drop([:delivery])
        |> sanitize_map()
        #|> Enum.sort_by(&(&1.promised_date), {:asc, Date})
      end)
    end

    attachments_query = fn ->
      query = from r in Jb_attachment, where: r.owner_id in ^job_numbers
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> sanitize_map()
        |> rename_key(:attach_path, :path)
        |> rename_key(:owner_id, :job)
      end)
    end


    # Run the first three queries concurrently
    tasks = [
      {:jobs, job_query},
      {:operations, operation_query},
      {:materials, material_query},
      {:deliveries, deliveries_query},
      {:attachments, attachments_query}
    ]

    # Execute tasks concurrently and collect results
    results =
      Task.async_stream(tasks, fn {key, task} -> {key, task.()} end, timeout: :infinity)
      |> Enum.into(%{}, fn {:ok, {key, result}} -> {key, result} end)

    # Extract results
    jobs_map = results[:jobs]
    operations_map = results[:operations]
    deliveries_map = results[:deliveries]
    mats_map = results[:materials]
    attachments_map = results[:attachments]
    updated_mats_maps = #group together mats by job and change values as needed
      Enum.map(job_numbers, fn job_number ->
        mats = Map.get(mats_map, job_number, [])
        updated_mats =
          case Enum.count(mats) do
            0 ->
              empty_map =
                Map.from_struct(%Jb_material_req{})
                |> Map.drop([:__meta__])
                |> Map.drop([:status, :description, :job])
                |> Map.put(:material, "Customer Supplied")
                |> sanitize_map()
                [empty_map]
            _ ->
              mats
          end
        {job_number, updated_mats}
      end)
      |> Map.new()

    # Extract dependencies for subsequent queries
    job_operation_numbers = Enum.map(operations_map, fn op -> op.job_operation end)
    user_values_list =
      jobs_map
      |> Enum.flat_map(fn {_job_number, jobs} -> Enum.map(jobs, & &1.user_values) end)
      |> Enum.uniq()

    # Define the dependent query functions
    operation_time_query = fn ->
      query = from r in Jb_job_operation_time, where: r.job_operation in ^job_operation_numbers
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> sanitize_map()
       end)
    end

    user_values_query = fn ->
      failsafed_query(from r in Jb_user_values, where: r.user_values in ^user_values_list)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.put(:text1, dots_calc(op.text1))
        |> rename_key(:text1, :dots)
        |> sanitize_map()
      end)
      #|> Enum.group_by(& &1.user_values)
    end

    # Run the last two queries concurrently
    dependent_tasks = [
      {:operation_time, operation_time_query},
      {:user_values, user_values_query}
    ]

    # Execute dependent tasks concurrently and collect results
    dependent_results =
      Task.async_stream(dependent_tasks, fn {key, task} -> {key, task.()} end, timeout: :infinity)
      |> Enum.into(%{}, fn {:ok, {key, result}} -> {key, result} end)

    # Extract final results
    operation_time_map = dependent_results[:operation_time]
    user_values_map = dependent_results[:user_values]

    {jobs_map, updated_mats_maps, user_values_map, deliveries_map, operation_time_map, job_operation_numbers, operations_map, attachments_map}
  end

  defp merge_job_data(ops, jobs_map) do
    Enum.map(ops, fn %{job: job} = op ->
      {_jn , [data]} = Enum.find(jobs_map, fn {jn, _data} -> jn == job end)
      data = Map.drop(data, [:est_rem_hrs, :est_total_hrs, :est_labor, :est_material, :est_service, :act_total_hrs, :act_labor, :act_material, :act_service ])
      Map.merge(op, data)
    end)
  end

  defp merge_material_data(ops, mats_map) do
    Enum.map(ops, fn %{job: job} = op ->
        {_jn, mat} = Enum.find(mats_map, fn {jn, _data} -> jn == job end)
      Map.put(op, :material_reqs, mat)
    end)
  end

  defp merge_operation_time_data(ops, operation_time_map) do
    Enum.map(ops, fn %{job_operation: job_operation} = op ->
      matching_data =
        Enum.filter(operation_time_map, &(&1.job_operation == job_operation))
        |> Enum.sort_by(&(&1.work_date), {:asc, Date})
      starting_map =
        Map.from_struct(%Jb_job_operation_time{})
        |> Map.drop([:__meta__])
        |> Map.drop([:job_operation])
        |> Map.put(:full_employee_log, [])
      combined_data_collection = #merges all time entry data for the specific operation
        if matching_data != [] do
          Enum.reduce(matching_data, starting_map, fn row, acc ->
            acc
            |> Map.put(:act_run_labor_hrs, Float.round(((row.act_run_labor_hrs || 0) + acc.act_run_labor_hrs), 2))
            |> Map.put(:act_run_qty, (row.act_run_qty || 0) + acc.act_run_qty)
            |> Map.put(:act_scrap_qty, (row.act_scrap_qty || 0) + acc.act_scrap_qty)
            |> Map.put(:employee,
              case row.employee do
                "" -> acc.employee
                nil -> acc.employee
                _ -> acc.employee <> " | " <> row.employee <> ": " <> Calendar.strftime(row.work_date, "%m-%d-%y")
              end)
            |> Map.put(:full_employee_log, acc.full_employee_log ++ ["#{Calendar.strftime(row.work_date, "%m-%d-%y")}: #{row.employee} - #{row.act_run_labor_hrs} hrs"])
          end)
        else
          starting_map
        end
      new_map = Map.merge(op, combined_data_collection)
      trimmed_employee =
        if new_map.employee != nil do
          new_map.employee
          |> String.split("|")
          |> Enum.map(&String.trim/1)
          |> Enum.filter(fn x -> x != "" end)
          |> Enum.uniq
          |> Enum.join(" | ")
        else
          op.employee
        end
      Map.put(new_map, :employee, trimmed_employee)
    end)
  end

  defp merge_jb_user_values(ops, user_values_map) do
    Enum.map(ops, fn %{user_values: user_value} = op ->
      new_user_data = Enum.find(user_values_map, &(&1.user_values == user_value))
      if new_user_data do
        Map.merge(op, new_user_data)
      else
        Map.merge(op, Map.from_struct(%Jb_user_values{})
          |> Map.drop([:__meta__])
          |> Map.put(:text1, nil)
          |> rename_key(:text1, :dots))
      end
    end)
  end

  defp add_runlist_user_values(ops) do
    Enum.map(ops, fn map ->
      sanitize_map(map)
      |> Map.put(:id, "op-#{map.job_operation}")
      |> Map.put(:assignment, nil)
      |> Map.put(:currentop, nil)
      |> Map.put(:material_waiting, false)
      |> Map.put(:runner, false)
      |> Map.put(:date_row_identifer, nil)
    end)
  end

  defp create_job_info(job, deliveries_map, operations, attachments_map) do
    job_manager = case job.note_text do
      nil -> ""
      _ ->
        job.note_text
        |> String.replace("\r", " ")
        |> String.replace("\n", " ")
        |> String.split(" ")
        |> Enum.slice(-2, 2)
        |> Enum.map(&(String.capitalize(&1, :ascii)))
        |> Enum.join(" ")
        |> String.trim()
    end

    cost_each =
      case job.make_quantity do
        0 -> 0.0
        _ -> (job.act_labor + job.act_material + job.act_service) / job.make_quantity
      end
      |> Float.round(2)

    percent_profit =
      case cost_each do
        +0.0 ->
          previous_make_job = get_previous_make_job(job.part_number, job.order_date)

          previous_job_data =
            case Shophawk.RunlistCache.job(previous_make_job) do
              [] ->
                case Shophawk.RunlistCache.non_active_job(previous_make_job) do #check non-active job cache
                  [] ->
                    case Shophawk.Jobboss_db_job.load_job_history([previous_make_job]) do #load single job if no list is passed to function
                      [] ->
                        {:error}
                      [{_job, job_data}] ->
                        Cachex.put(:temporary_runlist_jobs_for_history, previous_make_job, job_data)
                        job_data
                    end
                  non_active_job ->
                    non_active_job
                end
              active_job -> active_job
            end

          case previous_job_data do
            {:error} -> 0.0
            job_list -> job_list.job_info.percent_profit
          end
        _ ->
          case job.unit_price do
            +0.0 -> 0.0
            _ -> (((job.unit_price - cost_each) / job.unit_price) * 100) #profit per each made, correct unlike jobboss for jobs with spares
          end
      end
      |> Float.round(2)

    percent_profit = #clears out profit value if it's an active job
      case job.job_status do
        "Active" -> 0.0
        _ -> percent_profit
      end

    current_op =
      case operations do
        [] -> ""
        _ -> List.last(operations).currentop
      end

    %{}
    |> Map.put(:part_number, to_string(job.part_number))
    |> Map.put(:rev, to_string(job.rev))
    |> Map.put(:order_quantity, job.order_quantity)
    |> Map.put(:pick_quantity, job.pick_quantity)
    |> Map.put(:make_quantity, job.make_quantity)
    |> Map.put(:spares_made, job.make_quantity - job.order_quantity)
    |> Map.put(:customer, job.customer)
    |> Map.put(:customer_po, job.customer_po)
    |> Map.put(:customer_po_line, job.customer_po_line)
    |> Map.put(:description, job.description)
    |> Map.put(:material_reqs, job.material_reqs)
    |> Map.put(:currentop, current_op)
    |> Map.put(:job_manager, job_manager)
    |> Map.put(:deliveries, filter_deliveries_for_job(job.job, deliveries_map))
    |> Map.put(:dots, job.dots)
    |> Map.put(:order_date, job.order_date)
    |> Map.put(:unit_price, Float.round(job.unit_price, 2))
    |> Map.put(:total_price, Float.round(job.total_price, 2))
    |> Map.put(:est_rem_hrs, Float.round(job.est_rem_hrs, 2))
    |> Map.put(:est_total_hrs, Float.round(job.est_total_hrs, 2))
    |> Map.put(:cost_each, Float.round(cost_each, 2))
    |> Map.put(:percent_profit, percent_profit)
    |> Map.put(:attachments, filter_attachments_for_job(job.job, attachments_map))

  end

  defp get_previous_make_job(part_number, date) do
    case part_number do
      nil -> ""
      _ ->
        {:ok, date} = NaiveDateTime.new(date, ~T[00:00:00])
        query =
          from(j in Jb_job,
          where: j.part_number == ^part_number and j.make_quantity > 0 and j.order_date < ^date,
          order_by: [desc: j.order_date],
          limit: 1,
          select: j.job
          )
      failsafed_query_one_result(query)
    end
  end

  defp filter_deliveries_for_job(job, deliveries_map) do
    Enum.filter(deliveries_map, fn d -> d.job == job end)
    |> Enum.sort_by(&(&1.promised_date), {:asc, Date})
  end

  defp filter_attachments_for_job(job, attachments_map) do
    Enum.filter(attachments_map, fn d -> d.job == job end)
  end

  defp convert_nil_values_to_empty_strings_for_ops(job_ops) do
    Enum.map(job_ops, fn op ->
      op = case op do
        %{operation_service: nil} -> Map.put(op, :operation_service, nil)
        %{operation_service: ""} -> Map.put(op, :operation_service, nil)
        %{operation_service: value} -> Map.put(op, :operation_service, " -" <> value)
        _ -> op
      end
      |> Map.put(:status, status_change(op.status))
      op = if op.rev == nil, do: Map.put(op, :rev, ""), else: Map.put(op, :rev, ", Rev: " <> op.rev)
      op = if op.customer_po_line == nil, do: Map.put(op, :customer_po_line, ""), else: op
      if op.operation_note_text == nil, do:  Map.put(op, :operation_note_text, ""), else: op
    end)
  end

  defp status_change(status) do
    case status do
      "C" -> "Closed"
      "S" -> "Started"
      "O" -> "Open"
      _ -> status
    end
  end

  defp set_current_op(job_ops) do
    {updated_maps, _, _} =
      Enum.reduce(job_ops, {[], nil, ""}, fn op, {acc, last_open_op, last_job} ->
        cond do
          op.status in ["O", "S"] and last_open_op == nil ->
            {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor, op.job}

          op.status in ["O", "S"] and last_open_op != nil ->
            {[%{op | currentop: last_open_op} | acc], last_open_op, op.job}

            op.status == "C" and op.job == last_job ->
              {[%{op | currentop: last_open_op} | acc], last_open_op, op.job}

            op.status == "C" ->
            {[%{op | currentop: nil} | acc], nil, op.job}

          true -> {[%{op | currentop: nil} | acc], nil, op.job}
        end
      end)
    Enum.reverse(updated_maps)
  end

  defp set_current_op_excluding_started(group) do #used for set_material_waiting only
    {updated_maps, _} =
      Enum.reduce(group, {[], nil}, fn op, {acc, last_open_op} ->
        cond do
          op.status in ["O"] and last_open_op == nil ->
            {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor}

          op.status in ["O"] and last_open_op != nil ->
            {[%{op | currentop: last_open_op} | acc], last_open_op}

          op.status == "C" ->
            {[%{op | currentop: nil} | acc], nil}

          true -> {[%{op | currentop: nil} | acc], nil}
        end
      end)
    Enum.reverse(updated_maps)
  end

  defp set_material_waiting(job_ops) do
    list = set_current_op_excluding_started(job_ops)

      {updated_maps, _, _} =
        Enum.reduce(list, {[], nil, false}, fn op, {acc, last_op, turn_off_mat_waiting} ->
          cond do
            op.currentop == "IN" ->
              case Shophawk.Shop.get_runlist_by_job_operation(op.job_operation) do
                nil -> Shophawk.Shop.create_runlist(%{job_operation: op.job_operation, material_waiting: true})
                op -> Shophawk.Shop.update_runlist(op, %{material_waiting: !op.material_waiting})
              end
              {[Map.put(op, :material_waiting, true) | acc], op.wc_vendor, false}

            op.currentop != "IN" and last_op == "IN" ->
              {[Map.put(op, :material_waiting, false) | acc], op.wc_vendor, true}

            op.currentop != "IN" and turn_off_mat_waiting == true ->
              {[Map.put(op, :material_waiting, false) | acc], op.wc_vendor, true}

            true -> {[op | acc], op.wc_vendor, false}
          end
        end)

    material_waiting_data = #creates list of maps of just the material_waiting and job_operation data
      Enum.reverse(updated_maps)
      |> List.flatten
      |> Enum.map(fn map -> Map.take(map, [:job_operation, :material_waiting]) end)

    Enum.map(List.flatten(job_ops), fn map -> #Merges material_waiting data with runlist
      matching_material_data = Enum.find(material_waiting_data, fn x -> x.job_operation == map.job_operation end)
      Map.merge(map, matching_material_data)
    end)
  end

  defp set_assignment_from_note_text_if_op_started(operations) do
    {:ok, employees} = Cachex.get(:employees, :data)

    Enum.map(operations, fn op ->
      if op.status == "S" do
        employee_initial =
          op.employee
          |> String.split("|")
          |> Enum.map(&String.trim/1)
          |> List.last
          |> String.split(":")
          |> List.first
        employee = Enum.find(employees, fn e -> e.employee == employee_initial end)
        name = if employee == nil, do: "", else: "#{employee.first_name} #{String.first(employee.last_name)}"
        Map.put(op, :assignment, name)
      else
        op
      end
    end)
  end

  defp merge_shophawk_runlist_db(ops, job_operation_numbers) do
    shophawk_runlist = Shophawk.Shop.load_all_ops_in_job_operation_list(job_operation_numbers)
    Enum.map(ops, fn op ->
      db_data =
        case Enum.find(shophawk_runlist, fn shophawk_op -> shophawk_op.job_operation == op.job_operation end) do
          nil -> %{}
          found ->
            Map.from_struct(found)
            |> Map.drop([:__meta__, :id, :inserted_at, :updated_at, :job_operation])
            |> sanitize_map()
        end
      Map.merge(op, db_data)
    end)
  end

  defp dots_calc(dots) do
    case dots do
      "0" -> 1
      "O" -> 1
      "o" -> 1
      1 -> 1
      "00" -> 2
      "OO" -> 2
      "oo" -> 2
      2 -> 2
      "000" -> 3
      "OOO" -> 3
      "ooo" -> 3
      3 -> 3
      _-> nil
    end
  end

  def update_workcenters do #check for new workcenters to be added for department workcenter selection
    one_year_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-365, :day)
    workcenters =
      Jb_job_operation
      |> where([j], j.last_updated >= ^one_year_ago)
      |> select([j], j.wc_vendor)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()
      |> Enum.sort

    saved_workcenters = Enum.map(Shophawk.Shop.list_workcenters, &(&1.workcenter))
    workcenters_to_ignore = ["y-"]
    workcenters
    |> Enum.reject(fn w -> Enum.member?(saved_workcenters, w) end) #filters out workcenters that already exist
    |> Enum.reject(fn w -> String.contains?(w, workcenters_to_ignore) end)
    |> Enum.each(fn workcenter ->
      Shophawk.Shop.create_workcenter(%{"workcenter" => workcenter})
    end)
  end

  def sync_recently_updated_jobs(previous_check) do
    #previous_check = NaiveDateTime.add(previous_check, -5, :hour) #convert to local time that jobboss DB uses
    query = from r in Jb_job, where: r.last_updated >= ^previous_check, select: r.job, distinct: true
    jobs = failsafed_query(query)
    query = from r in Jb_job_operation, where: r.last_updated >= ^previous_check, select: r.job, distinct: true
    job_operation_jobs = failsafed_query(query)
    query = from r in Jb_material_req, where: r.last_updated >= ^previous_check, select: r.job, distinct: true
    material_jobs = failsafed_query(query)
    query = from r in Jb_job_operation_time, where: r.last_updated >= ^previous_check, select: r.job_operation, distinct: true
    job_operation_time_ops = failsafed_query(query)
    query = from r in Jb_job_operation, where: r.job_operation in ^job_operation_time_ops, select: r.job, distinct: true
    job_operation_time_jobs = failsafed_query(query)

    jobs_to_update = jobs ++ job_operation_jobs ++ material_jobs ++ job_operation_time_jobs
    |> Enum.uniq

    job_tuples = load_job_history(jobs_to_update)

    Enum.each(job_tuples, fn {key, job_data} ->
      case job_data.job_status do
        "Active" ->
          Cachex.put(:active_jobs, key, job_data)
        _ ->
          Cachex.del(:active_jobs, key)
      end
    end)
  end

end
