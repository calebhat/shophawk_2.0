defmodule Shophawk.Shop.Csvimport do
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop

  def rework_to_do do #for testing



    #File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
    #File.write!(Path.join([File.cwd!(), "csv_files/last_export.text"]), DateTime.to_string(DateTime.utc_now()))
    #System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
    #data_collection_merge(Path.join([File.cwd!(), "csv_files/operationtime.csv"]))

  end

  def update_operations(caller_pid) do #quick import of most recent changes, updates currentop too.
    start_time = DateTime.utc_now()
    export_last_updated() #runs sql queries to only export jobs updated since last time it ran
    jobs_to_update = jobs_to_update() #creates list of all jobs #'s that have a change somewhere

    if jobs_to_update != [] do
      export_all_jobs_needed_to_update_data(jobs_to_update)

      operations = #Takes 25 seconds to merge 43K operations
      jobs_to_update
      |> runlist_ops(Path.join([File.cwd!(), "csv_files/runlistops.csv"])) #create map of all operations with a job listed in above function
      |> jobs_merge(Path.join([File.cwd!(), "csv_files/jobs.csv"])) #Merge job data with each operation
      |> mat_merge(Path.join([File.cwd!(), "csv_files/material.csv"])) #Merge material data with each operation
      |> uservalues_merge(Path.join([File.cwd!(), "csv_files/uservalues.csv"])) #Merge dots data with each operation
      |> Enum.map(fn map ->
        list = #for each map in the list, run it through changeset casting/validations. converts everything to correct datatype
          %Runlist{}
          |> Runlist.changeset(map)
        #have to manually add timestamps for insert all operation. Time must be in NavieDateTime for Ecto.
          list.changes #The changeset results in a list of data, extracts needed map from changeset.
          |> Map.put(:inserted_at, NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
          |> Map.put(:updated_at,  NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
          |> Map.put_new(:currentop, nil)
        end)

      {updated_list, _, _, _} = #set current op
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

      existing_records = #get structs of all operations needed for update
        Enum.map(operations, &(&1.job_operation))
        |> Enum.uniq #makes list of operation ID's to check for
        |> Shop.find_matching_operations #create list of structs that already exist in DB
        #|> job_finder()

      Enum.each(updated_list, fn op ->
        case Enum.find(existing_records, &(&1.job_operation == op.job_operation)) do
          nil -> #if the record does not exist, create a new one for it
            Shop.create_runlist(op)
          record ->   #if the record exists, update it with the new values
            Shop.update_runlist(record, op)
          end
      end)
      data_collection_merge(Path.join([File.cwd!(), "csv_files/operationtime.csv"])) #merge data collection
    end
    #IO.puts(DateTime.diff(DateTime.utc_now(), start_time, :milliseconds))

    send(caller_pid, :import_done)
  end

  def jobs_to_update() do #creates list of all jobs to update
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

      combined_list =
        job_list ++ material_job_list ++ operations_job_list
        |> Enum.uniq()
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
      [_, "NULL" | _] -> false
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

  def job_finder(operations) do #used for testing purposes.
    Enum.each(operations, fn op ->
      case op.job_operation do
      770743 -> IO.inspect(op.job_operation)
      IO.inspect(op.wc_vendor)
      _ ->
      end
    end)
    operations
  end

  def runlist_ops(jobs_to_update \\ [], file) do
    operations =
    File.stream!(file)
    |> Stream.map(&String.trim(&1))
    |> Stream.map(&String.split(&1, "`"))
    |> Stream.filter(fn
      [_, "NULL" | _] -> false
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
            rev: check_if_null(rev),
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

  def check_if_null(value) do
    if value = "NULL", do: nil, else: value
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

  def data_collection_merge(file) do
     empty_map = #used in case no match is found in material csv
      %{employee: nil,
        work_date: nil,
        act_setup_hrs: nil,
        act_run_hrs: nil,
        act_run_qty: nil,
        act_scrap_qty: nil,
        data_collection_note_text: nil
    }
    new_list =
      File.stream!(file)
      |> initial_mapping()
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
            %{job_operation: job_operation,
            employee: employee,
            work_date: work_date,
            act_setup_hrs: act_setup_hrs,
            act_run_hrs: act_run_hrs,
            act_run_qty: act_run_qty,
            act_scrap_qty: act_scrap_qty,
            data_collection_note_text: data_collection_note_text
            }
        [new_map | acc]  end)

      |> Enum.each(fn row ->
        runlist = Shop.get_runlist_by_job_operation(row.job_operation)
        changes =
          case runlist do
            nil -> %{}
            _ ->
              %{}
              |> Map.put(:act_run_hrs,
                case runlist.act_run_hrs do
                  nil -> String.to_float(row.act_run_hrs)
                  _ -> runlist.act_run_hrs + String.to_float(row.act_run_hrs)
                end)
              |> Map.put(:act_run_qty,
                case runlist.act_run_qty do
                  nil -> String.to_integer(row.act_run_qty)
                  _ -> runlist.act_run_qty + String.to_integer(row.act_run_qty)
                end)
              |> Map.put(:act_scrap_qty,
                case runlist.act_scrap_qty do
                  nil -> String.to_integer(row.act_scrap_qty)
                  _ -> runlist.act_scrap_qty + String.to_integer(row.act_scrap_qty)
                end)
              |> Map.put(:data_collection_note_text,
                case runlist.data_collection_note_text do
                  nil -> row.data_collection_note_text
                  _ -> runlist.data_collection_note_text <> " | " <> row.data_collection_note_text
                end)
              |> Map.put(:employee,
                case runlist.employee do
                  nil -> row.employee
                  _ -> runlist.employee <> " | " <> row.employee <> "-" <> Calendar.strftime(row.work_date, "%m-%d-%y")
                end)
              #need to change work_date to string type instead of date type for this to work.
              #|> Map.update(:work_date, "", fn value ->
              #  case value do
              #    nil -> row.work_date
              #    _ -> value <> "|" <> row.work_date
              #  end
              #end)
          end
        Shop.update_runlist(runlist, changes)
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
          Enum.map(operations, fn %{user_value: user_value} = map1 ->
            map2 = Enum.find(new_list, &(&1.user_value == user_value))
            if map2 do
              Map.merge(map1, map2)
            else
              Map.merge(map1, empty_map)
            end
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

  defp export_last_updated() do #changes short term batch files to export from database based on last export time.
    {:ok, prev_date, _} = File.read!(Path.join([File.cwd!(), "csv_files/last_export.text"])) |> DateTime.from_iso8601()
    time = DateTime.diff(prev_date, DateTime.utc_now(), :millisecond)
    if time == 0, do: time = -1
    File.write!(Path.join([File.cwd!(), "csv_files/last_export.text"]), DateTime.to_string(DateTime.utc_now()))

    #RunlistOps
    path = Path.join([File.cwd!(), "csv_files/runlistops.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Last_Updated > DATEADD(SECOND,<%= time %> / 1000,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1\n
    """
    sql_export = EEx.eval_string(export, [time: time, path: path])

    #Jobs
    path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job] WHERE Last_Updated > DATEADD(SECOND, <%= time %> / 1000,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    #material
    path = Path.join([File.cwd!(), "csv_files/material.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Last_Updated > DATEADD(SECOND, <%= time %> / 1000,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
  end

  defp export_all_jobs_needed_to_update_data(job_list) do
    {:ok, prev_date, _} = File.read!(Path.join([File.cwd!(), "csv_files/last_import.text"])) |> DateTime.from_iso8601()
    time = DateTime.diff(prev_date, DateTime.utc_now(), :millisecond)
    if time == 0, do: time = -1
    File.write!(Path.join([File.cwd!(), "csv_files/last_import.text"]), DateTime.to_string(DateTime.utc_now()))

    #create string that is readable for sql command
    jobs_to_export = "(" <> Enum.join(Enum.map(job_list, &("'" <> &1 <> "'")), ", ") <> ")"

    #RunlistOps
    path = Path.join([File.cwd!(), "csv_files/runlistops.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Job_Operation] ,[WC_Vendor] ,[Operation_Service] ,[Vendor] ,[Sched_Start] ,[Sched_End] ,[Sequence], [Status] ,[Est_Total_Hrs] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Job in <%= jobs_to_export %> ORDER BY Job_Operation ASC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1\n
    """
    sql_export = EEx.eval_string(export, [jobs_to_export: jobs_to_export, path: path])

    #Jobs
    path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Customer] ,[Order_Date] ,[Part_Number], [Status] ,[Rev] ,[Description] ,[Order_Quantity] ,[Extra_Quantity] ,[Pick_Quantity] ,[Make_Quantity] ,[Open_Operations] ,[Completed_Quantity] ,[Shipped_Quantity] ,[Customer_PO] ,[Customer_PO_LN] ,[Sched_End] ,[Sched_Start] ,REPLACE (CONVERT(VARCHAR(MAX), Note_Text),CHAR(13)+CHAR(10),' ') ,[Released_Date] ,[User_Values] FROM [PRODUCTION].[dbo].[Job] WHERE Job in <%= jobs_to_export %> ORDER BY Job DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [jobs_to_export: jobs_to_export, path: path, prev_command: sql_export])

    #material
    path = Path.join([File.cwd!(), "csv_files/material.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Material] ,[Vendor] ,[Description] ,[Pick_Buy_Indicator] ,[Status] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Job in <%= jobs_to_export %> ORDER BY Job DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [jobs_to_export: jobs_to_export, path: path, prev_command: sql_export])

    #UserValues
    path = Path.join([File.cwd!(), "csv_files/uservalues.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [User_Values] ,[Text1] FROM [PRODUCTION].[dbo].[User_Values] WHERE Text1 IS NOT NULL AND Last_Updated > DATEADD(SECOND, <%= time %> / 1000,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    #operation time - Data collection
    path = Path.join([File.cwd!(), "csv_files/operationtime.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job_Operation] ,[Employee] ,[Work_Date] ,[Act_Setup_Hrs] ,[Act_Run_Hrs] ,[Act_Run_Qty] ,[Act_Scrap_Qty] ,[Note_Text] FROM [PRODUCTION].[dbo].[Job_Operation_Time] WHERE Last_Updated > DATEADD(SECOND,<%= time %> / 1000,GETDATE()) ORDER BY Job_Operation DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
  end

  def import_last_year() do #imports ALL operations from the past 13 months into the database, !will make duplicates!
    export_last_year()
    operations = #Takes 25 seconds to merge 43K operations
      runlist_ops(Path.join([File.cwd!(), "csv_files/runlistops.csv"])) #create map of all operations from the past year
      |> jobs_merge(Path.join([File.cwd!(), "csv_files/jobs.csv"])) #Merge job data with each operation
      |> mat_merge(Path.join([File.cwd!(), "csv_files/material.csv"])) #Merge material data with each operation
      |> uservalues_merge(Path.join([File.cwd!(), "csv_files/uservalues.csv"])) #Merge dots data with each operation
      |> Enum.map(fn map ->
        list = #for each map in the list, run it through changeset casting/validations. converts everything to correct datatype
          %Runlist{}
          |> Runlist.changeset(map)
        #have to manually add timestamps for insert all operation. Time must be in NavieDateTime for Ecto.
          list.changes #The changeset results in a list of data, extracts needed map from changeset.
          |> Map.put(:inserted_at, NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
          |> Map.put(:updated_at,  NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
          |> Map.update(:est_total_hrs, 0.00, fn hrs -> Float.round(hrs, 2) end)
        end)

    Shop.import_all(operations) #imports all findings to the database at one time.
  end

  defp export_last_year() do #changes short term batch files to export from database based on last export time.

    #RunlistOps
    path = Path.join([File.cwd!(), "csv_files/runlistops.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Job_Operation] ,[WC_Vendor] ,[Operation_Service] ,[Vendor] ,[Sched_Start] ,[Sched_End] ,[Sequence], [Status] ,[Est_Total_Hrs] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Last_Updated > DATEADD(MONTH,-13,GETDATE()) ORDER BY Job_Operation ASC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1\n
    """
    sql_export = EEx.eval_string(export, [path: path])

    #Jobs
    path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Customer] ,[Order_Date] ,[Part_Number], [Status] ,[Rev] ,[Description] ,[Order_Quantity] ,[Extra_Quantity] ,[Pick_Quantity] ,[Make_Quantity] ,[Open_Operations] ,[Completed_Quantity] ,[Shipped_Quantity] ,[Customer_PO] ,[Customer_PO_LN] ,[Sched_End] ,[Sched_Start] ,REPLACE (CONVERT(VARCHAR(MAX), Note_Text),CHAR(13)+CHAR(10),' ') ,[Released_Date] ,[User_Values] FROM [PRODUCTION].[dbo].[Job] WHERE Last_Updated > DATEADD(MONTH,-13,GETDATE()) ORDER BY Job DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [path: path, prev_command: sql_export])

    #material
    path = Path.join([File.cwd!(), "csv_files/material.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Material] ,[Vendor] ,[Description] ,[Pick_Buy_Indicator] ,[Status] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Last_Updated > DATEADD(MONTH,-13,GETDATE()) ORDER BY Job DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [path: path, prev_command: sql_export])

    #UserValues
    path = Path.join([File.cwd!(), "csv_files/uservalues.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [User_Values] ,[Text1] FROM [PRODUCTION].[dbo].[User_Values] WHERE Text1 IS NOT NULL AND Last_Updated > DATEADD(MONTH,-13,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [path: path, prev_command: sql_export])

    File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
  end

end
