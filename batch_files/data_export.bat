sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,REPLACE (CONVERT(VARCHAR(MAX), Material),'`','') ,[Vendor] ,[Description] ,[Pick_Buy_Indicator] ,[Status] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Job in ('134389') ORDER BY Job DESC" -o "c:/phoenixapps/shophawk/csv_files/material.csv" -W -w 1024 -s "`" -f 65001 -h -1 

sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Customer] ,[Order_Date] ,[Part_Number], [Status] ,[Rev] ,[Description] ,[Order_Quantity] ,[Extra_Quantity] ,[Pick_Quantity] ,[Make_Quantity] ,[Open_Operations] ,[Completed_Quantity] ,[Shipped_Quantity] ,[Customer_PO] ,[Customer_PO_LN] ,[Sched_End] ,[Sched_Start] ,REPLACE (CONVERT(VARCHAR(MAX), Note_Text),CHAR(13)+CHAR(10),' ') ,[Released_Date] ,[User_Values] FROM [PRODUCTION].[dbo].[Job] WHERE Job in ('134389') ORDER BY Job DESC" -o "c:/phoenixapps/shophawk/csv_files/jobs.csv" -W -w 1024 -s "`" -f 65001 -h -1 

sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] ,[Job_Operation] ,[WC_Vendor] ,REPLACE (CONVERT(VARCHAR(MAX), Operation_Service),'`','') ,[Vendor] ,[Sched_Start] ,[Sched_End] ,[Sequence], [Status] ,[Est_Total_Hrs] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Job in ('134389') ORDER BY Job, COALESCE(Sched_Start, '9999-12-31') ASC, Job_Operation ASC" -o "c:/phoenixapps/shophawk/csv_files/runlistops.csv" -W -w 1024 -s "`" -f 65001 -h -1




