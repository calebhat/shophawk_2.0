defmodule Shophawk.Jb_material_location do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "material_location" do
    field :material, :string
    field :on_hand_qty, :float
    field :location_id, :string
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:material, :on_hand_qty, :location_id])
    |> validate_required([:material, :on_hand_qty, :location_id])
  end
end
