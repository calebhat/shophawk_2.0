defmodule Shophawk.Jobboss_db do
    import Ecto.Query, warn: false
    alias DateTime
    alias Shophawk.Jb_employees
    alias Shophawk.Jb_holiday
    alias Shophawk.Jb_user_values
    alias Shophawk.Jb_attachment
    alias Shophawk.Jb_job_operation_time
    #alias Shophawk.Jb_InvoiceDetail
    #This file is used for all loading and ecto calls directly to the Jobboss Database.

    def sanitize_map(map) do #makes sure all values are in correct formats for the app.
      Enum.reduce(map, %{}, fn {key, value}, acc ->
        value =
          value
          |> convert_binary_to_string()
          |> convert_to_date()
        Map.put(acc, key, value)
      end)
    end

  def convert_binary_to_string(value) when is_binary(value) do
    case :unicode.characters_to_binary(value, :latin1, :utf8) do
      {:error, _, _} ->
        :unicode.characters_to_binary(value, :latin1, :utf8)
      string -> string
    end
  end
  def convert_binary_to_string(value), do: value

  def convert_to_date(%NaiveDateTime{} = value), do: NaiveDateTime.to_date(value)
  def convert_to_date(value), do: value

  def rename_key(map, old_key, new_key) do
    map
    |> Map.put(new_key, Map.get(map, old_key))  # Add the new key with the old key's value
    |> Map.delete(old_key)  # Remove the old key
  end

    #### Query Failsafes ####
  def failsafed_query(query, retries \\ 3, delay \\ 100) do #For jobboss db queries
    Process.sleep(delay)
    try do
      {:ok, result} = {:ok, Shophawk.Repo_jb.all(query)}
      result
    rescue
      _e in DBConnection.ConnectionError ->
        IO.puts("Database connection error. Retries left: #{retries}")
        handle_retry(query, retries, delay, :connection_error)
      e in Ecto.QueryError ->
        IO.puts("Query error: #{inspect(e)}. Retries left: #{retries}")
        handle_retry(query, retries, delay, :query_error)
      e ->
        IO.puts("Unexpected error: #{inspect(e)}. Retries left: #{retries}")
        handle_retry(query, retries, delay, :unexpected_error)
    end
  end

  def failsafed_query_one_result(query, retries \\ 3, delay \\ 100) do #For jobboss db queries
    Process.sleep(delay)
    try do
      {:ok, result} = {:ok, Shophawk.Repo_jb.one(query)}
      result
    rescue
      _e in DBConnection.ConnectionError ->
        IO.puts("Database connection error. Retries left: #{retries}")
        handle_retry(query, retries, delay, :connection_error)
      e in Ecto.QueryError ->
        IO.puts("Query error: #{inspect(e)}. Retries left: #{retries}")
        handle_retry(query, retries, delay, :query_error)
      e ->
        IO.puts("Unexpected error: #{inspect(e)}. Retries left: #{retries}")
        handle_retry(query, retries, delay, :unexpected_error)
    end
  end

  defp handle_retry(_query, 0, delay, reason) do #For jobboss db queries
    Process.sleep(delay)
    {:error, reason}
  end

  defp handle_retry(query, retries, delay, _reason) do #For jobboss db queries
    :timer.sleep(delay)
    failsafed_query(query, retries - 1, delay)
  end


  ### misc jobboss queries ###

  def load_employees do
    query =
      from r in Jb_employees,
      where: r.status == "Active",
      order_by: [asc: r.employee]

    Shophawk.Repo_jb.all(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.drop([:status]) end)
  end

  def employee_data do
    query =
      from r in Jb_employees,
      where: r.status == "Active",
      order_by: [asc: r.employee]

    employees = Shophawk.Repo_jb.all(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.drop([:status]) end)
    user_values = Enum.reduce(employees, [], fn emp, acc -> if emp.user_values != nil, do: [emp.user_values | acc], else: acc end)

    query =
      from r in Jb_user_values,
      where: r.user_values in ^user_values

    birthdays =
      Shophawk.Repo_jb.all(query)
      |> Enum.map(fn x -> Map.from_struct(x) |> Map.drop([:__meta__]) |> Map.drop([:text1]) |> sanitize_map() end)

    Enum.reduce(employees, [], fn %{user_values: user_values} = employee, acc ->
      found_birthday = Enum.find(birthdays, &(&1.user_values == user_values))
      if found_birthday do
        [Map.merge(employee, found_birthday) |> rename_key(:date1, :birthday) |> rename_key(:user_values, :user_value) | acc ]
      else
        acc
      end
    end)

  end

  def load_holidays do
    query =
      from r in Jb_holiday,
      where: r.shift == "668B4614-5E2B-418E-B156-2045FA0E8CDF"

    Shophawk.Repo_jb.all(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() |> Map.drop([:shift]) end)
    |> Enum.map(fn %{holidaystart: holidaystart, holidayend: holidayend} ->
      for date <- Date.range(holidaystart, holidayend) do
        date
      end
    end)
    |> List.flatten()
  end

  def export_attachments(job) do
    query =
      from r in Jb_attachment,
      where: r.owner_id == ^job

    Shophawk.Repo_jb.all(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> sanitize_map()
        |> rename_key(:attach_path, :path)
        |> rename_key(:owner_id, :job)
      end)
  end

  def load_job_operation_employee_time(job_operations) do
    query =
      from r in Jb_job_operation_time,
      where: r.job_operation in ^job_operations
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) end)
  end

end
