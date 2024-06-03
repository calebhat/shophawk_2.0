defmodule Shophawk.Shopinfo.Timeoff do
  use Ecto.Schema
  import Ecto.Changeset

  schema "timeoff" do
    field :employee, :string
    field :startdate, :naive_datetime
    field :enddate, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(timeoff, attrs) do
    timeoff
    |> cast(attrs, [:employee, :startdate, :enddate])
    |> validate_required([:employee, :startdate, :enddate])
    |> update_startdate_if_nil()
    |> update_enddate_if_nil()
  end

  defp update_startdate_if_nil(changeset) do
    case get_field(changeset, :startdate) do
      nil ->
        current_date = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
        {year, month, day} = {current_date.year, current_date.month, current_date.day}
        {:ok, morning} = NaiveDateTime.new(year, month, day, 7, 0, 0)
        put_change(changeset, :startdate, morning)
      _ -> changeset
    end
  end

  defp update_enddate_if_nil(changeset) do
    case get_field(changeset, :enddate) do
      nil ->
        current_date = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
        {year, month, day} = {current_date.year, current_date.month, current_date.day}
        {:ok, evening} = NaiveDateTime.new(year, month, day, 15, 0, 0)
        put_change(changeset, :enddate, evening)
      _ -> changeset
    end
  end

end
