sqlcmd -S GEARSERVER\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Owner_ID] ,[Attach_Path] ,[Description] FROM [PRODUCTION].[dbo].[Attachment] WHERE Owner_ID = '135429'" -o "c:/phoenixapps/shophawkdev/csv_files/attachments.csv" -W -w 1024 -s "`" -f 65001 -h -1
