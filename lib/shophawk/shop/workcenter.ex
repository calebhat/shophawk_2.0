defmodule Shophawk.Shop.Workcenter do
  use Ecto.Schema

  schema "workcenters" do
    field :workcenter, :string

    has_many :department_workcenters, Shophawk.Shop.DepartmentWorkcenter
    has_many :departments, through: [:department_workcenters, :department]


    timestamps()
  end
end
