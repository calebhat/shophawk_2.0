defmodule Shophawk.Repo.Migrations.CreateDepartments do
  use Ecto.Migration

  def change do
    create table(:departments) do
      add :department, :string
      add :capacity, :float
      add :machine_count, :float
      add :show_jobs_started, :boolean, default: false, null: false

      timestamps()
    end
  end
end
