sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job_Operation] ,[Employee] ,[Work_Date] ,[Act_Setup_Hrs] ,[Act_Run_Hrs] ,[Act_Run_Qty] ,[Act_Scrap_Qty] ,[Note_Text] FROM [PRODUCTION].[dbo].[Job_Operation_Time] WHERE Last_Updated > DATEADD(MILLISECOND, -8356,GETDATE()) ORDER BY Job_Operation DESC" -o "c:/phoenixapps/shophawk/csv_files/operationtime.csv" -W -w 1024 -s "`" -f 65001 -h -1 
sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Last_Updated > DATEADD(MILLISECOND, -8356,GETDATE())" -o "c:/phoenixapps/shophawk/csv_files/material.csv" -W -w 1024 -s "`" -f 65001 -h -1 
sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job] WHERE Last_Updated > DATEADD(MILLISECOND, -8356,GETDATE())" -o "c:/phoenixapps/shophawk/csv_files/jobs.csv" -W -w 1024 -s "`" -f 65001 -h -1 
sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Last_Updated > DATEADD(MILLISECOND,-8356,GETDATE())" -o "c:/phoenixapps/shophawk/csv_files/runlistops.csv" -W -w 1024 -s "`" -f 65001 -h -1




