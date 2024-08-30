defmodule Shophawk.Dashboard.Monthlysales do
  use Ecto.Schema
  import Ecto.Changeset

  schema "monthly_sales" do
    field :date, :date
    field :amount, :float

    timestamps()
  end

  @doc false
  def changeset(dashboard, attrs) do
    dashboard
    |> cast(attrs, [:date, :amount])
    |> validate_required([:date, :amount])
  end
end
