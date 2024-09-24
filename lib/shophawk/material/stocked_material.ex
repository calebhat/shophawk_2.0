defmodule Shophawk.Material.StockedMaterial do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stockedmaterials" do
    field :material, :string
    field :bars,  {:array, :float}, default: []
    field :slugs,  {:array, :float}, default: []

    timestamps()
  end

  @doc false
  def changeset(stocked_material, attrs) do

    stocked_material
    |> cast(attrs, [:material, :bars, :slugs])
    |> validate_required([:material, :bars, :slugs])
  end

end
