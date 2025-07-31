defmodule Shophawk.Jb_RFQ do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "rfq" do
    field :rfq, :string
    field :customer, :string
    field :quote_date, :naive_datetime

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:rfq, :customer, :quote_date])
    |> validate_required([:rfq, :customer])
  end
end
