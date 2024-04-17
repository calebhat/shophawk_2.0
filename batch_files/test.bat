sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Job_Operation] ,[WC_Vendor] ,[Operation_Service] ,[Vendor] ,[Sched_Start] ,[Sched_End] ,[Sequence], [Status] ,[Est_Total_Hrs] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Job in ('133120') ORDER BY Job_Operation ASC" -o "c:/phoenixapps/shophawk/csv_files/test.csv" -W -w 1024 -s "`" -f 65001 -h -1

