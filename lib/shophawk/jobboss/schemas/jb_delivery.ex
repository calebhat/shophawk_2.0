defmodule Shophawk.Jb_delivery do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "delivery" do
    field :job, :string
    field :promised_date, :naive_datetime
    field :promised_quantity, :integer
    field :shipped_date, :naive_datetime
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :promised_date, :promised_quantity, :shipped_date])
    |> validate_required([:job, :promised_date, :promised_quantity])
  end
end