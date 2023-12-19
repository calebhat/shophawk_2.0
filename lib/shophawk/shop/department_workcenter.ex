defmodule Shophawk.Shop.DepartmentWorkcenter do
  use Ecto.Schema

  schema "department_workcenters" do
    belongs_to :department, Shophawk.Shop.Department
    belongs_to :workcenter, Shophawk.Shop.Workcenter

    timestamps()
  end
end
