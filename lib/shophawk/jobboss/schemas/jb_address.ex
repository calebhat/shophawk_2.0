defmodule Shophawk.Jb_address do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "address" do
    field :address, :integer
    field :name, :string
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:address, :name])
    |> validate_required([:address, :name])
  end
end
