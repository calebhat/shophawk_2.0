defmodule Shophawk.Repo.Migrations.AddExtraBarForReceivingToStockedmaterials do
  use Ecto.Migration

  def change do
    alter table(:stockedmaterials) do
      add :extra_bar_for_receiving, :boolean, null: true
    end
  end
end
