defmodule Shophawk.Shop.Department do
  use Ecto.Schema
  import Ecto.Changeset

  schema "departments" do
    field :department, :string
    field :capacity, :float
    field :machine_count, :float
    field :show_jobs_started, :boolean, default: false

    #has_many :department_workcenters, Shophawk.Shop.DepartmentWorkcenter
    many_to_many :workcenters, Shophawk.Shop.Workcenter, join_through: Shophawk.Shop.DepartmentWorkcenter, on_replace: :delete
    has_many :assignments, Shophawk.Shop.Assignment


    timestamps()
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:department, :capacity, :machine_count, :show_jobs_started])
    |> validate_required([:department, :capacity, :machine_count])
    |> unique_constraint(:department, message: "A department with this name already exists")

  end
end
