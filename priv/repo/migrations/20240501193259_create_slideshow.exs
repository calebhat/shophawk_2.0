defmodule Shophawk.Repo.Migrations.CreateSlideshow do
  use Ecto.Migration

  def change do
    create table(:slideshow) do
      add :workhours, :string
      add :announcement1, :string
      add :announcement2, :string
      add :announcement3, :string
      add :quote, :string
      add :photo, :string

      timestamps()
    end
  end
end
