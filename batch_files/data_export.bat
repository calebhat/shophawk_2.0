sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Material_Req] WHERE Last_Updated > DATEADD(SECOND, -5743 / 1000,GETDATE())" -o "c:/phoenixapps/shophawk/csv_files/material.csv" -W -w 1024 -s "`" -f 65001 -h -1 
sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job] WHERE Last_Updated > DATEADD(SECOND, -5743 / 1000,GETDATE())" -o "c:/phoenixapps/shophawk/csv_files/jobs.csv" -W -w 1024 -s "`" -f 65001 -h -1 
sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Job] FROM [PRODUCTION].[dbo].[Job_Operation] WHERE Last_Updated > DATEADD(SECOND,-5743 / 1000,GETDATE())" -o "c:/phoenixapps/shophawk/csv_files/runlistops.csv" -W -w 1024 -s "`" -f 65001 -h -1



