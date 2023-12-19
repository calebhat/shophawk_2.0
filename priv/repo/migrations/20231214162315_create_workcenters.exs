defmodule Shophawk.Repo.Migrations.CreateWorkcenters do
  use Ecto.Migration

  def change do
    create table(:workcenters) do
      add :workcenter, :string

      timestamps()
    end
  end
end
