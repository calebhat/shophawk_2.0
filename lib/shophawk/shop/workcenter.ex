defmodule Shophawk.Shop.Workcenter do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workcenters" do
    field :workcenter, :string
    many_to_many :departments, Shophawk.Shop.Department, join_through: Shophawk.Shop.DepartmentWorkcenter

    timestamps()
  end

  def changeset(workcenter, attrs) do
    workcenter
    |> cast(attrs, [:workcenter])
    |> validate_required([:workcenter])
  end
end
