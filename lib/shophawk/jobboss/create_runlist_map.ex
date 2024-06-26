defmodule Shophawk.RunlistMap do
    alias Shophawk.Repo
    import Ecto.Query, warn: false
    alias Shophawk.Jb_job
    alias Shophawk.Jb_job_operation
    alias Shophawk.Jb_material
    alias Shophawk.Runlist
    alias Shophawk.Jb_job_operation_time
    alias Shophawk.Jb_user_values


  def load_all_active_jobs() do
    query =
      from r in Jb_job,
      where: r.status == "Active",
      order_by: [asc: r.job]

    jobs = Shophawk.Repo_jb.all(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__])
        |> rename_key(:sched_end, :job_sched_end)
        |> rename_key(:sched_start, :job_sched_start)
        |> rename_key(:status, :job_status)
    end)
    #IO.inspect(Enum.count(jobs))
    job_numbers = Enum.map(jobs, fn op -> op.job end)

    #TESTING
    test_job = [[List.first(job_numbers)]]
    |> Enum.map(fn x -> merge_jobboss_job_info(x, jobs) end)
    |> Enum.each(fn maps ->
      Enum.each(maps, fn op -> IO.inspect(op) end)
    end)
    #TESTING

    #Good below
    #Enum.chunk_every(job_numbers, 50)
    #|> Enum.map(fn x -> merge_jobboss_job_info(x) end)

  end

  def merge_jobboss_job_info(job_numbers, jobs_map) do
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
              Map.merge(acc, map, fn _, value1, value2 ->
                "#{value1} | #{value2}"
              end)
            end)
            Map.merge(op, merged_matching_maps)
        end
      end)
      |> Enum.map(fn %{job_operation: job_operation} = op -> #Merge Job Operation Time
        matching_data = Enum.filter(operation_time_map, &((&1.job_operation) ==  job_operation))
        starting_map =  Map.from_struct(%Jb_job_operation_time{}) |> Map.drop([:__meta__])
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
          Map.merge(op, Map.from_struct(%Jb_job_operation_time{}) |> Map.drop([:__meta__]) |> Map.put(:text1, nil) |> rename_key(:text1, :dots))
        end
      end)
      |> Enum.with_index(1)
      |> Enum.map(fn {map, index} -> #add in extra keys used for runlist
        Map.put(map, :id, index)
        |> sanitize_map() #checks for strings with the wrong encoding for special characters. also converts naivedatetime to date format.
        |> Map.put(:assignment, nil)
        |> Map.put(:currentop, nil)
        |> Map.put(:material_waiting, false)
        |> Map.put(:runner, false)
      end)
      |> Enum.group_by(&{&1.job})
      |> Map.values
      |> set_current_op()
      |> set_material_waiting()
      |> List.flatten
      |> set_assignment_from_note_text_if_op_started

  end

  def rename_key(map, old_key, new_key) do
    map
    |> Map.put(new_key, Map.get(map, old_key))  # Add the new key with the old key's value
    |> Map.delete(old_key)  # Remove the old key
  end

  def sanitize_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      Map.put(acc, key, convert_binary_to_string(value))
      Map.put(acc, key, convert_to_date(value))
    end)
  end

  def convert_binary_to_string(value) when is_binary(value) do
    case :unicode.characters_to_binary(value, :latin1, :utf8) do
      {:error, _, _} ->
        Logger.error("Failed to convert string to UTF-8: #{inspect(value)}")
        :unicode.characters_to_binary(value, :latin1, :utf8, :replacement)
      string -> string
    end
  end
  def convert_binary_to_string(value), do: value

  def convert_to_date(value) do
    if is_struct(value, NaiveDateTime), do: NaiveDateTime.to_date(value), else: value
  end

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

  defp set_material_waiting(grouped_ops) do
    Enum.reduce(grouped_ops, [], fn group, acc ->
      {updated_maps, _, _} =
        Enum.reduce(group, {[], nil, false}, fn op, {acc, last_op, turn_off_mat_waiting} ->
          cond do
            op.currentop == "IN" ->
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
  end

  defp set_assignment_from_note_text_if_op_started(operations) do
    Enum.map(operations, fn op ->
      if op.status == "S" do
        employee =
          op.employee
          |> String.split("|")
          |> Enum.map(&String.trim/1)
          |> List.last
          |> String.split(":")
          |> List.first
        Map.put(op, :assignment, employee)
      else
        op
      end
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

end
