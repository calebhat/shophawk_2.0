defmodule Shophawk.Repo.Migrations.CreateRevenue do
  use Ecto.Migration

  def change do
    create table(:revenue) do
      add :total_revenue, :float
      add :six_week_revenue, :float
      add :total_jobs, :integer
      add :week, :date

      timestamps()
    end
  end
end
