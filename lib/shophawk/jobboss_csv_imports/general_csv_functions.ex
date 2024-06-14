defmodule Shophawk.GeneralCsvFunctions do

  def initial_mapping(list) do
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
      [_job | _] -> true end)
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

  def normalize_row(row, expected_columns) do
    try do
      row
      |> String.split("`")
      |> Enum.map(&replace_null/1)
      |> validate_length(expected_columns)
    rescue
      _ ->
        nil # Return nil to signal that the row should be skipped
    end
  end

  def replace_null(value) do
    Regex.replace(~r/\bNULL\b/, value, "") #replaces exact matches of NULL with nothing. this leave /n (new lines) if null is the last value in the row.
  end

  def validate_length(values, expected_columns) do #checks length of rows coming in from CSV and kicks them out if they don't match
    if Enum.count(values) == expected_columns do
      values
    else
      raise "csv row is incorrect length"
    end
  end

end
