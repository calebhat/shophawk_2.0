defmodule Shophawk.Jobboss_db do
    import Ecto.Query, warn: false
    alias DateTime
    alias Shophawk.Jb_job
    alias Shophawk.Jb_job_operation
    alias Shophawk.Jb_job_qty
    alias Shophawk.Jb_material_req
    alias Shophawk.Jb_job_operation_time
    alias Shophawk.Jb_user_values
    alias Shophawk.Jb_employees
    alias Shophawk.Jb_holiday
    alias Shophawk.Jb_attachment
    alias Shophawk.Jb_BankHistory
    alias Shophawk.Jb_JournalEntry
    alias Shophawk.Jb_InvoiceHeader
    alias Shophawk.Jb_job_delivery
    alias Shophawk.Jb_delivery
    alias Shophawk.Jb_job_note_text
    alias Shophawk.Jb_address
    alias Shophawk.Jb_material
    alias Shophawk.Jb_material_location
    alias Shophawk.Jb_Ap_Check
    #This file is used for all loading and ecto calls directly to the Jobboss Database.

  def load_all_active_jobs() do
    job_numbers =
      Jb_job
      |> where([j], j.status == "Active")
      |> where([j], not is_nil(j.customer))
      |> select([j], j.job)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()

    active_jobs = load_job_history(job_numbers)

    Cachex.put_many(:active_jobs, active_jobs)
    #Process.sleep(2000)

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
        merged_mats_map = Map.get(mats_map, job_number, %{})

        merged_first_op_job_map =
          Map.merge(first_op_job_map, user_values_map)
          |> Map.merge(merged_mats_map)

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

  def jobboss_queries_for_jobs(job_numbers) do
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
              Map.from_struct(%Jb_material_req{})
              |> Map.drop([:__meta__])
              |> Map.drop([:status, :description])
              |> Map.put(:material, "Customer Supplied")
              |> sanitize_map()
            1 ->
              Enum.at(mats, 0)
            _ ->
              Enum.reduce(mats, %{}, fn map, acc ->
                Map.merge(acc, map, fn _, value1, value2 ->
                  "#{value1} | #{value2}"
                end)
              end)
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

  def merge_job_data(ops, jobs_map) do
    Enum.map(ops, fn %{job: job} = op ->
      {_jn , [data]} = Enum.find(jobs_map, fn {jn, _data} -> jn == job end)
      data = Map.drop(data, [:est_rem_hrs, :est_total_hrs, :est_labor, :est_material, :est_service, :act_total_hrs, :act_labor, :act_material, :act_service ])
      Map.merge(op, data)
    end)
  end

  def merge_material_data(ops, mats_map) do
    Enum.map(ops, fn %{job: job} = op ->
      matching_maps =
        Enum.filter(mats_map, fn {jn, _data} -> jn == job end)
        |> Enum.map(fn {_jn, mat} -> mat end)
      case Enum.count(matching_maps) do
        0 ->
          Map.merge(op, Map.from_struct(%Jb_material_req{})
            |> Map.drop([:__meta__])
            |> Map.drop([:job, :status, :description]))
            |> Map.put(:material, "Customer Supplied")
            |> sanitize_map()
        1 ->
          Map.merge(op, Enum.at(matching_maps, 0))
        _ ->
          merged_matching_maps =
            Enum.reduce(matching_maps, %{}, fn map, acc ->
              map_without_job = Map.drop(map, [:job])
              Map.merge(acc, map_without_job, fn _, value1, value2 ->
                "#{value1} | #{value2}"
              end)
            end)
          Map.merge(op, merged_matching_maps)
      end
    end)
  end

  def merge_operation_time_data(ops, operation_time_map) do
    Enum.map(ops, fn %{job_operation: job_operation} = op ->
      matching_data = Enum.filter(operation_time_map, &(&1.job_operation == job_operation))
      starting_map =
        Map.from_struct(%Jb_job_operation_time{})
        |> Map.drop([:__meta__])
        |> Map.drop([:job_operation])
        |> Map.put(:full_employee_log, [])
      combined_data_collection =
        if matching_data != [] do
          Enum.reduce(matching_data, starting_map, fn row, acc ->
            acc
            |> Map.put(:act_run_labor_hrs, (row.act_run_labor_hrs || 0) + acc.act_run_labor_hrs)
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

  def merge_jb_user_values(ops, user_values_map) do
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

  def add_runlist_user_values(ops) do
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

  def create_job_info(job, deliveries_map, operations, attachments_map) do
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
                    case Shophawk.Jobboss_db.load_job_history([previous_make_job]) do #load single job if no list is passed to function
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
    |> Map.put(:material, job.material)
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

  def get_previous_make_job(part_number, date) do
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

  def filter_deliveries_for_job(job, deliveries_map) do
    Enum.filter(deliveries_map, fn d -> d.job == job end)
    |> Enum.sort_by(&(&1.promised_date), {:asc, Date})
  end

  def filter_attachments_for_job(job, attachments_map) do
    Enum.filter(attachments_map, fn d -> d.job == job end)
  end

  def filter_deliveries_for_job(job) do
    Shophawk.Jobboss_db.load_all_deliveries([job])
    #Enum.filter(deliveries_map, fn d -> d.job == job end)
    |> Enum.sort_by(&(&1.promised_date), {:asc, Date})
  end

  def convert_nil_values_to_empty_strings_for_ops(job_ops) do
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

  def sanitize_map(map) do #makes sure all values are in correct formats for the app.
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      value =
        value
        |> convert_binary_to_string()
        |> convert_to_date()
      Map.put(acc, key, value)
    end)
  end

  def convert_binary_to_string(value) when is_binary(value) do
    case :unicode.characters_to_binary(value, :latin1, :utf8) do
      {:error, _, _} ->
        :unicode.characters_to_binary(value, :latin1, :utf8)
      string -> string
    end
  end
  def convert_binary_to_string(value), do: value

  def convert_to_date(%NaiveDateTime{} = value), do: NaiveDateTime.to_date(value)
  def convert_to_date(value), do: value

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

  def merge_shophawk_runlist_db(ops, job_operation_numbers) do
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

  def dots_calc(dots) do
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

  def load_employees do
    query =
      from r in Jb_employees,
      where: r.status == "Active",
      order_by: [asc: r.employee]

    Shophawk.Repo_jb.all(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.drop([:status]) end)
  end

  def employee_data do
    query =
      from r in Jb_employees,
      where: r.status == "Active",
      order_by: [asc: r.employee]

    employees = Shophawk.Repo_jb.all(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.drop([:status]) end)
    user_values = Enum.reduce(employees, [], fn emp, acc -> if emp.user_values != nil, do: [emp.user_values | acc], else: acc end)

    query =
      from r in Jb_user_values,
      where: r.user_values in ^user_values

    birthdays =
      Shophawk.Repo_jb.all(query)
      |> Enum.map(fn x -> Map.from_struct(x) |> Map.drop([:__meta__]) |> Map.drop([:text1]) |> sanitize_map() end)

    Enum.reduce(employees, [], fn %{user_values: user_values} = employee, acc ->
      found_birthday = Enum.find(birthdays, &(&1.user_values == user_values))
      if found_birthday do
        [Map.merge(employee, found_birthday) |> rename_key(:date1, :birthday) |> rename_key(:user_values, :user_value) | acc ]
      else
        acc
      end
    end)

  end

  def load_holidays do
    query =
      from r in Jb_holiday,
      where: r.shift == "668B4614-5E2B-418E-B156-2045FA0E8CDF"

    Shophawk.Repo_jb.all(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() |> Map.drop([:shift]) end)
    |> Enum.map(fn %{holidaystart: holidaystart, holidayend: holidayend} ->
      for date <- Date.range(holidaystart, holidayend) do
        date
      end
    end)
    |> List.flatten()
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

  def export_attachments(job) do
    query =
      from r in Jb_attachment,
      where: r.owner_id == ^job

    Shophawk.Repo_jb.all(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> sanitize_map()
        |> rename_key(:attach_path, :path)
        |> rename_key(:owner_id, :job)
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

  def rename_key(map, old_key, new_key) do
    map
    |> Map.put(new_key, Map.get(map, old_key))  # Add the new key with the old key's value
    |> Map.delete(old_key)  # Remove the old key
  end

  ######
  #DASHBOARD PAGE FUNCTIONS
  ######

  def bank_statements do #monthly bank statements
    ten_years_ago = NaiveDateTime.add(NaiveDateTime.utc_now(), -3650, :day)
    query =
      from r in Jb_BankHistory,
      where: r.statement_date > ^ten_years_ago,
      where: r.bank == "Johnson Bank"
      #order_by: [asc: r.employee]

    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.drop([:bank]) |> sanitize_map() end)
  end

  def journal_entry(start_date, end_date) do #start_date and end_date are naive Time format
    query =
      from r in Jb_JournalEntry,
      where: r.transaction_date >= ^start_date and r.transaction_date <= ^end_date,
      where: r.gl_account == "104",
      order_by: [asc: r.transaction_date]
    failsafed_query(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def open_invoices() do
    query =
      from r in Jb_InvoiceHeader,
      where: r.open_invoice_amt > 0.0

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
      |> Enum.sort_by(&(&1.customer), :desc)
      |> Enum.with_index()
      |> Enum.map(fn {inv, index} -> Map.put(inv, :id, index) end)
      |> Enum.reverse
      |> Enum.map(fn inv ->
        inv =
          cond do
            inv.terms in ["Net 30 days", "1% 10 Net 30", "2% 10 Net 30", "Due On Receipt"] -> Map.put(inv, :terms, 30)
            inv.terms in ["Net 45 Days", "2% 10 NET 45", "NET 40 DAYS"] -> Map.put(inv, :terms, 45)
            inv.terms in ["NET 60 DAYS"] -> Map.put(inv, :terms, 60)
            inv.terms in ["Net 75 Days", "Net 60 mth end"] -> Map.put(inv, :terms, 75)
            inv.terms in ["NET 90 DAYS"] -> Map.put(inv, :terms, 90)
            true -> inv
          end
        inv = Map.put(inv, :open_invoice_amount, Float.round(inv.open_invoice_amt, 2))
        inv = Map.put(inv, :days_open, Date.diff(Date.utc_today(), inv.document_date))
        inv = if Date.diff(inv.due_date, Date.utc_today()) <= 0, do: Map.put(inv, :late, true), else: Map.put(inv, :late, false)

        cond do
          inv.days_open < 30 -> Map.put(inv, :column, 1)
          inv.days_open >= 30 and inv.days_open <= 60 -> Map.put(inv, :column, 2)
          inv.days_open > 60 and inv.days_open <= 90 -> Map.put(inv, :column, 3)
          inv.days_open > 90 -> Map.put(inv, :column, 4)
          true -> Map.put(inv, :column, 0)
        end
      end)
  end

  def active_jobs_with_cost() do
    query =
      from r in Jb_job_delivery,
      where: r.status == "Active"

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def released_jobs(date) do
    date = NaiveDateTime.new(date, ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_job_note_text,
      where: r.released_date == ^date

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def load_late_deliveries() do #All active deliveries
    today = NaiveDateTime.new(Date.utc_today(), ~T[00:00:00]) |> elem(1)
    two_years_ago = NaiveDateTime.new(Date.add(Date.utc_today(), -730), ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_delivery,
      where: is_nil(r.shipped_date) and
            r.promised_date < ^today and
            r.promised_date > ^two_years_ago and
            not like(r.job, "%lbr%") and
            not like(r.job, "%lvl%")

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_late_delivery_history() do #All active deliveries
    query =
      from r in Jb_delivery,
      where: r.shipped_date > r.promised_date and
            not like(r.job, "%lbr%") and
            not like(r.job, "%lvl%")

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_deliveries() do
    two_years_ago = NaiveDateTime.new(Date.add(Date.utc_today(), -730), ~T[00:00:00]) |> elem(1)

    query =
      from r in Jb_delivery,
      where: r.promised_date >= ^two_years_ago and r.promised_quantity > r.shipped_quantity

      list =
        failsafed_query(query)
        |> Enum.map(fn op ->
          Map.from_struct(op)
          |> Map.drop([:__meta__])
          |> Map.put(:deliveryo, Integer.to_string(op.delivery))
          |> Map.drop([:delivery])
          |> sanitize_map()
        end)

        Enum.map(list, fn op ->
          Map.put(op, :delivery, op.deliveryo)
          |> Map.drop([:deliveryo])
        end)
        |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_deliveries(job_numbers) do
    query =
      from r in Jb_delivery,
      where: r.job in ^job_numbers and r.promised_quantity > 0 and is_nil(r.shipped_date) and is_nil(r.packlist)

    list =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.put(:deliveryo, Integer.to_string(op.delivery))
        |> Map.drop([:delivery])
        |> sanitize_map()
      end)

      Enum.map(list, fn op ->
        Map.put(op, :delivery, op.deliveryo)
        |> Map.drop([:deliveryo])
      end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_all_deliveries(job_numbers) do
    query =
      from r in Jb_delivery,
      where: r.job in ^job_numbers and r.promised_quantity > 0

    list =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.put(:deliveryo, Integer.to_string(op.delivery))
        |> Map.drop([:delivery])
        |> sanitize_map()
      end)

      Enum.map(list, fn op ->
        Map.put(op, :delivery, op.deliveryo)
        |> Map.drop([:deliveryo])
      end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_active_deliveries(job_numbers) do
    query =
      from r in Jb_delivery,
      where: r.job in ^job_numbers and is_nil(r.shipped_date) and r.promised_quantity > 0

    failsafed_query(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
    |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_invoices(start_date, end_date) do
    start_date = NaiveDateTime.new(start_date, ~T[00:00:00]) |> elem(1)
    end_date = NaiveDateTime.new(end_date, ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_InvoiceHeader,
      where: r.document_date >= ^start_date and r.document_date <= ^end_date
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def load_vendor_payments(start_date, end_date) do
    start_date = NaiveDateTime.new(start_date, ~T[00:00:00]) |> elem(1)
    end_date = NaiveDateTime.new(end_date, ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_Ap_Check,
      where: r.check_date >= ^start_date and r.check_date <= ^end_date and r.vendor not in ["DH", "DTH REAL"]
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def load_jobs(job_numbers) do
    query = from r in Jb_job, where: r.job in ^job_numbers
    failsafed_query(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def load_delivery_jobs(job_numbers) do
    query = from r in Jb_job_delivery, where: r.job in ^job_numbers
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def load_addresses(addresses) do
    query = from r in Jb_address, where: r.address in ^addresses
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def total_revenue_at_date(date) do
    naive_datetime = NaiveDateTime.new(date, ~T[00:00:00]) |> elem(1)
    query = from j in Jb_job_delivery,
          join: d in Jb_delivery,
          on: j.job == d.job,
          where: j.order_date <= ^naive_datetime,
          where: d.promised_date >= ^naive_datetime or d.shipped_date >= ^naive_datetime,
          distinct: true,
          select: j.total_price
    failsafed_query(query)
    |> Enum.sum()
  end

  def total_jobs_at_date(date) do
    naive_datetime = NaiveDateTime.new(date, ~T[00:00:00]) |> elem(1)
    query = from j in Jb_job_delivery,
          join: d in Jb_delivery,
          on: j.job == d.job,
          where: j.order_date <= ^naive_datetime,
          where: d.promised_date >= ^naive_datetime or d.shipped_date >= ^naive_datetime,
          distinct: true,
          select: count(j.job)
    failsafed_query(query)
    |> Enum.sum()
  end

  def total_worth_of_orders_in_six_weeks_from_date(date) do
    # Convert the date to a NaiveDateTime at the start of the day
    naive_datetime = NaiveDateTime.new(date, ~T[00:00:00]) |> elem(1)

    # Calculate the end date, which is 6 weeks from the input date
    end_date = NaiveDateTime.add(naive_datetime, 6 * 7 * 24 * 60 * 60, :second)

    query = from j in Jb_job_delivery,
            join: d in Jb_delivery,
            on: j.job == d.job,
            where: j.order_date <= ^naive_datetime,
            where: d.promised_date >= ^naive_datetime and d.promised_date <= ^end_date,
            distinct: true,
            select: j.total_price

    failsafed_query(query)
    |> Enum.sum()
  end


  ### MATERIAL PAGE FUNCTIONS ###

  def load_jb_material_information(material_name) do #NOT USED????
    query =
      from r in Jb_material,
      where: r.material == ^material_name,
      where: r.pick_buy_indicator == "P",
      where: r.stocked_uofm == "ft",
      where: r.status == "Active"
    material =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
      end)
      |> List.first

      merge_material_location(material)
  end

  def merge_material_location(material) do
    query =
      from r in Jb_material_location,
      where: r.material == ^material.material
    material_location =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
      end)
      |> List.first
    case material_location do
      nil -> Map.merge(material, %Shophawk.Jb_material_location{} |> Map.from_struct() |> Map.drop([:__meta__, :material, :location_id]) )
      _ -> Map.merge(material, material_location)
    end
  end

  def load_all_jb_material_on_hand(material_list) do
    query =
      from r in Jb_material_location,
      where: r.material in ^material_list
    material =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
      end)
    #rename materail key:
    Enum.map(material, fn mat ->
      Map.put(mat, :material_name, mat.material)
      |> Map.delete(:material)
    end)
  end

  def update_material(size_info, on_hand_qty) do
    material = size_info.material_name
    location_id = size_info.location_id
    purchase_price = size_info.purchase_price
    sell_price = size_info.sell_price
    location_id = if location_id == nil, do: "", else: location_id
    if is_nil(material) == false and location_id != "" do
      on_hand_qty = on_hand_qty / 12 #Convert to Feet for Jobboss
      query =
        Shophawk.Jb_material_location
        |> where([r], r.location_id == ^location_id)
        |> where([r], r.material == ^material)
        |> update([r], set: [on_hand_qty: ^on_hand_qty])
      Shophawk.Repo_jb.update_all(query, [])

      rounded_purchase_price = Float.round(purchase_price, 2)
      rounded_sell_price = Float.round(sell_price, 2)
      if rounded_sell_price > 0.0 do
        query =
          Shophawk.Jb_material
          |> where([r], r.material == ^material)
          |> update([r], set: [standard_cost: ^rounded_purchase_price])
          |> update([r], set: [selling_price: ^rounded_sell_price])
        Shophawk.Repo_jb.update_all(query, [])
      end
      true
    else
      false
    end
  end

  def load_materials_and_sizes() do #doesn't load into cache right now
    query =
      from r in Jb_material,
      where: r.pick_buy_indicator == "P",
      where: r.stocked_uofm == "ft",
      where: r.shape in ["Round", "Rectangle", "Tubing"],
      where: r.status == "Active"
    failsafed_query(query)
    |> Enum.map(fn op ->
      Map.from_struct(op)
      |> Map.drop([:__meta__])
    end)
    |> Enum.reject(fn mat -> String.contains?(mat.material, ["GROB", "MC907", "NGSM", "NMSM", "NNSM", "TEST", "ATN"]) end)
  end

  def load_material_requirements do
    query =
      from r in Jb_material_req,
      where: r.status in ["O", "S"],
      where: r.pick_buy_indicator == "P",
      where: r.uofm == "ft",
      where: not is_nil(r.due_date)
    mat_reqs =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.update!(:cutoff, &(Float.round(&1, 2)))
        |> Map.update!(:part_length, &(Float.round(&1, 2)))
        |> Map.put(:est_qty, Float.round((op.est_qty - op.act_qty), 2))
        |> sanitize_map()
      end)
      job_numbers = Enum.map(mat_reqs, fn mat -> mat.job end) |> Enum.uniq
      query = from r in Jb_job_qty, where: r.job in ^job_numbers
      jobs = #grab make_qty and merge
        failsafed_query(query)
        |> Enum.map(fn op ->
          Map.from_struct(op)
          |> Map.drop([:__meta__])
        end)
      Enum.map(mat_reqs, fn mat ->
        case Enum.find(jobs, fn job -> job.job == mat.job end) do
          nil -> mat
          found_job -> Map.merge(mat, found_job)
        end
      end)
  end

  def load_year_history_of_material_requirements do
    one_year_ago = NaiveDateTime.utc_now() |> NaiveDateTime.beginning_of_day() |> NaiveDateTime.shift(year: -1)
    query =
      from r in Jb_material_req,
      where: r.pick_buy_indicator == "P",
      where: r.uofm == "ft",
      where: not is_nil(r.due_date),
      where: r.due_date >= ^one_year_ago
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([[:__meta__, :cutoff, :part_length, :vendor, :description, :pick_buy_indicator, :status, :uofm, :last_updated, :due_date, :est_qty]])
        |> Map.update!(:act_qty, &(Float.round(&1, 2)))
        |> sanitize_map()
      end)
  end

  def load_job_operation_time_by_employee(employee_initial, startdate, enddate) do
    startdate = NaiveDateTime.new(startdate, ~T[00:00:00]) |> elem(1)
    enddate = NaiveDateTime.new(enddate, ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_job_operation_time,
      where: r.employee == ^employee_initial,
      where: r.work_date <= ^enddate and r.work_date >= ^startdate
      failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) end)
  end

  def load_job_operation_employee_time(job_operations) do
    query =
      from r in Jb_job_operation_time,
      where: r.job_operation in ^job_operations
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) end)
  end

  def load_job_operations(operation_numbers) do
    query = from r in Jb_job_operation, where: r.job_operation in ^operation_numbers
    failsafed_query(query)
    |> Enum.map(fn op ->
      Map.from_struct(op)
      |> Map.drop([:__meta__])
      |> rename_key(:note_text, :operation_note_text)
    end)
  end

  def load_single_material_requirements(material) do
    query =
      from r in Jb_material_req,
      where: r.status in ["O", "S"],
      where: r.pick_buy_indicator == "P",
      where: r.uofm == "ft",
      where: not is_nil(r.due_date),
      where: r.material == ^material
    mat_reqs =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.update!(:cutoff, &(Float.round(&1, 2)))
        |> Map.update!(:part_length, &(Float.round(&1, 2)))
        |> Map.put(:est_qty, Float.round((op.est_qty - op.act_qty), 2))
        |> sanitize_map()
      end)
      job_numbers = Enum.map(mat_reqs, fn mat -> mat.job end) |> Enum.uniq
      query = from r in Jb_job_qty, where: r.job in ^job_numbers
      jobs = #grab make_qty and merge
        failsafed_query(query)
        |> Enum.map(fn op ->
          Map.from_struct(op)
          |> Map.drop([:__meta__])
        end)
      Enum.map(mat_reqs, fn mat ->
        case Enum.find(jobs, fn job -> job.job == mat.job end) do
          nil -> mat
          found_job -> Map.merge(mat, found_job)
        end
      end)
  end

  def convert_string_to_float(string) do
    string = if String.at(string, 0) == ".", do: "0" <> string, else: string
    elem(Float.parse(string), 0)
  end

  #### Part History Search Function ####
  def jobs_search(params) do
    #params_map =
      #%{
      #  "customer" => "",
      #  "customer_po" => "",
      #  "description" => "",
      #  "end-date" => "2000-01-12",
      #  "job" => "",
      #  "part" => "",
      #  "start-date" => "2025-06-13",
      #  "status" => ""
      #}

    # Convert string dates to NaiveDateTime or nil if empty/invalid
    start_date = parse_date(params["start-date"])
    end_date = parse_date(params["end-date"])

    query =
      Jb_job
      |> maybe_filter(:customer, params["customer"])
      |> maybe_filter(:customer_po, params["customer_po"])
      |> maybe_filter_description(params["description"])
      |> maybe_filter(:job, params["job"])
      |> maybe_filter(:part_number, params["part"])
      |> maybe_filter(:status, params["status"])
      |> maybe_filter_date_range(start_date, end_date)
      |> order_by([desc: :order_date])
      |> limit(100)

    failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> sanitize_map()
      end)
  end

  # Helper to parse date strings to NaiveDateTime or return nil
  defp parse_date(""), do: nil
  defp parse_date(date_str) do
    case NaiveDateTime.from_iso8601(date_str <> "T00:00:00") do
      {:ok, ndt} -> ndt
      {:error, _} -> nil
    end
  end

  # Helper to add filter for non-empty string values
  defp maybe_filter(query, _field, ""), do: query
  defp maybe_filter(query, field, value) when is_binary(value) do
    from r in query, where: field(r, ^field) == ^value
  end

  # Helper for multiple wildcard searches on description
  defp maybe_filter_description(query, ""), do: query
  defp maybe_filter_description(query, value) when is_binary(value) do
    # Remove commas, split on spaces, remove empty terms
    terms = value |> String.replace(",", "") |> String.split(" ", trim: true)
    Enum.reduce(terms, query, fn term, q ->
      from r in q, where: ilike(r.description, ^"%#{sanitize_term(term)}%")
    end)
  end

  # Sanitize term to prevent SQL injection
  defp sanitize_term(term) do
    # Only allow alphanumeric and spaces; remove other characters
    String.replace(term, ~r/[^a-zA-Z0-9\s]/, "")
  end

  # Helper to add date range filter if both dates are valid
  defp maybe_filter_date_range(query, nil, _), do: query
  defp maybe_filter_date_range(query, _, nil), do: query
  defp maybe_filter_date_range(query, start_date, end_date) do
    from r in query,
      where: r.order_date >= ^start_date and r.order_date <= ^end_date
  end

  #### Query Failsafes ####
  def failsafed_query(query, retries \\ 3, delay \\ 100) do #For jobboss db queries
    Process.sleep(delay)
    try do
      {:ok, result} = {:ok, Shophawk.Repo_jb.all(query)}
      result
    rescue
      _e in DBConnection.ConnectionError ->
        IO.puts("Database connection error. Retries left: #{retries}")
        handle_retry(query, retries, delay, :connection_error)
      e in Ecto.QueryError ->
        IO.puts("Query error: #{inspect(e)}. Retries left: #{retries}")
        handle_retry(query, retries, delay, :query_error)
      e ->
        IO.puts("Unexpected error: #{inspect(e)}. Retries left: #{retries}")
        handle_retry(query, retries, delay, :unexpected_error)
    end
  end

  def failsafed_query_one_result(query, retries \\ 3, delay \\ 100) do #For jobboss db queries
  Process.sleep(delay)
  try do
    {:ok, result} = {:ok, Shophawk.Repo_jb.one(query)}
    result
  rescue
    _e in DBConnection.ConnectionError ->
      IO.puts("Database connection error. Retries left: #{retries}")
      handle_retry(query, retries, delay, :connection_error)
    e in Ecto.QueryError ->
      IO.puts("Query error: #{inspect(e)}. Retries left: #{retries}")
      handle_retry(query, retries, delay, :query_error)
    e ->
      IO.puts("Unexpected error: #{inspect(e)}. Retries left: #{retries}")
      handle_retry(query, retries, delay, :unexpected_error)
  end
end

  defp handle_retry(_query, 0, delay, reason) do #For jobboss db queries
    Process.sleep(delay)
    {:error, reason}
  end

  defp handle_retry(query, retries, delay, _reason) do #For jobboss db queries
    :timer.sleep(delay)
    failsafed_query(query, retries - 1, delay)
  end

end
