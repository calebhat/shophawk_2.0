defmodule Shophawk.Jb_customer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "customer" do
    field :customer, :string
    field :status, :string
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:customer, :status])
    |> validate_required([:customer, :status])
  end
end
