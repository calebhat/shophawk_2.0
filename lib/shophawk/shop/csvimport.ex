defmodule Shophawk.Shop.Csvimport do
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop

  def rework_to_do do
#WORKING, NEED TO RUN ON PROD DB TO SYNC ALL OLD DATA COLLECTION.
    Enum.chunk_every(export_active_jobs() , 500) #breaks the list up into chunks
    |> Enum.map(fn jobs_chunk ->
      export_job_chunk(jobs_chunk) #export csv files for each chunk.
      operations = runlist_ops(Path.join([File.cwd!(), "csv_files/runlistops.csv"])) #create map of all operations from the past year

      job_operations_to_export =
        operations
        |> Enum.map(&Map.get(&1, :job_operation))
        |> case do
          [] -> false
          job_operations -> "(" <> Enum.join(job_operations, ", ") <> ")"
        end

      sql_export =
        if job_operations_to_export do
          #Job_operation_time
          path = Path.join([File.cwd!(), "csv_files/operationtime.csv"])
          export = """
          sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job_Operation] ,[Employee] ,[Work_Date] ,[Act_Setup_Hrs] ,[Act_Run_Hrs] ,[Act_Run_Qty] ,[Act_Scrap_Qty] ,[Note_Text] FROM [PRODUCTION].[dbo].[Job_Operation_Time] WHERE Job_Operation in <%= job_operations_to_export %> ORDER BY Job_Operation DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1
          """
          EEx.eval_string(export, [job_operations_to_export: job_operations_to_export, path: path])
        else
          ""
        end

      if sql_export != "" do
        File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
        System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
      end
      #LIST OF OPERATIONS FROM OPERATIONS LIST

      update_data_collection_only()
    end)

  end

  def save_enum_to_text(data) do
    file_content = Enum.reduce(data, "", fn map, acc -> acc <> inspect(map) <> "\n" end)
    File.write!(Path.join([File.cwd!(), "csv_files/see_data.text"]), file_content)
  end

  def update_operations(caller_pid, rewind_seconds) do #quick import of most recent changes, updates currentop too.
    start_time = DateTime.utc_now()
    export_last_updated(rewind_seconds) #runs sql queries to only export jobs updated since last time it ran
    #create list of all jobs #'s that have a change somewhere
    job_list = #make a list of jobs that changed
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
    jobs_to_update = job_list ++ material_job_list ++ operations_job_list |> Enum.uniq()
    if jobs_to_update != [] do
      operations =
        Enum.chunk_every(jobs_to_update, 500) #breaks the list up into chunks
        |> Enum.map(fn jobs_chunk ->
          export_job_chunk(jobs_chunk) #export csv files for each chunk.
          runlist_ops(Path.join([File.cwd!(), "csv_files/runlistops.csv"])) #create map of all operations from the past year
          |> jobs_merge(Path.join([File.cwd!(), "csv_files/jobs.csv"])) #Merge job data with each operation
          |> mat_merge(Path.join([File.cwd!(), "csv_files/material.csv"])) #Merge material data with each operation
          |> export_and_merge_new_job_operations_and_user_value()
          |> set_current_ops()
          |> set_material_waiting()
        end)
        |> Enum.reduce([], fn result, acc -> acc ++ result end)
      existing_records = #get structs of all operations needed for update
        Enum.map(operations, &(&1.job_operation))
        |> Enum.uniq #makes list of operation ID's to check for
        |> Shop.find_matching_operations #create list of structs that already exist in DB
      Enum.each(operations, fn op ->
        case Enum.find(existing_records, &(&1.job_operation == String.to_integer(op.job_operation))) do
          nil -> #if the record does not exist, create a new one for it
            Shop.create_runlist(op)
          record ->   #if the record exists, update it with the new values
            op = merge_existing_data_collection(record, op)
            Shop.update_runlist(record, op)
          end
      end)
    else
      update_data_collection_only()
    end
    IO.puts("Import Complete - " <> Integer.to_string(Enum.count(jobs_to_update)) <> " Jobs Updated")
    if caller_pid != nil do
      send(caller_pid, :import_done)
    end
  end

  def update_data_collection_only() do
    process_csv(Path.join([File.cwd!(), "csv_files/operationtime.csv"]), 8)
    existing_records =
      File.stream!(Path.join([File.cwd!(), "csv_files/operationtime.csv"]))
      |> initial_mapping()
      |> Enum.reverse
      |> Enum.reduce( [], fn [ job_operation | _], acc -> [String.to_integer(job_operation) | acc]  end)
      |> Shop.find_matching_operations
      |> Enum.map(fn op -> if op.data_collection_note_text == nil, do: Map.put(op, :data_collection_note_text, ""), else: op end)

      merged_ops =
        Enum.map(existing_records, fn map ->
          map
          |> Map.put(:est_total_hrs, 0.00)
          |> Map.put(:currentop, nil) #add keys for data_collection_merge after the changeset
          |> Map.put(:employee, nil) #add needed keys for data-collection merge
          |> Map.put(:work_date, nil)
          |> Map.put(:act_setup_hrs, 0.0)
          |> Map.put(:act_run_hrs, 0.0)
          |> Map.put(:act_run_qty, 0.0)
          |> Map.put(:act_scrap_qty, 0.0)
          |> Map.put(:data_collection_note_text, "")
        end)
        |> data_collection_merge(Path.join([File.cwd!(), "csv_files/operationtime.csv"]))

      Enum.each(merged_ops, fn op ->
        case Enum.find(existing_records, &(&1.job_operation == op.job_operation)) do
          existing_record ->   #if the record exists, update it with the new values
            op = merge_existing_data_collection(existing_record, op) |> Map.from_struct
            Shop.update_runlist(existing_record, op)
          _ -> nil
          end
      end)
  end

  def merge_existing_data_collection(record, op) do
    op =
      if op.employee != nil do
        new_runlist_data =
          %{}
          |> Map.put(:act_run_hrs,
            case op.act_run_hrs do
              nil -> record.act_run_hrs
              _ -> op.act_run_hrs + record.act_run_hrs
            end)
          |> Map.put(:act_run_qty,
            case op.act_run_qty do
              nil -> record.act_run_qty
              _ -> op.act_run_qty + record.act_run_qty
            end)
          |> Map.put(:act_setup_hrs,
          case op.act_setup_hrs do
            nil -> record.act_setup_hrs
            _ -> op.act_setup_hrs + record.act_setup_hrs
            end)
          |> Map.put(:act_scrap_qty,
            case op.act_scrap_qty do
              nil -> record.act_scrap_qty
              _ -> op.act_scrap_qty + record.act_scrap_qty
            end)
          |> Map.put(:data_collection_note_text,
            case op.data_collection_note_text do
              nil -> record.data_collection_note_text
              "" -> record.data_collection_note_text
              _ -> record.data_collection_note_text <> " | " <> op.data_collection_note_text
            end)
          |> Map.put(:employee,
            case op.employee do
              nil -> record.employee
              "" -> record.employee
              _ ->
                if record.employee != nil do
                  record.employee <> " | " <> op.employee
                  |> String.split("|")
                  |> Enum.map(&String.trim/1)
                  |> Enum.uniq
                  |> Enum.join(" | ")
                else
                  op.employee
                end
            end)
          Map.merge(op, new_runlist_data)
      else
        op
      end
  end

  def import_all_history() do
    #sets time for auto import function to start from
    File.write!(Path.join([File.cwd!(), "csv_files/last_import.text"]), DateTime.to_string(DateTime.utc_now()))

    #all_jobs = export_all_jobs() #creates list of every job made so far
    all_jobs = export_active_jobs() #testing

    #all_jobs_count = Enum.count(all_jobs)
    #IO.inspect(all_jobs_count)
    Stream.chunk_every(all_jobs, 400) #breaks the list up into chunks
    |> Enum.map(fn jobs_chunk ->
      start = DateTime.utc_now()
      operations =
        export_job_chunk(jobs_chunk) #export csv files for each chunk.
        runlist_ops(Path.join([File.cwd!(), "csv_files/runlistops.csv"])) #create map of all operations from the past year
        |> jobs_merge(Path.join([File.cwd!(), "csv_files/jobs.csv"])) #Merge job data with each operation
        |> mat_merge(Path.join([File.cwd!(), "csv_files/material.csv"])) #Merge material data with each operation
        |> export_and_merge_new_job_operations_and_user_value()
        |> set_current_ops()
        |> set_material_waiting()
        |> Enum.map(fn map ->
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
      Shop.import_all(operations)
      IO.puts("milliseconds: #{DateTime.diff(DateTime.utc_now(), start, :millisecond)}")
    end)
  end

  defp initial_mapping(list) do
    list
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
      [job | _] -> true end)
  end

  def load_blackout_dates do
    System.cmd("cmd", ["/C", "C:\\phoenixapps\\shophawk\\batch_files\\load_blackout_dates.bat"])

    blackout_dates =
      File.stream!(Path.join([File.cwd!(), "csv_files/blackoutdates.csv"]))
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.filter(fn
        [_, "HolidayStart" | _] -> false #filter out header line
        ["-----------" | _] -> false #filter out empty line
        [_] -> false #lines with only one entry
        [name | _] -> true
      end)
      |> Enum.map(fn [name, start_date, end_date] ->
        {:ok, start_date} = NaiveDateTime.from_iso8601(start_date)
        {:ok, end_date} = NaiveDateTime.from_iso8601(end_date)
        for date <- Date.range(NaiveDateTime.to_date(start_date), NaiveDateTime.to_date(end_date)) do
          date
        end
      end)
      |> List.flatten()
  end

  def update_workcenters do #check for new workcenters to be added for department workcenter selection
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
      |> Enum.sort

    saved_workcenters = Enum.map(Shop.list_workcenters, &(&1.workcenter))
    workcenters
      |> Enum.reject(fn workcenter -> Enum.member?(saved_workcenters, workcenter) end) #filters out workcenters that already exist
      |> Enum.reduce(%{}, fn workcenter, acc ->
        Shop.create_workcenter(%{"workcenter" => workcenter})
      end)
  end

  def runlist_ops(jobs_to_update \\ [], file) do
    operations =
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
    |> Enum.reduce( [],
    fn
    [
      job,
      job_operation,
      wc_vendor,
      operation_service,
      vendor,
      sched_start,
      sched_end,
      sequence,
      status,
      est_total_hrs | _], acc ->
      new_map =
        %{job: job,
        job_operation: job_operation,
        wc_vendor: wc_vendor,
        operation_service: operation_service,
        sched_start: sched_start,
        sched_end: sched_end,
        sequence: sequence,
        status: status,
        est_total_hrs: est_total_hrs
        }
      [new_map | acc] end)
  end

  def jobs_merge(operations, file) do
    #empty map to make sure all fields are included in the map for later stuct
    empty_map =
      %{
      customer: nil,
      order_date: nil,
      part_number: nil,
      job_status: nil,
      rev: nil,
      description: nil,
      order_quantity: nil,
      extra_quantity: nil,
      pick_quantity: nil,
      make_quantity: nil,
      open_operations: nil,
      shipped_quantity: nil,
      customer_po: nil,
      customer_po_line: nil,
      job_sched_end: nil,
      job_sched_start: nil,
      released_date: nil,
      note_text: nil,
      user_value: nil
      }
    new_list =
      File.stream!(file)
      |> initial_mapping()
      |> Enum.reduce( [],
      fn
      [
        job,
        customer,
        order_date,
        part_number,
        job_status,
        rev,
        description,
        order_quantity,
        extra_quantity,
        pick_quantity,
        make_quantity,
        open_operations,
        completed_quantity,
        shipped_quantity,
        customer_po,
        customer_po_line,
        job_sched_end,
        job_sched_start,
        note_text,
        released_date,
        user_value | _], acc ->
          new_map =
            %{job: job,
            customer: customer,
            order_date: order_date,
            part_number: part_number,
            job_status: job_status,
            rev: rev,
            description: description,
            order_quantity: order_quantity,
            extra_quantity: extra_quantity,
            pick_quantity: pick_quantity,
            make_quantity: make_quantity,
            open_operations: open_operations,
            shipped_quantity: shipped_quantity,
            customer_po: customer_po,
            customer_po_line: customer_po_line,
            job_sched_end: job_sched_end,
            job_sched_start: job_sched_start,
            released_date: released_date,
            note_text: note_text,
            user_value: user_value
            }
        [new_map | acc]  end)

        merged_list = Enum.map(operations, fn %{job: job} = map1 ->
          #find the corresponding map in new_list based on job value
          map2 = Enum.find(Enum.reverse(new_list), &(&1.job == job))

          if map2 do
            Map.merge(map1, map2)
          else
            Map.merge(map1, empty_map)
          end
        end)
  end

  defp set_current_ops(operations) do
    {operations, _, _, _} = #set current op
      Enum.reduce(Enum.reverse(operations), {[], nil, nil, false}, fn op, {acc, last_wc_vendor, last_job, hold} ->
        case {op.status, op.job, hold} do
          {"O", job, _} when last_job == nil -> #for starting the search and no previous operation to go from
            {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor, op.job, true}

          {"O", job, false} when job == last_job -> #locks in the current wc_vendor to hold for next one
            {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor, op.job, true}

          {"O", job, true} when job == last_job -> #continues setting the previous wc_vendor
            {[%{op | currentop: last_wc_vendor} | acc], last_wc_vendor, op.job, true}

          {"O", job, true} -> #if found a new job
            {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor, op.job, true}

          {"S", job, _} when last_job == nil -> #for starting the search and no previous operation to go from
          {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor, op.job, true}

          {"S", job, false} when job == last_job -> #locks in the current wc_vendor to hold for next one
            {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor, op.job, true}

          {"S", job, true} when job == last_job -> #continues setting the previous wc_vendor
            {[%{op | currentop: last_wc_vendor} | acc], last_wc_vendor, op.job, true}

          {"S", job, _} -> #if found a new job
            {[%{op | currentop: op.wc_vendor} | acc], op.wc_vendor, op.job, true}

          {"C", job, _}  ->
            {[%{op | currentop: nil} | acc], nil, op.job, false}

          {_, _, _} ->
            {[%{op | currentop: nil} | acc], nil, op.job, false}
        end
      end)
    Enum.reverse(operations)
  end

  defp set_material_waiting(operations) do
    operations = Enum.map(operations, fn op ->
      if op.currentop == "IN" do
        Map.put_new(op, :material_waiting, true)
      else
        op
      end
    end)
    operations
  end

  def check_if_null(value) do
    if value = "NULL", do: "", else: value
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
    keys_to_exclude = [:job]
    new_list =
      File.stream!(file)
      |> initial_mapping()
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

  def data_collection_merge(operations, file) do
    new_data_collection_map_list =
      File.stream!(file)
      |> initial_mapping()
      |> Enum.reverse
      |> Enum.reduce( [],
      fn
      [ job_operation,
        employee,
        work_date,
        act_setup_hrs,
        act_run_hrs,
        act_run_qty,
        act_scrap_qty,
        data_collection_note_text | _], acc ->
          new_map =
            %{job_operation: String.to_integer(job_operation),
            employee: employee,
            work_date: work_date,
            act_setup_hrs: String.to_float(act_setup_hrs),
            act_run_hrs: String.to_float(act_run_hrs),
            act_run_qty: String.to_integer(act_run_qty),
            act_scrap_qty: String.to_integer(act_scrap_qty),
            data_collection_note_text: data_collection_note_text
            }
        [new_map | acc]  end)

    Enum.map(operations, fn %{job_operation: job_operation} = op ->
      new_runlist_data = Enum.filter(new_data_collection_map_list, &((&1.job_operation) == job_operation))
      starting_map = %{act_run_hrs: op.act_run_hrs, act_run_qty: op.act_run_qty, act_scrap_qty: op.act_scrap_qty,  data_collection_note_text: op.data_collection_note_text, employee: op.employee}
      starting_map = if starting_map.data_collection_note_text == nil, do: Map.put(starting_map, :data_collection_note_text, ""), else: starting_map
      starting_map = if starting_map.employee == nil, do: Map.put(starting_map, :employee, ""), else: starting_map

      new_runlist_data_map =
      if new_runlist_data != [] do
        Enum.reduce(new_runlist_data, starting_map, fn new_runlist_data_op, map ->
          {:ok, work_date, _} = DateTime.from_iso8601(String.replace(new_runlist_data_op.work_date, " ", "T") <> "Z")
          work_date = Calendar.strftime(work_date, "%m-%d-%y")

          new_runlist_data =
          %{}
          |> Map.put(:act_run_hrs,
            case new_runlist_data_op.act_run_hrs do
              nil -> map.act_run_hrs
              _ -> map.act_run_hrs + new_runlist_data_op.act_run_hrs
            end)
          |> Map.put(:act_run_qty,
            case new_runlist_data_op.act_run_qty do
              nil -> map.act_run_qty
              _ -> map.act_run_qty + new_runlist_data_op.act_run_qty
            end)
          |> Map.put(:act_scrap_qty,
            case new_runlist_data_op.act_scrap_qty do
              nil -> map.act_scrap_qty
              _ -> map.act_scrap_qty + new_runlist_data_op.act_scrap_qty
            end)
          |> Map.put(:data_collection_note_text,
            case new_runlist_data_op.data_collection_note_text do
              "" -> map.data_collection_note_text
              nil -> map.data_collection_note_text
              _ -> map.data_collection_note_text <> " | " <> new_runlist_data_op.data_collection_note_text
            end)
          |> Map.put(:employee,
            case new_runlist_data_op.employee do
              "" -> map.employee
              nil -> map.employee
              _ -> map.employee <> " | " <> new_runlist_data_op.employee <> ": " <> work_date
            end)
        end)
      else
        starting_map
      end
      new_map = Map.merge(op, new_runlist_data_map)

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

  def uservalues_merge(operations, file) do
    empty_map = %{user_value: nil, dots: nil} #used in case no match is found in material csv
    new_list =
      File.stream!(file)
      |> initial_mapping()
      |> Enum.reduce( [],
        fn [user_value, dots | _], acc ->
          new_map = %{user_value: user_value, dots: dots_calc(dots)}
          [new_map | acc]  end)
    if new_list != [] do #csv could be empty if no matching user values found
      Enum.map(operations, fn %{user_value: user_value} = op ->
        new_runlist_data = Enum.find(new_list, &(&1.user_value == user_value))
        if new_runlist_data do
          Map.merge(op, new_runlist_data)
        else
          op
        end
      end)
    else
      operations
    end
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

  def process_csv(file_path, columns) do #Checks for any rows that have the wrong # of columns and kicks them out.
    expected_columns = columns

    new_data =
    File.stream!(file_path)
    |> Stream.map(&normalize_row(&1, expected_columns))
    |> Stream.filter(&is_list/1) # Filter out results that are not lists
    |> Stream.map(&Enum.join(&1, "`"))
    |> Enum.join("")

    File.write!(file_path, new_data)
  end

  defp normalize_row(row, expected_columns) do
    try do
      row
      |> String.split("`")
      |> Enum.map(&replace_null/1)
      |> validate_length(expected_columns)
    rescue
      _ ->
        #IO.puts("Skipping invalid row: #{row}")
        nil # Return nil to signal that the row should be skipped
    end
  end

  defp replace_null(value) do
    Regex.replace(~r/\bNULL\b/, value, "") #replaces exact matches of NULL with nothing. this leave /n (new lines) if null is the last value in the row.
  end

  defp validate_length(values, expected_columns) do #checks length of rows coming in from CSV and kicks them out if they don't match
    if Enum.count(values) == expected_columns do
      values
    else
      raise "csv row is incorrect length"
    end
  end

  defp export_last_updated(additional_seconds) do #changes short term batch files to export from database based on last export time.
    {:ok, prev_date, _} = File.read!(Path.join([File.cwd!(), "csv_files/last_export.text"])) |> DateTime.from_iso8601()
    time = DateTime.diff(prev_date, DateTime.truncate(DateTime.utc_now(), :second))
    time = time - additional_seconds
    File.write!(Path.join([File.cwd!(), "csv_files/last_export.text"]), DateTime.to_string(DateTime.truncate(DateTime.utc_now(), :second)))

    #RunlistOps
    path = Path.join([File.cwd!(), "csv_files/runlistops.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Last_Updated > DATEADD(SECOND,<%= time %>,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1\n
    """
    sql_export = EEx.eval_string(export, [time: time, path: path])

    #Jobs
    path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job] WHERE Last_Updated > DATEADD(SECOND, <%= time %>,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    #material
    path = Path.join([File.cwd!(), "csv_files/material.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Last_Updated > DATEADD(SECOND, <%= time %>,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    #Job_operation_time
    path = Path.join([File.cwd!(), "csv_files/operationtime.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job_Operation] ,[Employee] ,[Work_Date] ,[Act_Setup_Hrs] ,[Act_Run_Hrs] ,[Act_Run_Qty] ,[Act_Scrap_Qty] ,[Note_Text] FROM [PRODUCTION].[dbo].[Job_Operation_Time] WHERE Last_Updated > DATEADD(SECOND, <%= time %>,GETDATE()) ORDER BY Job_Operation DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
  end

  defp export_and_merge_new_job_operations_and_user_value(operations) do

    #format lists for sql command to read properaly
    job_operations_to_export =
      operations
      |> Enum.map(&Map.get(&1, :job_operation))
      |> case do
        [] -> false
        job_operations -> "(" <> Enum.join(job_operations, ", ") <> ")"
      end

    user_values_to_export =
      operations
      |> Enum.map(&Map.get(&1, :user_value))
      |> Enum.reject(&(&1 == nil or &1 == "")) # Filter out nil values
      |> case do
        [] -> false  # Handle the case where all user values are nil
        user_values -> "(" <> Enum.join(user_values, ", ") <> ")"
      end

    sql_export =
      if job_operations_to_export do
        #Job_operation_time
        path = Path.join([File.cwd!(), "csv_files/operationtime.csv"])
        export = """
        sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job_Operation] ,[Employee] ,[Work_Date] ,[Act_Setup_Hrs] ,[Act_Run_Hrs] ,[Act_Run_Qty] ,[Act_Scrap_Qty] ,[Note_Text] FROM [PRODUCTION].[dbo].[Job_Operation_Time] WHERE Job_Operation in <%= job_operations_to_export %> ORDER BY Job_Operation DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1
        """
        EEx.eval_string(export, [job_operations_to_export: job_operations_to_export, path: path])
      else
        ""
      end

    sql_export =
      if user_values_to_export do
        #user values
        path = Path.join([File.cwd!(), "csv_files/uservalues.csv"])
        export = """
        sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [User_Values] ,[Text1] FROM [PRODUCTION].[dbo].[User_Values] WHERE Text1 IS NOT NULL AND User_Values in <%= user_values_to_export %>" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
        """
        EEx.eval_string(export, [user_values_to_export: user_values_to_export, path: path, prev_command: sql_export])
      else
        sql_export
      end

    if sql_export != "" do
      File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
      System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])

      operations =
        if user_values_to_export do
          process_csv(Path.join([File.cwd!(), "csv_files/uservalues.csv"]), 2)
          uservalues_merge(operations, Path.join([File.cwd!(), "csv_files/uservalues.csv"])) #Merge dots data with each operation
        else
          operations
        end

      operations =
        if job_operations_to_export do
          process_csv(Path.join([File.cwd!(), "csv_files/operationtime.csv"]), 8)
          Enum.map(operations, fn map ->
            map
            |> Map.update(:est_total_hrs, 0.00, fn hrs -> Float.round(String.to_float(hrs), 2) end)
            |> Map.put_new(:currentop, nil) #add keys for data_collection_merge after the changeset
            |> Map.put_new(:employee, nil) #add needed keys for data-collection merge
            |> Map.put_new(:work_date, nil)
            |> Map.put_new(:act_setup_hrs, 0.0)
            |> Map.put_new(:act_run_hrs, 0.0)
            |> Map.put_new(:act_run_qty, 0.0)
            |> Map.put_new(:act_scrap_qty, 0.0)
            |> Map.put_new(:data_collection_note_text, nil)
          end)
          |> data_collection_merge(Path.join([File.cwd!(), "csv_files/operationtime.csv"]))
        else
          operations
        end
    else
      operations
    end
  end

  defp export_job_chunk(job_list) do
    #create string that is readable for sql command
    jobs_to_export = "(" <> Enum.join(Enum.map(job_list, &("'" <> &1 <> "'")), ", ") <> ")"

    #RunlistOps
    path = Path.join([File.cwd!(), "csv_files/runlistops.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Job_Operation] ,[WC_Vendor] ,REPLACE (CONVERT(VARCHAR(MAX), Operation_Service),'`','') ,[Vendor] ,[Sched_Start] ,[Sched_End] ,[Sequence], [Status] ,[Est_Total_Hrs] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Job in <%= jobs_to_export %> ORDER BY Job, COALESCE(Sched_Start, '9999-12-31') ASC, Job_Operation ASC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1\n\n
    """
    sql_export = EEx.eval_string(export, [jobs_to_export: jobs_to_export, path: path])

    #Jobs
    path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Customer] ,[Order_Date] ,[Part_Number], [Status] ,[Rev] ,[Description] ,[Order_Quantity] ,[Extra_Quantity] ,[Pick_Quantity] ,[Make_Quantity] ,[Open_Operations] ,[Completed_Quantity] ,[Shipped_Quantity] ,[Customer_PO] ,[Customer_PO_LN] ,[Sched_End] ,[Sched_Start] ,REPLACE (CONVERT(VARCHAR(MAX), Note_Text),CHAR(13)+CHAR(10),' ') ,[Released_Date] ,[User_Values] FROM [PRODUCTION].[dbo].[Job] WHERE Job in <%= jobs_to_export %> ORDER BY Job DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n\n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [jobs_to_export: jobs_to_export, path: path, prev_command: sql_export])

    #material
    path = Path.join([File.cwd!(), "csv_files/material.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,REPLACE (CONVERT(VARCHAR(MAX), Material),'`','') ,[Vendor] ,[Description] ,[Pick_Buy_Indicator] ,[Status] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Job in <%= jobs_to_export %> ORDER BY Job DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n\n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [jobs_to_export: jobs_to_export, path: path, prev_command: sql_export])

    File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
    process_csv(Path.join([File.cwd!(), "csv_files/runlistops.csv"]), 10)
    process_csv(Path.join([File.cwd!(), "csv_files/jobs.csv"]), 21)
    process_csv(Path.join([File.cwd!(), "csv_files/material.csv"]), 6)
  end

  defp export_all_jobs() do #changes short term batch files to export from database based on last export time.
  #Jobs
  path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
  export = """
  sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job] WHERE status != 'Template'" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1
  """
  sql_export = EEx.eval_string(export, [path: path])
  File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
  System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
  File.stream!(Path.join([File.cwd!(), "csv_files/jobs.csv"]))
    |> Stream.map(&String.trim(&1))
    |> Stream.map(&String.replace(&1, "\uFEFF", ""))
    |> Stream.reject(&String.contains?(&1, "("))
    |> Stream.reject(&(&1 == ""))
    |> Enum.to_list()
  end

  defp export_active_jobs() do #FOR TESTING SMALL DATASETS
  #Jobs
  path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
  export = """
  sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job] WHERE status != 'Template' AND Status='Active'" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1
  """
  sql_export = EEx.eval_string(export, [path: path])
  File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
  System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
  File.stream!(Path.join([File.cwd!(), "csv_files/jobs.csv"]))
    |> Stream.map(&String.trim(&1))
    |> Stream.map(&String.replace(&1, "\uFEFF", ""))
    |> Stream.reject(&String.contains?(&1, "("))
    |> Stream.reject(&(&1 == ""))
    |> Enum.to_list()
  end

end
