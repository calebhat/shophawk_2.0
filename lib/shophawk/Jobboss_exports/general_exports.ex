defmodule Shophawk.GeneralExports do
  alias Shophawk.GeneralCsvFunctions
#used in to export needed data for slideshow
  def export_employees do
    path = Path.join([File.cwd!(), "csv_files/employees.csv"])
    export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Employee] ,[User_Values] ,[First_Name] ,[Last_Name] ,[Hire_Date] FROM [PRODUCTION].[dbo].[Employee] WHERE Status = 'Active'" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1
    """
    sql_export = EEx.eval_string(export, [path: path])
    File.write!(Path.join([File.cwd!(), "batch_files/load_employees.bat"]), sql_export)
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/load_employees.bat"])])
    employees =
      File.stream!(Path.join([File.cwd!(), "csv_files/employees.csv"]))
      |> GeneralCsvFunctions.initial_mapping
      |> Enum.reduce( [],
        fn
        [
          employee,
          user_value,
          first_name,
          last_name,
          hire_date| _], acc ->
            new_map =
              %{employee: employee,
              user_value: (if user_value == "NULL", do: "", else: user_value),
              first_name: first_name,
              last_name: last_name,
              hire_date: Date.from_iso8601!(String.slice(hire_date, 0..9))
              }
          [new_map | acc]  end)
    user_values_to_export =
      employees
      |> Enum.map(&Map.get(&1, :user_value))
      |> Enum.reject(&(&1 == nil or &1 == "")) # Filter out nil values
      |> case do
        [] -> false  # Handle the case where all user values are nil
        user_values -> "(" <> Enum.join(user_values, ", ") <> ")"
      end
      sql_export =
        if user_values_to_export != [] do
          #user values
          path = Path.join([File.cwd!(), "csv_files/employees.csv"])
          export = """
          sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [User_Values] ,[Date1] FROM [PRODUCTION].[dbo].[User_Values] WHERE Text1 IS NOT NULL AND User_Values in <%= user_values_to_export %>" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1
          """
          EEx.eval_string(export, [user_values_to_export: user_values_to_export, path: path])
        end
      if sql_export do
        File.write!(Path.join([File.cwd!(), "batch_files/load_employees.bat"]), sql_export)
        System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/load_employees.bat"])])
        birthdays_list =
          File.stream!(Path.join([File.cwd!(), "csv_files/employees.csv"]))
          |> GeneralCsvFunctions.initial_mapping()
          |> Enum.reduce( [], fn [user_value, birthday | _], acc ->
            new_map = %{user_value: user_value, birthday: Date.from_iso8601!(String.slice(birthday, 0..9))}
            [new_map | acc]
          end)
        if birthdays_list != [] do #csv could be empty if no matching user values found
          Enum.map(employees, fn %{user_value: user_value} = employee ->
            found_birthday = Enum.find(birthdays_list, &(&1.user_value == user_value))
            if found_birthday do
              Map.merge(employee, found_birthday)
            end
          end)
        else
          employees
        end
        |> Enum.filter(fn item -> is_map(item) end)
      end
  end

  def export_attachments(job) do
    path = Path.join([File.cwd!(), "csv_files/attachments.csv"])
    sql_export = """
    sqlcmd -S GEARSERVER\\SQLEXPRESS -d PRODUCTION -E -Q "SELECT [Owner_ID] ,[Attach_Path] ,[Description] FROM [PRODUCTION].[dbo].[Attachment] WHERE Owner_ID = '<%= job %>'" -o "<%= path %>" -W -w 1024 -s "`" -f 65001 -h -1
    """
    export = EEx.eval_string(sql_export, [job: job, path: path])
    File.write!(Path.join([File.cwd!(), "batch_files/job_attachments.bat"]), export)
    System.cmd("cmd", ["/C", Path.join([File.cwd!(), "batch_files/job_attachments.bat"])])

    File.stream!(Path.join([File.cwd!(), "csv_files/attachments.csv"]))
    |> GeneralCsvFunctions.initial_mapping()
    |> Enum.reduce( [], fn [job, path, description | _], acc ->
      new_map = %{job: job, path: path, description: description}
      [new_map | acc]
    end)
  end
end
