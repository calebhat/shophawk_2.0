defmodule Shophawk.Repo.Migrations.CreateInvoiceComments do
  use Ecto.Migration

  def change do
    create table(:invoice_comments) do
      add :invoice, :string
      add :comment, :string

      timestamps()
    end
  end
end
