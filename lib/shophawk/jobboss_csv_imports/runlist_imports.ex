defmodule Shophawk.RunlistImports do
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop
  alias Shophawk.RunlistExports
  alias Shophawk.GeneralCsvFunctions

  alias Shophawk.MSSQL
  def test do
    IO.inspect("hello")
    sql_query = "SELECT * FROM [PRODUCTION].[dbo].[Job] WHERE Job='134134'"
    MSSQL.query(sql_query)
    #case MSSQL.query(sql_query) do
    #  {:ok, result} ->
    #    result.rows

    #  {:error, reason} ->
    #    IO.puts("Failed to execute query: #{inspect(reason)}")
    #    []
    #end
  end

  def refresh_active_jobs() do #refresh all active jobs
    update_operations(Enum.uniq(RunlistExports.export_active_jobs() ++ Shop.get_all_active_jobs_from_db()))
  end

  def refresh_all_jobs() do #refresh all jobs
    update_operations(RunlistExports.export_all_jobs())
  end

  def custom_job_update() do
    update_operations(["134376",  "134580"])
  end

  def scheduled_runlist_update(caller_pid) do
    RunlistExports.export_last_updated(0) #runs sql queries to only export jobs updated since last time it ran
    jobs_to_update = create_jobs_list()
    if jobs_to_update != [] do
      update_operations(jobs_to_update)
    end
    if caller_pid != nil do
      send(caller_pid, :update_from_jobboss_complete)
    end
  end

  def update_operations(jobs_to_update) do
    #creates a list of all operations in their most recent state
    Enum.chunk_every(jobs_to_update, 400) #breaks the list up into chunks
    |> Enum.map(fn jobs_chunk ->
      RunlistExports.export_job_chunk(jobs_chunk) #export csv files for each chunk.
      operations =
        runlist_creation_start(Path.join([File.cwd!(), "csv_files/runlistops.csv"])) #create map of all operations from the past year
        |> jobs_merge(Path.join([File.cwd!(), "csv_files/jobs.csv"])) #Merge job data with each operation
        |> mat_merge(Path.join([File.cwd!(), "csv_files/material.csv"])) #Merge material data with each operation
      {operations, merge_data, merge_user} = RunlistExports.export_data_collection_and_user_values(operations) #uses job_operation to find data
      operations =
        merge_data_collection(operations, merge_data)
        |> merge_user_values(merge_user)
        |> Enum.reverse
        |> Enum.group_by(&{&1.job})
        |> Map.values
        |> set_current_op()
        |> set_material_waiting()
        |> List.flatten
        |> set_assignment_from_note_text_if_op_started
      existing_records = Enum.map(operations, &(&1.job)) |> Enum.uniq |> Shop.find_matching_job_ops #create list of structs that already exist in DB
      operations =
        Enum.map(operations, fn op -> #merges assignment value to operations
          case Enum.find(existing_records, &(&1.job_operation == op.job_operation)) do
            nil -> #if the record does not exist, create a new one for it
              op
            record ->   #if the record exists, update it with the new values
              Map.put(op, :assignment, record.assignment)
            end
        end)
        |> Enum.map(fn map -> #shortens any strings to be under the string length limit
          new_map =
            Enum.map(map, fn {key, value} -> #shortens values to fit max character length
              if is_binary(value) and String.length(value) > 255, do: {key, String.slice(value, 0, 255)}, else: {key, value}
            end)
            |> Enum.into(%{}) # Convert back into a map
          list = #for each map in the list, run it through changeset casting/validations. converts everything to correct datatype
            %Runlist{}
            |> Runlist.changeset(new_map)
            #have to manually add timestamps for insert all operation. Time must be in NavieDateTime for Ecto.
          list.changes #The changeset results in a list of data, extracts needed map from changeset.
          |> Map.put(:inserted_at, NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
          |> Map.put(:updated_at,  NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
        end)

        if existing_records != [], do: Shop.delete_listed_runlist(existing_records)
        Shop.import_all(operations)
    end)
    IO.puts("Import Complete - " <> Integer.to_string(Enum.count(jobs_to_update)) <> " Jobs Updated")
    :ok
  end


  def runlist_creation_start(jobs_to_update \\ [], file) do
    File.stream!(file)
    |> Stream.map(&String.trim(&1))
    |> Stream.map(&String.split(&1, "`"))
    |> Stream.map(fn list ->
      case list do
        [first | rest] -> [String.replace(first, "\uFEFF", "") | rest]
        _ -> list
      end
    end)
    |> Stream.filter(fn
      [_] -> false #lines with only one entry
      [job | _] -> jobs_to_update |> Enum.empty?() || Enum.member?(jobs_to_update, job) #if the "jobs_to_update" list is empty, it allows any job to pass, if it's not empty, it checks if each job is on the list before passing it through
    end)
    |> Enum.reduce( [], fn [ job, job_operation, wc_vendor, operation_service, sched_start, sched_end, sequence, status, est_total_hrs | _], acc ->
      new_map = %{job: job, job_operation: String.to_integer(job_operation), wc_vendor: wc_vendor, operation_service: operation_service, sched_start: sched_start, sched_end: sched_end, sequence: sequence, status: status, est_total_hrs: est_total_hrs}
      [new_map | acc]
    end)
  end

  def jobs_merge(operations, file) do
    new_list =
      File.stream!(file)
      |> GeneralCsvFunctions.initial_mapping()
      |> Enum.reduce( [],
        fn [job, customer, order_date, part_number, job_status, rev, description, order_quantity, extra_quantity, pick_quantity, make_quantity, open_operations, shipped_quantity, customer_po, customer_po_line, job_sched_end, job_sched_start, note_text, released_date, user_value | _], acc ->
          new_map =%{job: job, customer: customer, order_date: order_date,  part_number: part_number,  job_status: job_status,  rev: rev,  description: description,  order_quantity: order_quantity,  extra_quantity: extra_quantity,  pick_quantity: pick_quantity,  make_quantity: make_quantity,  open_operations: open_operations,  shipped_quantity: shipped_quantity,  customer_po: customer_po,  customer_po_line: customer_po_line,  job_sched_end: job_sched_end,  job_sched_start: job_sched_start,  released_date: released_date,  note_text: note_text,  user_value: user_value}
          [new_map | acc]
        end)
    Enum.map(operations, fn %{job: job} = map1 ->
      map2 = Enum.find(Enum.reverse(new_list), &(&1.job == job))
      if map2 do
        Map.merge(map1, map2)
      else
        empty_map =%{customer: nil, order_date: nil, part_number: nil, job_status: nil, rev: nil, description: nil, order_quantity: nil, extra_quantity: nil, pick_quantity: nil, make_quantity: nil, open_operations: nil, shipped_quantity: nil, customer_po: nil,  customer_po_line: nil, job_sched_end: nil, job_sched_start: nil, released_date: nil, note_text: nil, user_value: nil}
        Map.merge(map1, empty_map)
      end
    end)
  end

  def mat_merge(operations, file) do
    empty_map = #used in case no match is found in material csv
      %{job: nil,
      material: nil,
      mat_vendor: nil,
      mat_description: nil,
      mat_pick_or_buy: nil,
      mat_status: nil
    }
    new_list =
      File.stream!(file)
      |> GeneralCsvFunctions.initial_mapping()
      |> Enum.reduce( [],
      fn
      [
        job,
        material,
        mat_vendor,
        mat_description,
        mat_pick_or_buy,
        mat_status | _], acc ->
          new_map =
            %{job: job,
            material: material,
            mat_vendor: mat_vendor,
            mat_description: mat_description,
            mat_pick_or_buy: mat_pick_or_buy,
            mat_status: mat_status
            }
        [new_map | acc]  end)
        Enum.map(operations, fn %{job: job} = map1 ->
          matching_maps = Enum.reverse(new_list) |> Enum.filter(&(&1.job == job))
          case Enum.count(matching_maps) do #case if multiple maps found in the list, ie multiple materials
            0 -> Map.merge(map1, Map.take(empty_map, Map.keys(empty_map) -- [:job]))
            1 ->
              map2 = Enum.at(matching_maps, 0)
              Map.merge(map1, Map.take(map2, Map.keys(map2) -- [:job])) #merges all except job to keep job in place (overwrites the job to nil if there no material ie. pick jobs)
            _ ->
              #map2 = Map.merge(map1, map2)
              map2 = Enum.reduce(matching_maps, %{}, fn map, acc ->
                Map.merge(acc, Map.take(map, Map.keys(map) -- [:job]), fn _, value1, value2 ->
                  "#{value1} | #{value2}"
                end)
              end)
              Map.merge(map1, map2)
          end
        end)
  end

  defp merge_data_collection(operations, merge_data) do
    if merge_data == true do
      GeneralCsvFunctions.process_csv(Path.join([File.cwd!(), "csv_files/operationtime.csv"]), 8)
        operations =
          Enum.map(operations, fn map -> #sets default values if no data collection data for an operation
            map
            |> Map.put_new(:est_total_hrs, 0.0)
            |> Map.put_new(:currentop, nil)
            |> Map.put_new(:employee, nil)
            |> Map.put_new(:work_date, nil)
            |> Map.put_new(:act_setup_hrs, 0.0)
            |> Map.put_new(:act_run_hrs, 0.0)
            |> Map.put_new(:act_run_qty, 0.0)
            |> Map.put_new(:act_scrap_qty, 0.0)
            |> Map.put_new(:data_collection_note_text, nil)
          end)

        new_data_list =
          File.stream!(Path.join([File.cwd!(), "csv_files/operationtime.csv"]))
          |> GeneralCsvFunctions.initial_mapping()
          |> Enum.reverse
          |> Enum.reduce( [], fn [job_operation, employee, work_date, act_setup_hrs, act_run_hrs, act_run_qty, act_scrap_qty, data_collection_note_text | _], acc ->
            new_map =
              %{job_operation: String.to_integer(job_operation),
              employee: employee,
              work_date: work_date,
              act_setup_hrs: Float.round(String.to_float(act_setup_hrs), 2),
              act_run_hrs: Float.round(String.to_float(act_run_hrs), 2),
              act_run_qty: String.to_integer(act_run_qty),
              act_scrap_qty: String.to_integer(act_scrap_qty),
              data_collection_note_text: data_collection_note_text
              }
            [new_map | acc]
          end)

        Enum.map(operations, fn %{job_operation: job_operation} = op ->
          matching_data = Enum.filter(new_data_list, &((&1.job_operation) ==  job_operation))

          starting_map = %{act_run_hrs: op.act_run_hrs, act_run_qty: op.act_run_qty, act_scrap_qty: op.act_scrap_qty,  data_collection_note_text: op.data_collection_note_text, employee: op.employee}
          starting_map = if starting_map.data_collection_note_text == nil, do: Map.put(starting_map, :data_collection_note_text, ""), else: starting_map
          starting_map = if starting_map.employee == nil, do: Map.put(starting_map, :employee, ""), else: starting_map

          combined_data_collection = #merge all matching data together before merging with operations
            if matching_data != [] do
              Enum.reduce(matching_data, starting_map, fn row, acc ->
                {:ok, work_date, _} = DateTime.from_iso8601(String.replace(row.work_date, " ", "T") <> "Z")
                work_date = Calendar.strftime(work_date, "%m-%d-%y")

                acc
                |> Map.put(:act_run_hrs, (row.act_run_hrs || 0) + acc.act_run_hrs)
                |> Map.put(:act_run_qty, (row.act_run_qty || 0) + acc.act_run_qty)
                |> Map.put(:act_scrap_qty, (row.act_scrap_qty || 0) + acc.act_scrap_qty)
                |> Map.put(:data_collection_note_text,
                  case row.data_collection_note_text do
                    "" -> acc.data_collection_note_text
                    nil -> acc.data_collection_note_text
                    _ -> new_string = acc.data_collection_note_text <> " | " <> row.data_collection_note_text
                        if String.length(new_string) > 220, do: String.slice(acc.data_collection_note_text, 0, 230), else: new_string
                  end)
                |> Map.put(:employee,
                  case row.employee do
                    "" -> acc.employee
                    nil -> acc.employee
                    _ -> new_string = acc.employee <> " | " <> row.employee <> ": " <> work_date
                        if String.length(new_string) > 220, do: acc.employee, else: new_string

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


    else
      operations
    end
  end

  defp merge_user_values(operations, merge_user) do
    if merge_user == true do
      GeneralCsvFunctions.process_csv(Path.join([File.cwd!(), "csv_files/uservalues.csv"]), 2)
      user_value_list =
        File.stream!(Path.join([File.cwd!(), "csv_files/uservalues.csv"]))
        |> GeneralCsvFunctions.initial_mapping()
        |> Enum.reduce( [], fn [user_value, dots | _], acc ->
          new_map = %{user_value: user_value, dots: dots_calc(dots)}
          [new_map | acc]
        end)
      if user_value_list != [] do #csv could be empty if no matching user values found
        Enum.map(operations, fn %{user_value: user_value} = op ->
          new_user_data = Enum.find(user_value_list, &(&1.user_value == user_value))
          if new_user_data do
            Map.merge(op, new_user_data)
          else
            op
          end
        end)
      else
        operations
      end
    else
      operations
    end
  end

  def create_jobs_list() do
    job_list =
    File.stream!(Path.join([File.cwd!(), "csv_files/jobs.csv"]))
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.replace(&1, "\uFEFF", ""))
      |> Stream.reject(&String.contains?(&1, "("))
      |> Stream.reject(&(&1 == ""))
      |> Enum.to_list()
    material_job_list = #make a list of jobs that material changed
      File.stream!(Path.join([File.cwd!(), "csv_files/material.csv"]))
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.replace(&1, "\uFEFF", ""))
      |> Stream.reject(&String.contains?(&1, "("))
      |> Stream.reject(&(&1 == ""))
      |> Enum.to_list()
    operations_job_list = #Get list of jobs that have at least one operation updated
      File.stream!(Path.join([File.cwd!(), "csv_files/runlistops.csv"]))
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.replace(&1, "\uFEFF", ""))
      |> Stream.reject(&String.contains?(&1, "("))
      |> Stream.reject(&(&1 == ""))
      |> Enum.to_list()
    job_list = (job_list ++ material_job_list ++ operations_job_list) |> Enum.uniq()
    if job_list == [] do #make list of jobs from job_operations from data_collection
      File.stream!(Path.join([File.cwd!(), "csv_files/operationtime.csv"]))
      |> GeneralCsvFunctions.initial_mapping()
      |> Enum.reverse
      |> Enum.reduce( [], fn [ job_operation | _], acc -> [String.to_integer(job_operation) | acc]  end)
      |> Shop.find_matching_operations
      |> Enum.map(fn row -> row.job end)
      |> Enum.uniq
    else
      job_list
    end
  end

  def load_blackout_dates do
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/load_blackout_dates.bat"])])
    File.stream!(Path.join([File.cwd!(), "csv_files/blackoutdates.csv"]))
    |> Stream.map(&String.trim(&1))
    |> Stream.map(&String.split(&1, "`"))
    |> Stream.filter(fn
      [_, "HolidayStart" | _] -> false #filter out header line
      ["-----------" | _] -> false #filter out empty line
      [_] -> false #lines with only one entry
      [_name | _] -> true
    end)
    |> Enum.map(fn [_name, start_date, end_date] ->
      {:ok, start_date} = NaiveDateTime.from_iso8601(start_date)
      {:ok, end_date} = NaiveDateTime.from_iso8601(end_date)
      for date <- Date.range(NaiveDateTime.to_date(start_date), NaiveDateTime.to_date(end_date)) do
        date
      end
    end)
    |> List.flatten()
  end

  def update_workcenters do #check for new workcenters to be added for department workcenter selection
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/load_workcenter.bat"])])
    workcenters =
      File.stream!(Path.join([File.cwd!(), "csv_files/workcenters.csv"]))
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.map(fn list ->
        case list do
          [first | rest] -> [String.replace(first, "\uFEFF", "") | rest]
          _ -> list
        end
      end)
      |> Enum.reduce( [], fn [ wc_vendor | _], acc -> [wc_vendor | acc] end)
      |> Enum.uniq
      |> Enum.filter(fn string -> !String.contains?(string, "rows affected") end)
      |> Enum.sort

    saved_workcenters = Enum.map(Shop.list_workcenters, &(&1.workcenter))
    workcenters
    |> Enum.reject(fn workcenter -> Enum.member?(saved_workcenters, workcenter) end) #filters out workcenters that already exist
    |> Enum.each(fn workcenter ->
      Shop.create_workcenter(%{"workcenter" => workcenter})
    end)
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
