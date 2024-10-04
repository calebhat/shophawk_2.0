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
    alias Shophawk.Material
    #This file is used for all loading and ecto calls directly to the Jobboss Database.


  def rename_key(map, old_key, new_key) do
    map
    |> Map.put(new_key, Map.get(map, old_key))  # Add the new key with the old key's value
    |> Map.delete(old_key)  # Remove the old key
  end

  def load_all_active_jobs() do
    job_numbers =
      Jb_job
      |> where([j], j.status == "Active")
      |> select([j], j.job)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()

    runlist =
      Enum.chunk_every(job_numbers, 50)
      |> Enum.map(fn x -> merge_jobboss_job_info(x) end)
      |> List.flatten()

    :ets.insert(:runlist, {:active_jobs, runlist})  # Store the data in ETS
  end

  def merge_jobboss_job_info(job_numbers) do
    query = from r in Jb_job, where: r.job in ^job_numbers
    jobs_map =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> rename_key(:sched_end, :job_sched_end)
        |> rename_key(:sched_start, :job_sched_start)
        |> rename_key(:status, :job_status)
        |> rename_key(:customer_po_ln, :customer_po_line)
      end)

    query = from r in Jb_job_operation, where: r.job in ^job_numbers
    operations_map =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> rename_key(:note_text, :operation_note_text)
      end)
      #IO.puts("job ops map loaded")
    job_operation_numbers = Enum.map(operations_map, fn op -> op.job_operation end)
    user_values_list = Enum.map(jobs_map, fn job -> job.user_values end)

    query = from r in Jb_material_req, where: r.job in ^job_numbers
    mats_map = failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> rename_key(:status, :mat_status) |> rename_key(:description, :mat_description) end)
    #IO.puts("mat map loaded")
    query = from r in Jb_job_operation_time, where: r.job_operation in ^job_operation_numbers
    operation_time_map = failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) end)
    #IO.puts("operation time map loaded")
    query = from r in Jb_user_values, where: r.user_values in ^user_values_list
    user_values_map = failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.put(:text1, dots_calc(op.text1)) |> rename_key(:text1, :dots) end)
    #IO.puts("user value map loaded")
    operations_map
    |> Enum.map(fn %{job: job} = op -> Map.merge(op, Enum.find(jobs_map, &(&1.job == job))) end) #merge job info
    |> Enum.map(fn %{job: job} = op -> #merge material info
      matching_maps = Enum.filter(mats_map, fn mat -> mat.job == job end)
      case Enum.count(matching_maps) do #case if multiple maps found in the list, ie multiple materials
        0 -> Map.merge(op, Map.from_struct(%Jb_material_req{}) |> Map.drop([:__meta__]) |> Map.drop([:job]) |> Map.drop([:status]) |> Map.drop([:description])) |> Map.put(:material, "Customer Supplied") #in case no material
        1 -> Map.merge(op, Enum.at(matching_maps, 0))
        _ ->
          merged_matching_maps = Enum.reduce(matching_maps, %{}, fn map, acc ->
            map_without_job = Map.drop(map, [:job])
            Map.merge(acc, map_without_job, fn _, value1, value2 ->
              "#{value1} | #{value2}"
            end)
          end)
          Map.merge(op, merged_matching_maps)
      end
    end)
    |> Enum.map(fn %{job_operation: job_operation} = op -> #Merge Job Operation Time
      matching_data = Enum.filter(operation_time_map, &((&1.job_operation) == job_operation))
      starting_map =  Map.from_struct(%Jb_job_operation_time{}) |> Map.drop([:__meta__]) |> Map.drop([:job_operation])
      combined_data_collection = #merge all matching data together before merging with operations
        if matching_data != [] do
          Enum.reduce(matching_data, starting_map, fn row, acc ->
            acc
            |> Map.put(:act_run_hrs, (row.act_run_hrs || 0) + acc.act_run_hrs)
            |> Map.put(:act_run_qty, (row.act_run_qty || 0) + acc.act_run_qty)
            |> Map.put(:act_scrap_qty, (row.act_scrap_qty || 0) + acc.act_scrap_qty)
            |> Map.put(:employee,
              case row.employee do
                "" -> acc.employee
                nil -> acc.employee
                _ -> acc.employee <> " | " <> row.employee <> ": " <> Calendar.strftime(row.work_date, "%m-%d-%y")
              end)
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
    |> Enum.map(fn %{user_values: user_value} = op -> #Merge User Values
      new_user_data = Enum.find(user_values_map, &(&1.user_values == user_value))
      if new_user_data do
        Map.merge(op, new_user_data)
      else
        Map.merge(op, Map.from_struct(%Jb_user_values{}) |> Map.drop([:__meta__]) |> Map.put(:text1, nil) |> rename_key(:text1, :dots))
      end
    end)
    |> Enum.map(fn map -> #add in extra keys used for runlist
      sanitize_map(map) #checks for strings with the wrong encoding for special characters. also converts naivedatetime to date format.
      |> Map.put(:id, "op-#{map.job_operation}")
      |> Map.put(:assignment, nil)
      |> Map.put(:currentop, nil)
      |> Map.put(:material_waiting, false)
      |> Map.put(:runner, false)
      |> Map.put(:date_row_identifer, nil)
    end)
    |> Enum.reject(fn op -> op.job_sched_end == nil end)
    |> merge_shophawk_runlist_db(job_operation_numbers)
    |> Enum.group_by(&{&1.job})
    |> Map.values
    |> set_current_op()
    |> set_material_waiting() #This function flattens the grouped ops as well.
    |> set_assignment_from_note_text_if_op_started
  end

  def load_job_history(job_numbers) do #loads a job that is complete
    query = from r in Jb_job, where: r.job in ^job_numbers
    jobs_map =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> rename_key(:sched_end, :job_sched_end)
        |> rename_key(:sched_start, :job_sched_start)
        |> rename_key(:status, :job_status)
        |> rename_key(:customer_po_ln, :customer_po_line)
      end)

    query = from r in Jb_job_operation, where: r.job in ^job_numbers
    operations_map =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> rename_key(:note_text, :operation_note_text)
      end)
      #IO.puts("job ops map loaded")
    job_operation_numbers = Enum.map(operations_map, fn op -> op.job_operation end)
    user_values_list = Enum.map(jobs_map, fn job -> job.user_values end)

    query = from r in Jb_material_req, where: r.job in ^job_numbers
    mats_map = failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> rename_key(:status, :mat_status) |> rename_key(:description, :mat_description) end)
    #IO.puts("mat map loaded")
    query = from r in Jb_job_operation_time, where: r.job_operation in ^job_operation_numbers
    operation_time_map = failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) end)
    #IO.puts("operation time map loaded")
    query = from r in Jb_user_values, where: r.user_values in ^user_values_list
    user_values_map = failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.put(:text1, dots_calc(op.text1)) |> rename_key(:text1, :dots) end)
    #IO.puts("user value map loaded")
    operations_map
    |> Enum.map(fn %{job: job} = op -> Map.merge(op, Enum.find(jobs_map, &(&1.job == job))) end) #merge job info
    |> Enum.map(fn %{job: job} = op -> #merge material info
      matching_maps = Enum.filter(mats_map, fn mat -> mat.job == job end)
      case Enum.count(matching_maps) do #case if multiple maps found in the list, ie multiple materials
        0 -> Map.merge(op, Map.from_struct(%Jb_material_req{}) |> Map.drop([:__meta__]) |> Map.drop([:job]) |> Map.drop([:status]) |> Map.drop([:description])) |> Map.put(:material, "Customer Supplied") #in case no material
        1 -> Map.merge(op, Enum.at(matching_maps, 0))
        _ ->
          merged_matching_maps = Enum.reduce(matching_maps, %{}, fn map, acc ->
            map_without_job = Map.drop(map, [:job])
            Map.merge(acc, map_without_job, fn _, value1, value2 ->
              "#{value1} | #{value2}"
            end)
          end)
          Map.merge(op, merged_matching_maps)
      end
    end)
    |> Enum.map(fn %{job_operation: job_operation} = op -> #Merge Job Operation Time
      matching_data = Enum.filter(operation_time_map, &((&1.job_operation) == job_operation))
      starting_map =  Map.from_struct(%Jb_job_operation_time{}) |> Map.drop([:__meta__]) |> Map.drop([:job_operation])
      combined_data_collection = #merge all matching data together before merging with operations
        if matching_data != [] do
          Enum.reduce(matching_data, starting_map, fn row, acc ->
            acc
            |> Map.put(:act_run_hrs, (row.act_run_hrs || 0) + acc.act_run_hrs)
            |> Map.put(:act_run_qty, (row.act_run_qty || 0) + acc.act_run_qty)
            |> Map.put(:act_scrap_qty, (row.act_scrap_qty || 0) + acc.act_scrap_qty)
            |> Map.put(:employee,
              case row.employee do
                "" -> acc.employee
                nil -> acc.employee
                _ -> acc.employee <> " | " <> row.employee <> ": " <> Calendar.strftime(row.work_date, "%m-%d-%y")
              end)
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
    |> Enum.map(fn %{user_values: user_value} = op -> #Merge User Values
      new_user_data = Enum.find(user_values_map, &(&1.user_values == user_value))
      if new_user_data do
        Map.merge(op, new_user_data)
      else
        Map.merge(op, Map.from_struct(%Jb_user_values{}) |> Map.drop([:__meta__]) |> Map.put(:text1, nil) |> rename_key(:text1, :dots))
      end
    end)
    |> Enum.map(fn map -> #add in extra keys used for runlist
      sanitize_map(map) #checks for strings with the wrong encoding for special characters. also converts naivedatetime to date format.
      |> Map.put(:id, "op-#{map.job_operation}")
      |> Map.put(:assignment, nil)
      |> Map.put(:currentop, nil)
      |> Map.put(:material_waiting, false)
      |> Map.put(:runner, false)
      |> Map.put(:date_row_identifer, nil)
    end)
    |> merge_shophawk_runlist_db(job_operation_numbers)
    |> Enum.group_by(&{&1.job})
    |> Map.values
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
        ##IO.puts("Failed to convert string to UTF-8: #{inspect(value)}")
        :unicode.characters_to_binary(value, :latin1, :utf8)
      string -> string
    end
  end
  def convert_binary_to_string(value), do: value

  def convert_to_date(%NaiveDateTime{} = value), do: NaiveDateTime.to_date(value)
  def convert_to_date(value), do: value

  defp set_current_op(grouped_ops) do
    Enum.reduce(grouped_ops, [], fn group, acc ->
      {updated_maps, _, _} =
        Enum.reduce(group, {[], nil, ""}, fn op, {acc, last_open_op, last_job} ->
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

      [Enum.reverse(updated_maps) | acc]
    end)
  end

  defp set_current_op_excluding_started(grouped_ops) do #used for set_material_waiting only
    Enum.reduce(grouped_ops, [], fn group, acc ->
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

      [Enum.reverse(updated_maps) | acc]
    end)
  end

  defp set_material_waiting(grouped_ops) do
    list = set_current_op_excluding_started(grouped_ops)
    material_waiting_data = #creates list of maps of just the material_waiting and job_operation data
      Enum.reduce(list, [], fn group, acc ->
        {updated_maps, _, _} =
          Enum.reduce(group, {[], nil, false}, fn op, {acc, last_op, turn_off_mat_waiting} ->
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
        [Enum.reverse(updated_maps) | acc]
      end)
      |> List.flatten
      |> Enum.map(fn map -> Map.take(map, [:job_operation, :material_waiting]) end)

    Enum.map(List.flatten(grouped_ops), fn map -> #Merges material_waiting data with runlist
      matching_material_data = Enum.find(material_waiting_data, fn x -> x.job_operation == map.job_operation end)
      Map.merge(map, matching_material_data)
    end)
  end

  defp set_assignment_from_note_text_if_op_started(operations) do
    [{:data, employees}] = :ets.lookup(:employees, :data)

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

  def load_blackout_dates do
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
    previous_check = NaiveDateTime.add(previous_check, -5, :hour) #convert to local time that jobboss DB uses
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
    operations = merge_jobboss_job_info(jobs_to_update) |> Enum.reject(fn op -> op.job_sched_end == nil end)
    [{:active_jobs, runlist}] = :ets.lookup(:runlist, :active_jobs)
    runlist = List.flatten(runlist)
    skinned_runlist = Enum.reduce(jobs_to_update, runlist, fn job, acc -> #removes all operations that have a job that gets updated
      Enum.reject(acc, fn op -> job == op.job end)
    end)
    new_runlist = Enum.reduce(operations, skinned_runlist, fn op, acc ->
      if op.job_status == "Active", do: [op | acc], else: acc
    end)
    :ets.insert(:runlist, {:active_jobs, new_runlist})  # Store the data in ETS
  end

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

  defp handle_retry(_query, 0, delay, reason) do #For jobboss db queries
    Process.sleep(delay)
    {:error, reason}
  end

  defp handle_retry(query, retries, delay, _reason) do #For jobboss db queries
    :timer.sleep(delay)
    failsafed_query(query, retries - 1, delay)
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

  def load_deliveries(job_numbers) do
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

  def load_materials_and_sizes_into_cache() do #doesn't load into cache right now
    query =
      from r in Jb_material,
      where: r.pick_buy_indicator == "P",
      where: r.stocked_uofm == "ft",
      where: r.shape == "Round",
      where: r.status == "Active"
    material =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
      end)
      |> Enum.reject(fn mat -> String.contains?(mat.material, ["GROB", "MC907", "NGSM", "NMSM", "NNSM", "TEST", "ATN"]) end)
    mat_reqs = load_material_requirements()
    all_jb_material_info =
      Enum.map(material, fn mat -> mat.material end)
      |> load_all_jb_material_on_hand()
    all_material_on_floor = Material.list_stockedmaterials_on_floor

    round_stock = Enum.reduce(material, [], fn mat, acc ->
      case String.split(mat.material, "X", parts: 2) do
        [_] -> acc
        [size, material] ->
          matching_mat_reqs = Enum.reduce(mat_reqs, [], fn req, acc -> if String.ends_with?(req.material, material), do: [req | acc], else: acc end)
          matching_size_reqs = Enum.reduce(matching_mat_reqs, [], fn req, acc ->
            matching_size = case String.split(req.material, "X", parts: 2) do
              [size_to_find, _material] -> if size_to_find == size, do: [req | acc], else: acc
              _ -> acc
            end
          end)
          matching_material_on_floor = Enum.filter(all_material_on_floor, fn floor_mat -> floor_mat.material == mat.material end)

          #if material == "4140HT" and size == "16" do

            #FILTER OUT JOBS THAT AREN'T RELEASED YET SOMEHOW
            #1x4140HT and 1.625x4140HT are sharing jobs??
            jobs =
              Enum.map(matching_size_reqs, fn job ->
                %{job: job.job, length: Float.round((job.part_length + 0.05), 2), make_qty: job.make_quantity, cutoff: job.cutoff, mat: material, size: size}
              end)
              |> Enum.sort_by(&(&1.make_qty), :desc)
              #|> IO.inspect

              {matching_material_on_floor, material_needed} = assign_jobs_to_material(jobs, matching_material_on_floor)
              #|> IO.inspect

          #end

          #calculate total amount needed by multiplying parts needed + cutoff + blade width is sawed
          #Reduce through sizes, and assign slugs/bars to use for each. Start with smallest slugs and go up
          #Maybe just flield for :assigned? & :slugs_assigned? make it a map that includes job number and length used?
          #don't save to db, make this functions end result the used list for everything.


          matching_jobs = Enum.map(matching_size_reqs, fn mat -> %{job: mat.job, qty: mat.est_qty} end) |> Enum.sort_by(&(&1.qty), :asc)
          material_info =
            case Enum.find(all_jb_material_info, fn mat_info -> mat_info.material_name == mat.material end) do
              nil ->  %{material_name: mat.material, location_id: "", on_hand_qty: 0.0}
              found_mat_info -> found_mat_info
            end
          case Enum.find(acc, fn mat -> mat.material == material end) do
            nil -> #new material/size not in list already
              [%{
                material: material,
                mat_reqs_count: Enum.count(matching_mat_reqs),
                sizes:
                  [%{size: convert_string_to_float(size),
                  jobs_using_size: Enum.count(matching_size_reqs),
                  matching_jobs: matching_jobs,
                  material_info: material_info,
                  need_to_order_amt: 0.0}]
                } | acc]
            found_material -> #add new sizes to existing material in list.
              updated_map =
                Map.update!(found_material, :sizes, fn existing_sizes ->
                  [
                    %{size: convert_string_to_float(size),
                    jobs_using_size: Enum.count(matching_size_reqs),
                    matching_jobs: matching_jobs,
                    material_info: material_info,
                    need_to_order_amt: 0.0
                    } | existing_sizes]
                  end)
              updated_acc = Enum.reject(acc, fn mat -> mat.material == found_material.material end) #removes previous material for replacement with updated_map
              [updated_map | updated_acc]
          end
        _ -> acc
      end
    end)
    |> Enum.map(fn material ->
      Map.put(material, :sizes, Enum.sort_by(material.sizes, & &1.size, :asc))
    end)
    |> Enum.uniq_by(&(&1.material))
    |> Enum.sort_by(&(&1.material), :asc)
  end

  def assign_jobs_to_material(jobs, stocked_materials) do
    if stocked_materials != [] do
      Enum.reduce(jobs, {stocked_materials, 0.0}, fn job, {materials, length_needed_to_order} ->
        sawed_length = Float.round((job.length + job.cutoff + 0.1), 2)
        #use slugs within .25" of length
        {materials_with_slugs, remaining_qty} = assign_to_slugs(materials, job)

        {materials_with_bars, remaining_qty} =
          if remaining_qty > 0 do
            #add cutoff and blade width for cutting
            job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: remaining_qty}
            assign_to_bars(materials_with_slugs, job_that_needs_sawing)
          else
          {materials_with_slugs, remaining_qty}
          end

        {assigned_bars, remaining_qty} =
          if remaining_qty > 0 do #use longer slugs if nothing else works
            #revert to length without saw cuts
            longer_slugs_needed = Map.put(job, :make_qty, remaining_qty)
            last_resort_assign_to_slugs(materials_with_bars, longer_slugs_needed)
          else
            {materials_with_bars, remaining_qty}
          end
        length_needed_to_order = Float.round((remaining_qty * sawed_length) + length_needed_to_order, 2)# |> IO.inspect
        #IO.inspect("job: #{job.job}, length_needed: #{length_needed_to_order}")
        {assigned_bars, length_needed_to_order}
      end)
    else
      length_needed_to_order = Enum.reduce(jobs, 0.0, fn job, acc -> ((job.length + job.cutoff + 0.05) * job.make_qty) + acc end)
      if length_needed_to_order > 1000.0, do: IO.inspect(jobs)
      {stocked_materials, Float.round(length_needed_to_order, 2)}
    end
    #|> IO.inspect
  end

  defp assign_to_slugs(materials, %{length: length_needed, make_qty: make_qty, job: job_id}) do
    Enum.reduce_while(materials, {[], make_qty}, fn material, {acc, remaining_qty} ->
      #if slug is withing .25" of length needed, assign to slug
      if material.slug_length >= length_needed and material.slug_length <= (length_needed + 0.25) do
        assignments = Map.get(material, :job_assignments, [])
        slugs_left =
          case assignments do
            [] -> 0
            list ->
              slugs_used = Enum.reduce(list, 0.0, fn x, acc -> x.slug_qty + acc end)
              material.number_of_slugs - slugs_used
          end
        if slugs_left > 0 do
          updated_assignments = [%{job: job_id, slug_qty: min(remaining_qty, material.number_of_slugs), length_to_use: 0.0, parts_from_bar: 0} | assignments]
          remaining_qty = max(0, remaining_qty - material.number_of_slugs)

          updated_material = Map.put(material, :job_assignments, updated_assignments)
          {:cont, {[updated_material | acc], remaining_qty}}
        else
          {:cont, {[material | acc], remaining_qty}}
        end
      else
        {:cont, {[material | acc], remaining_qty}}
      end
    end)
  end

  defp assign_to_bars(materials, %{job: job, sawed_length: sawed_length, remaining_qty: remaining_qty}) do
    Enum.reduce_while(materials, {[], remaining_qty}, fn material, {acc, remaining_qty} ->
      if material.bar_length != nil do
        assignments = Map.get(material, :job_assignments, [])
          non_assigned_bar_length =
            case assignments do
              [] -> material.bar_length
              list ->
                bar_length_assigned = Enum.reduce(list, 0.0, fn x, acc -> x.length_to_use + acc end)
                Float.round(material.bar_length - bar_length_assigned, 2)
            end
        if non_assigned_bar_length >= sawed_length do
          parts_from_bar = min(remaining_qty, floor(non_assigned_bar_length / sawed_length))
          length_to_use = Float.round(sawed_length * parts_from_bar, 2)
          remaining_qty = max(0, remaining_qty - parts_from_bar)

          updated_assignments = [%{job: job, length_to_use: length_to_use, parts_from_bar: parts_from_bar, slug_qty: 0} | assignments]

          updated_material = Map.put(material, :job_assignments, updated_assignments)
          {:cont, {[updated_material | acc], remaining_qty}}
        else
          {:cont, {[material | acc], remaining_qty}}
        end
      else
        {:cont, {[material | acc], remaining_qty}}
      end
    end)
  end

  defp last_resort_assign_to_slugs(materials, %{length: length_needed, make_qty: make_qty, job: job_id}) do
    Enum.reduce_while(materials, {[], make_qty}, fn material, {acc, remaining_qty} ->
      #if slug is withing .25" of length needed, assign to slug
      if material.slug_length != nil do
        if material.slug_length >= length_needed do
          assignments = Map.get(material, :job_assignments, [])
          slugs_left =
            case assignments do
              [] -> material.number_of_slugs
              list ->
                slugs_used = Enum.reduce(list, 0.0, fn x, acc -> x.slug_qty + acc end)
                material.number_of_slugs - slugs_used
            end
          if slugs_left > 0 do
            updated_assignments = [%{job: job_id, slug_qty: min(remaining_qty, material.number_of_slugs), length_to_use: 0.0, parts_from_bar: 0} | assignments]
            remaining_qty = max(0, remaining_qty - material.number_of_slugs)

            updated_material = Map.put(material, :job_assignments, updated_assignments)
            {:cont, {[updated_material | acc], remaining_qty}}
          else
            {:cont, {[material | acc], remaining_qty}}
          end
        else
          {:cont, {[material | acc], remaining_qty}}
        end
      else
        {:cont, {[material | acc], remaining_qty}}
      end
    end)
  end


  def load_material_requirements do
    query =
      from r in Jb_material_req,
      where: r.status == "O",
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
        |> Map.update!(:est_qty, &(Float.round(&1, 2)))
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

end
