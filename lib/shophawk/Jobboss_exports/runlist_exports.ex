defmodule Shophawk.RunlistExports do
  alias Shophawk.GeneralCsvFunctions
  #all exports specific to the runlist

  def export_data_collection_and_user_values(operations) do
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
      if job_operations_to_export != [] do
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
      if user_values_to_export != [] do
        #user values
        path = Path.join([File.cwd!(), "csv_files/uservalues.csv"])
        export = """
        sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [User_Values] ,[Text1] FROM [PRODUCTION].[dbo].[User_Values] WHERE Text1 IS NOT NULL AND User_Values in <%= user_values_to_export %>" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
        """
        EEx.eval_string(export, [user_values_to_export: user_values_to_export, path: path, prev_command: sql_export])
      else
        sql_export
      end

      File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
      System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
      merge_data = if job_operations_to_export != [], do: true, else: false
      merge_user = if user_values_to_export != [], do: true, else: false
    {operations, merge_data, merge_user}
  end

  def export_last_updated(additional_milliseconds) do #changes short term batch files to export from database based on last export time.
    {:ok, prev_date, _} = File.read!(Path.join([File.cwd!(), "csv_files/last_export.text"])) |> DateTime.from_iso8601()
    File.write!(Path.join([File.cwd!(), "csv_files/last_export.text"]), DateTime.to_string(DateTime.truncate(DateTime.utc_now(), :millisecond)))

    time = DateTime.diff(prev_date, DateTime.utc_now(), :millisecond)
    time = time - additional_milliseconds

    #RunlistOps
    path = Path.join([File.cwd!(), "csv_files/runlistops.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Last_Updated > DATEADD(MILLISECOND,<%= time %>,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1\n
    """
    sql_export = EEx.eval_string(export, [time: time, path: path])

    #Jobs
    path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job] WHERE Last_Updated > DATEADD(MILLISECOND, <%= time %>,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    #material
    path = Path.join([File.cwd!(), "csv_files/material.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Last_Updated > DATEADD(MILLISECOND, <%= time %>,GETDATE())" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    #Job_operation_time
    path = Path.join([File.cwd!(), "csv_files/operationtime.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job_Operation] ,[Employee] ,[Work_Date] ,[Act_Setup_Hrs] ,[Act_Run_Hrs] ,[Act_Run_Qty] ,[Act_Scrap_Qty] ,[Note_Text] FROM [PRODUCTION].[dbo].[Job_Operation_Time] WHERE Last_Updated > DATEADD(MILLISECOND, <%= time %>,GETDATE()) ORDER BY Job_Operation DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n<%= prev_command %>
    """
    sql_export = EEx.eval_string(export, [time: time, path: path, prev_command: sql_export])

    File.write!(Path.join([File.cwd!(), "batch_files/data_export.bat"]), sql_export)
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/data_export.bat"])])
  end

  def export_job_chunk(job_list) do
    #create string that is readable for sql command
    jobs_to_export = "(" <> Enum.join(Enum.map(job_list, &("'" <> &1 <> "'")), ", ") <> ")"

    #RunlistOps
    path = Path.join([File.cwd!(), "csv_files/runlistops.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Job_Operation] ,[WC_Vendor] ,REPLACE (CONVERT(VARCHAR(MAX), Operation_Service),'`','') ,[Sched_Start] ,[Sched_End] ,[Sequence], [Status] ,[Est_Total_Hrs] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Job in <%= jobs_to_export %> ORDER BY Job, COALESCE(Sched_Start, '9999-12-31') ASC, Job_Operation ASC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1\n\n
    """
    sql_export = EEx.eval_string(export, [jobs_to_export: jobs_to_export, path: path])

    #Jobs
    path = Path.join([File.cwd!(), "csv_files/jobs.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Customer] ,[Order_Date] ,[Part_Number], [Status] ,[Rev] ,[Description] ,[Order_Quantity] ,[Extra_Quantity] ,[Pick_Quantity] ,[Make_Quantity] ,[Open_Operations] ,[Shipped_Quantity] ,[Customer_PO] ,[Customer_PO_LN] ,[Sched_End] ,[Sched_Start] ,REPLACE (CONVERT(VARCHAR(MAX), Note_Text),CHAR(13)+CHAR(10),' ') ,[Released_Date] ,[User_Values] FROM [PRODUCTION].[dbo].[Job] WHERE Job in <%= jobs_to_export %> ORDER BY Job DESC" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1 \n\n<%= prev_command %>
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
    GeneralCsvFunctions.process_csv(Path.join([File.cwd!(), "csv_files/runlistops.csv"]), 9)
    GeneralCsvFunctions.process_csv(Path.join([File.cwd!(), "csv_files/jobs.csv"]), 20)
    GeneralCsvFunctions.process_csv(Path.join([File.cwd!(), "csv_files/material.csv"]), 6)
  end

  def export_active_jobs() do #FOR TESTING SMALL DATASETS
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

  def export_all_jobs() do #changes short term batch files to export from database based on last export time.
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

end
