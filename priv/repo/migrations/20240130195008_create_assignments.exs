defmodule Shophawk.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :assignment, :string
      add :department_id, references(:departments, on_delete: :delete_all)

      timestamps()
    end
  end
end
