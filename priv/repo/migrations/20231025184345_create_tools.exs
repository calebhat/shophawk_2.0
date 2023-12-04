defmodule Shophawk.Repo.Migrations.CreateTools do
  use Ecto.Migration

  def change do
    create table(:tools) do
      add :part_number, :string
      add :description, :string
      add :balance, :integer
      add :minimum, :integer
      add :location, :string
      add :vendor, :string
      add :tool_info, :string
      add :number_of_checkouts, :integer
      add :status, :string
      add :department, :string

      timestamps()
    end

    create unique_index(:tools, [:part_number])
  end
end
