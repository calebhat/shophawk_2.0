defmodule Shophawk.Jb_material do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "material" do
    field :material, :string
    field :primary_vendor, :string
    field :shape, :string
    field :location_id, :string
    field :description, :string
    field :stocked_uofm, :string
    field :selling_price, :float
    field :pick_buy_indicator, :string
    field :status, :string
    field :is_weight_factor, :float
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:material, :primary_vendor, :shape, :location_id, :description, :stocked_uofm, :selling_price, :pick_buy_indicator, :status, :is_weight_factor])
    |> validate_required([:material, :primary_vendor, :shape, :location_id, :description, :stocked_uofm, :selling_price, :pick_buy_indicator, :status, :is_weight_factor])
  end
end
