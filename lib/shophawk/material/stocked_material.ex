defmodule Shophawk.Material.StockedMaterial do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stockedmaterials" do
    field :material, :string
    field :bar_length, :float
    field :slug_length, :float
    field :number_of_slugs, :integer
    field :purchase_date, :date
    field :purchase_price, :float #$/lb
    field :vendor, :string
    field :being_quoted, :boolean, default: false
    field :ordered, :boolean, default: false
    field :in_house, :boolean, default: false
    field :bar_used, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(stocked_material, attrs) do
    stocked_material
    |> cast(attrs, [:material, :bar_length, :slug_length, :number_of_slugs, :purchase_date, :purchase_price, :vendor, :being_quoted, :ordered, :in_house, :bar_used])
    |> validate_required([:material, :bar_length, :being_quoted, :ordered, :in_house, :bar_used])
  end

end
