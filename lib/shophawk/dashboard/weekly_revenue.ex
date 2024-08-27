defmodule Shophawk.Dashboard.Weeklyrevenue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weekly_revenue" do
    field :total_revenue, :float
    field :six_week_revenue, :float
    field :total_jobs, :integer

    timestamps()
  end

  @doc false
  def changeset(dashboard, attrs) do
    dashboard
    |> cast(attrs, [:total_revenue, :six_week_revenue, :total_jobs])
    |> validate_required([:total_revenue, :six_week_revenue, :total_jobs])
  end
end
