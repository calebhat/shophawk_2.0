defmodule Shophawk.Repo.Migrations.CreateStockedmaterials do
  use Ecto.Migration

  def change do
    create table(:stockedmaterials) do
      add :material, :string
      add :bar_length, :float
      add :original_bar_length, :float
      add :slug_length, :float
      add :number_of_slugs, :integer
      add :purchase_date, :date
      add :purchase_price, :float #$/lb
      add :vendor, :string
      add :being_quoted, :boolean, default: false
      add :ordered, :boolean, default: false
      add :in_house, :boolean, default: false
      add :bar_used, :boolean, default: false
      add :extra_bar_for_receiving, :boolean, null: true

      timestamps()
    end
  end
end
