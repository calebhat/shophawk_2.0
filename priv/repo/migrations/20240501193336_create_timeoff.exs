defmodule Shophawk.Repo.Migrations.CreateTimeoff do
  use Ecto.Migration

  def change do
    create table(:timeoff) do
      add :employee, :string
      add :startdate, :naive_datetime
      add :enddate, :naive_datetime

      timestamps()
    end
  end
end
