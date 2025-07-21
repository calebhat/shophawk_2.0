defmodule Shophawk.Dashboard.InvoiceComments do
  use Ecto.Schema
  import Ecto.Changeset

  schema "invoice_comments" do
    field :invoice, :string
    field :comment, :string

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:invoice, :comment])
    |> validate_required([:invoice, :comment])
  end
end
