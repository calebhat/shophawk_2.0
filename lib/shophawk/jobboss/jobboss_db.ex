defmodule Shophawk.Jobboss_db do
    alias Shophawk.Repo
    import Ecto.Query, warn: false
    alias Shophawk.Jb_job
    alias Shophawk.Jb_job_operation
    alias Shophawk.Jb_material
    alias Shophawk.Runlist
    alias Shophawk.Jb_job_operation_time
    alias Shophawk.Jb_user_values
    alias Shophawk.Jb_employees
    alias Shophawk.Jb_holiday
    alias Shophawk.Jb_attachment
    #This file is used for all loading and ecto calls directly to the Jobboss Database.

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

    :ets.insert(:runlist, {:active_jobs, runlist})  # Store the data in ETS
  end

  def merge_jobboss_job_info(job_numbers) do
    jobs_map =
      Jb_job
      |> where([j], j.job in ^job_numbers)
      |> Shophawk.Repo_jb.all()
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__])
      |> rename_key(:sched_end, :job_sched_end)
      |> rename_key(:sched_start, :job_sched_start)
      |> rename_key(:status, :job_status)
      |> rename_key(:customer_po_ln, :customer_po_line)
      end)

    operations_map =
      Shophawk.Repo_jb.all(from r in Jb_job_operation, where: r.job in ^job_numbers)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
      end)
    job_operation_numbers = Enum.map(operations_map, fn op -> op.job_operation end)
    user_values_list = Enum.map(jobs_map, fn job -> job.user_values end)
    mats_map = Shophawk.Repo_jb.all(from r in Jb_material, where: r.job in ^job_numbers) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> rename_key(:status, :mat_status) |> rename_key(:description, :mat_description) end)
    operation_time_map = Shophawk.Repo_jb.all(from r in Jb_job_operation_time, where: r.job_operation in ^job_operation_numbers) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) end)
    user_values_map = Shophawk.Repo_jb.all(from r in Jb_user_values, where: r.user_values in ^user_values_list) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.put(:text1, dots_calc(op.text1)) |> rename_key(:text1, :dots) end)

    operations =
      operations_map
      |> Enum.map(fn %{job: job} = op -> Map.merge(op, Enum.find(jobs_map, &(&1.job == job))) end) #merge job info
      |> Enum.map(fn %{job: job} = op -> #merge material info
        matching_maps = Enum.filter(mats_map, fn mat -> mat.job == job end)
        case Enum.count(matching_maps) do #case if multiple maps found in the list, ie multiple materials
          0 -> Map.merge(op, Map.from_struct(%Jb_material{}) |> Map.drop([:__meta__])) #in case no material
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
                  _ -> new_string = acc.employee <> " | " <> row.employee <> ": " <> Calendar.strftime(row.work_date, "%m-%d-%y")
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
        |> Map.put(:id, map.job_operation)
        |> Map.put(:assignment, nil)
        |> Map.put(:currentop, nil)
        |> Map.put(:material_waiting, false)
        |> Map.put(:runner, false)
        |> Map.put(:date_row_identifer, nil)
      end)
      |> Enum.reject(fn op -> op.job_sched_end == nil end)
      |> merge_shophawk_runlist_db
      |> Enum.group_by(&{&1.job})
      |> Map.values
      |> set_current_op()
      |> set_material_waiting() #This function flattens the grouped ops as well.
      |> set_assignment_from_note_text_if_op_started
  end

  def rename_key(map, old_key, new_key) do
    map
    |> Map.put(new_key, Map.get(map, old_key))  # Add the new key with the old key's value
    |> Map.delete(old_key)  # Remove the old key
  end

  def sanitize_map(map) do
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
        Logger.error("Failed to convert string to UTF-8: #{inspect(value)}")
        :unicode.characters_to_binary(value, :latin1, :utf8)
      string -> string
    end
  end
  def convert_binary_to_string(value), do: value

  def convert_to_date(%NaiveDateTime{} = value), do: NaiveDateTime.to_date(value)
  def convert_to_date(value), do: value

  defp set_current_op(grouped_ops) do
    Enum.reduce(grouped_ops, [], fn group, acc ->
      {updated_maps, _} =
        Enum.reduce(group, {[], nil}, fn op, {acc, last_open_op} ->
          cond do
            op.status in ["O", "S"] and last_open_op == nil ->
              {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor}

            op.status in ["O", "S"] and last_open_op != nil ->
              {[%{op | currentop: last_open_op} | acc], last_open_op}

            op.status == "C" ->
              {[%{op | currentop: nil} | acc], nil}

            true -> {[%{op | currentop: nil} | acc], nil}
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

  def merge_shophawk_runlist_db(ops) do
    Enum.map(ops, fn op ->
      db_data =
        case Shophawk.Shop.get_runlist_by_job_operation(op.job_operation) do
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
    jobs =
      Jb_job
      |> where([j], j.last_updated >= ^previous_check)
      |> select([j], j.job)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()
    job_operation_jobs =
      Jb_job_operation
      |> where([j], j.last_updated >= ^previous_check)
      |> select([j], j.job)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()
    material_jobs =
      Jb_material
      |> where([j], j.last_updated >= ^previous_check)
      |> select([j], j.job)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()
    job_operation_time_ops =
      Jb_job_operation_time
      |> where([j], j.last_updated >= ^previous_check)
      |> select([j], j.job_operation)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()
    job_operation_time_jobs =
      Jb_job_operation
      |> where([j], j.job_operation in ^job_operation_time_ops)
      |> select([j], j.job)
      |> distinct(true)
      |> Shophawk.Repo_jb.all()
    jobs_to_update = jobs ++ job_operation_jobs ++ material_jobs ++ job_operation_time_jobs
      |> Enum.uniq
    operations = merge_jobboss_job_info(jobs_to_update) |> Enum.reject(fn op -> op.job_sched_end == nil end)
    [{:active_jobs, runlist}] = :ets.lookup(:runlist, :active_jobs)
    runlist = List.flatten(runlist)
    new_runlist = Enum.reduce(operations, runlist, fn op, acc ->
      if op.job_status == "Active" do
        case Enum.find_index(acc, &(&1.job_operation == op.job_operation)) do
          nil -> [op | acc]
          index -> List.replace_at(acc, index, op)
        end
      else
        Enum.reject(acc, &(&1.job_operation == op.job_operation))
      end
    end)
    :ets.insert(:runlist, {:active_jobs, new_runlist})  # Store the data in ETS
    IO.inspect(previous_check)
    IO.puts("#{Enum.count(jobs_to_update)} Jobs updated")
    IO.inspect(jobs_to_update)
  end

end
