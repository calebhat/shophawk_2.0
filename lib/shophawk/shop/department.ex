defmodule Shophawk.Shop.Department do
  use Ecto.Schema
  import Ecto.Changeset

  schema "departments" do
    field :department, :string
    field :capacity, :float
    field :machine_count, :float
    field :show_jobs_started, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:department, :capacity, :machine_count, :show_jobs_started])
    |> validate_required([:department, :capacity, :machine_count, :show_jobs_started])
  end
end
