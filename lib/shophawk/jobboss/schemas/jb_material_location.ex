defmodule Shophawk.Jb_material_location do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

    schema "Material_Location" do
    field :location_id, :string, primary_key: true
    field :material, :string, primary_key: true
    field :on_hand_qty, :float
  end

  @doc false
  def changeset(record, attrs) do
    record
    |> cast(attrs, [:location_id, :material, :on_hand_qty])
    |> validate_required([:location_id, :material, :on_hand_qty])
  end
end
