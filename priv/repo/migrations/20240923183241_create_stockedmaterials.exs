defmodule Shophawk.Repo.Migrations.CreateStockedmaterials do
  use Ecto.Migration

  def change do
    create table(:stockedmaterials) do
      add :material, :string
      add :bars, {:array, :float}, default: []
      add :slugs, {:array, :float}, default: []

      timestamps()
    end
  end
end
