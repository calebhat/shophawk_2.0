defmodule Shophawk.Shopinfo do
  @moduledoc """
  The Shopinfo context.
  """

  import Ecto.Query, warn: false
  alias Shophawk.Repo

  alias Shophawk.Shopinfo.Slideshow

  @doc """
  Returns the list of slideshow.

  ## Examples

      iex> list_slideshow()
      [%Slideshow{}, ...]

  """
  def list_slideshow do
    Repo.all(Slideshow)
  end

  @doc """
  Gets a single slideshow.

  Raises `Ecto.NoResultsError` if the Slideshow does not exist.

  ## Examples

      iex> get_slideshow!(123)
      %Slideshow{}

      iex> get_slideshow!(456)
      ** (Ecto.NoResultsError)

  """
  def get_slideshow!(id), do: Repo.get!(Slideshow, id)

  @doc """
  Creates a slideshow.

  ## Examples

      iex> create_slideshow(%{field: value})
      {:ok, %Slideshow{}}

      iex> create_slideshow(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_slideshow(attrs \\ %{}) do
    %Slideshow{}
    |> Slideshow.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a slideshow.

  ## Examples

      iex> update_slideshow(slideshow, %{field: new_value})
      {:ok, %Slideshow{}}

      iex> update_slideshow(slideshow, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_slideshow(%Slideshow{} = slideshow, attrs) do
    slideshow
    |> Slideshow.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a slideshow.

  ## Examples

      iex> delete_slideshow(slideshow)
      {:ok, %Slideshow{}}

      iex> delete_slideshow(slideshow)
      {:error, %Ecto.Changeset{}}

  """
  def delete_slideshow(%Slideshow{} = slideshow) do
    Repo.delete(slideshow)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking slideshow changes.

  ## Examples

      iex> change_slideshow(slideshow)
      %Ecto.Changeset{data: %Slideshow{}}

  """
  def change_slideshow(%Slideshow{} = slideshow, attrs \\ %{}) do
    Slideshow.changeset(slideshow, attrs)
  end

  alias Shophawk.Shopinfo.Timeoff

  @doc """
  Returns the list of timeoff.

  ## Examples

      iex> list_timeoff()
      [%Timeoff{}, ...]

  """
  def list_timeoff do
    Repo.all(Timeoff)
  end

  def search_timeoff(search_term, start_date, end_date) do
    start_date = parse_date(start_date) |> NaiveDateTime.add(-30, :day)
    end_date = parse_date(end_date)
    end_date =
      if end_date == "" do
        {:ok, datetime} = DateTime.now("Etc/UTC")
        DateTime.add(datetime, 365, :day)
      else
        NaiveDateTime.add(end_date, 30, :day)
      end
    query =
      Timeoff
      |> where([t], ilike(t.employee, ^"%#{search_term}%"))
      |> where([t], t.startdate >= ^start_date)
      |> where([t], t.enddate <= ^end_date)

    Repo.all(query)
    |> Enum.sort_by(&{&1.employee, &1.startdate}, fn
      {employee1, date1}, {employee2, date2} ->
        case employee1 do
          employee1 when employee1 < employee2 -> true
          employee1 when employee1 > employee2 -> false
          _ ->
            case NaiveDateTime.compare(date1, date2) do
              :lt -> true
              :eq -> true
              :gt -> false
            end
        end
    end)
  end

  defp parse_date(""), do: ""
  defp parse_date(%Date{} = date) do
    {:ok, naive_date} = NaiveDateTime.new(date.year, date.month, date.day, 0, 0, 0)
    naive_date
  end
  defp parse_date(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} ->
        {:ok, naive_date} = NaiveDateTime.new(date.year, date.month, date.day, 0, 0, 0)
        naive_date
      _ -> ""
    end
  end

  @doc """
  Gets a single timeoff.

  Raises `Ecto.NoResultsError` if the Timeoff does not exist.

  ## Examples

      iex> get_timeoff!(123)
      %Timeoff{}

      iex> get_timeoff!(456)
      ** (Ecto.NoResultsError)

  """
  def get_timeoff!(id), do: Repo.get!(Timeoff, id)

  @doc """
  Creates a timeoff.

  ## Examples

      iex> create_timeoff(%{field: value})
      {:ok, %Timeoff{}}

      iex> create_timeoff(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_timeoff(attrs \\ %{}) do
    %Timeoff{}
    |> Timeoff.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a timeoff.

  ## Examples

      iex> update_timeoff(timeoff, %{field: new_value})
      {:ok, %Timeoff{}}

      iex> update_timeoff(timeoff, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_timeoff(%Timeoff{} = timeoff, attrs) do
    timeoff
    |> Timeoff.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a timeoff.

  ## Examples

      iex> delete_timeoff(timeoff)
      {:ok, %Timeoff{}}

      iex> delete_timeoff(timeoff)
      {:error, %Ecto.Changeset{}}

  """
  def delete_timeoff(%Timeoff{} = timeoff) do
    Repo.delete(timeoff)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking timeoff changes.

  ## Examples

      iex> change_timeoff(timeoff)
      %Ecto.Changeset{data: %Timeoff{}}

  """
  def change_timeoff(%Timeoff{} = timeoff, attrs \\ %{}) do
    Timeoff.changeset(timeoff, attrs)
  end
end
