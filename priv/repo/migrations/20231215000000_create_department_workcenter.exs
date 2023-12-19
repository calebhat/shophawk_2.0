defmodule Shophawk.Repo.Migrations.CreateDepartmentWorkcenter do
  use Ecto.Migration

  def change do
    create table(:department_workcenter) do
      add :department_id, references(:departments, on_delete: :delete_all)
      add :workcenter_id, references(:workcenters, on_delete: :delete_all)

      timestamps()

    end
    create unique_index(:department_workcenter, [:department_id, :workcenter_id])
  end
end
