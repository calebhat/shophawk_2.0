defmodule Shophawk.Jb_InvoiceDetail do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "invoice_detail" do
    field :document, :string
    field :job, :string
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:document, :job])
    |> validate_required([:document, :job])
  end
end
