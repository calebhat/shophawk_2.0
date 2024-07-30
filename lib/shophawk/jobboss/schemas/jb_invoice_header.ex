defmodule Shophawk.Jb_InvoiceHeader do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "invoice_header" do
    field :document, :integer
    field :customer, :string
    field :ship_via, :string
    field :terms, :string
    field :document_date, :naive_datetime
    field :due_date, :naive_datetime
    field :orig_invoice_amount, :float
    field :open_invoice_amount, :float
    field :last_updated, :naive_datetime
    field :invoiced_by, :string
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:document, :customer, :ship_via, :terms, :reference, :document_date, :due_date, :orig_invoice_amount, :open_invoice_amount, :last_updated, :invoiced_by])
    |> validate_required([:document, :customer, :ship_via, :terms, :reference, :document_date, :due_date, :orig_invoice_amount, :open_invoice_amount, :last_updated, :invoiced_by])
  end
end
