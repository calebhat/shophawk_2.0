defmodule Shophawk.Jb_material_req do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "material_req" do
    field :job, :string
    field :material, :string
    field :vendor, :string
    field :description, :string
    field :pick_buy_indicator, :string
    field :status, :string
    field :last_updated, :naive_datetime
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :material, :vendor, :description, :pick_buy_indicator, :status, :last_updated])
    |> validate_required([:job, :material])
  end
end
