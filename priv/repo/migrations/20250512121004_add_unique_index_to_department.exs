defmodule Shophawk.Repo.Migrations.AddUniqueIndexToDepartment do
  use Ecto.Migration

  def change do
    create unique_index(:departments, [:department])
  end
end
