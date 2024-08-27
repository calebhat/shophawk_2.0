defmodule Shophawk.Dashboard.Revenue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "revenue" do
    field :total_revenue, :float
    field :six_week_revenue, :float
    field :total_jobs, :integer
    field :week, :date

    timestamps()
  end

  @doc false
  def changeset(dashboard, attrs) do
    dashboard
    |> cast(attrs, [:total_revenue, :six_week_revenue, :total_jobs, :week])
    |> validate_required([:total_revenue, :six_week_revenue, :total_jobs, :week])
  end
end
