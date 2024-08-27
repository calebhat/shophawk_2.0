defmodule Shophawk.Repo.Migrations.CreateMonthlySales do
  use Ecto.Migration

  def change do
    create table(:monthly_sales) do
      add :date, :naive_datetime
      add :amount, :float

      timestamps()
    end
  end
end
