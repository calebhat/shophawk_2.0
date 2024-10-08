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
    field :saved, :boolean, default: true, virtual: true
    field :enough_bar_for_job, :boolean, default: true, virtual: true
    field :job_assignments, {:array, :map}, default: [], virtual: true

    timestamps()
  end

  @doc false
  def changeset(stocked_material, attrs) do
    stocked_material
    |> cast(attrs, [:material, :bar_length, :slug_length, :number_of_slugs, :purchase_date, :purchase_price, :vendor, :being_quoted, :ordered, :in_house, :bar_used])
    |> validate_required([:material, :being_quoted, :ordered, :in_house, :bar_used])
    |> round_floats()
  end

  # Custom function to round float fields to 2 decimal places
  defp round_floats(changeset) do
    changeset
    |> round_field(:bar_length)
    |> round_field(:slug_length)
  end

  # Rounds a field's value and puts it back into the changeset
  defp round_field(changeset, field) do
    # Use `get_field/3` to get the field value, whether changed or not
    value = get_field(changeset, field)

    if is_float(value) do
      # Put the rounded value back into the changeset
      put_change(changeset, field, Float.round(value, 2))
    else
      changeset
    end
  end

end
