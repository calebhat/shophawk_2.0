defmodule Shophawk.Material.StockedMaterial do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stockedmaterials" do
    field :material, :string
    field :bar_length, :float
    field :original_bar_length, :float
    field :slug_length, :float
    field :number_of_slugs, :integer
    field :purchase_date, :date
    field :purchase_price, :float #$/lb
    field :vendor, :string
    field :being_quoted, :boolean, default: false
    field :ordered, :boolean, default: false
    field :in_house, :boolean, default: false
    field :bar_used, :boolean, default: false
    field :extra_bar_for_receiving, :boolean, default: false
    field :location, :string

    field :saved, :boolean, default: true, virtual: true
    #field :enough_bar_for_job, :boolean, default: true, virtual: true
    field :job_assignments, {:array, :map}, default: [], virtual: true
    field :remaining_length_not_assigned, :float, default: 0.0, virtual: true
    field :status, :string, virtual: true


    timestamps()
  end

  @doc false
  def changeset(stocked_material, attrs) do
    stocked_material
    |> cast(attrs, [:material, :bar_length, :original_bar_length, :slug_length, :number_of_slugs, :purchase_date, :purchase_price, :vendor, :being_quoted, :ordered, :in_house, :bar_used, :remaining_length_not_assigned, :extra_bar_for_receiving, :location])
    |> validate_required([:material, :being_quoted, :ordered, :in_house, :bar_used])
    |> validate_number(:purchase_price, greater_than_or_equal_to: 0, message: "Must be positive")
    |> validate_number(:original_bar_length, greater_than_or_equal_to: 0, message: "Must be positive")
    |> validate_number(:bar_length, greater_than_or_equal_to: 0, message: "Must be positive")
    |> round_floats()
  end

  #includes extra validations
  @spec material_waiting_on_quote_changeset(
          {map(), map()}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()

  def material_waiting_on_quote_changeset(stocked_material, attrs) do
    stocked_material
    |> cast(attrs, [:material, :bar_length, :slug_length, :number_of_slugs, :purchase_date, :purchase_price, :vendor, :being_quoted, :ordered, :in_house, :bar_used, :remaining_length_not_assigned, :extra_bar_for_receiving, :location])
    |> validate_required([:material, :being_quoted, :ordered, :in_house, :bar_used, :vendor, :purchase_price])
    |> validate_number(:purchase_price, greater_than_or_equal_to: 0, message: "Must be positive")
    |> round_floats()
  end

  def changeset_material_receiving(stocked_material, attrs) do
    stocked_material
    |> cast(attrs, [:material, :bar_length, :original_bar_length, :slug_length, :number_of_slugs, :purchase_date, :purchase_price, :vendor, :being_quoted, :ordered, :in_house, :bar_used, :remaining_length_not_assigned, :extra_bar_for_receiving, :location])
    |> validate_required([:material, :being_quoted, :ordered, :in_house, :bar_used, :purchase_price, :vendor])
    |> validate_number(:bar_length, greater_than_or_equal_to: 0, message: "Must be positive")
    |> validate_at_least_one_length(:bar_length, :original_bar_length)
    |> round_floats()
  end

  # Custom validation to ensure at least one of bar_length or original_bar_length is non-empty
  defp validate_at_least_one_length(changeset, field1, field2) do
    bar_length = get_field(changeset, field1)
    original_bar_length = get_field(changeset, field2)

    cond do
      is_nil(bar_length) and is_nil(original_bar_length) ->
        # Both are nil (or empty after casting)
        add_error(changeset, :bar_length, "Enter Bar Length")
        |> add_error(:original_bar_length, "Enter Bar Length")

      bar_length == 0.0 and original_bar_length == 0.0 ->
        # Both are zero (possibly from empty strings cast to floats)
        add_error(changeset, :bar_length, "Enter Bar Length")
        |> add_error(:original_bar_length, "Enter Bar Length")

      true ->
        # At least one is non-nil and non-zero
        changeset
    end
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
