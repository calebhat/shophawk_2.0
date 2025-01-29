defmodule Shophawk.Repo.Migrations.CreateDeliveries do
  use Ecto.Migration

  def change do
    create table(:deliveries) do
      add :delivery, :string
      add :job, :string
      add :packaged, :boolean
      add :user_comment, :string
      add :promised_date, :naive_datetime

      timestamps()
    end
  end
end
