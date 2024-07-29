defmodule Shophawk.Inventory.Tool do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tools" do
    field :status, :string
    field :description, :string
    field :location, :string
    field :balance, :integer, default: 0
    field :part_number, :string
    field :minimum, :integer, default: 0
    field :vendor, :string
    field :tool_info, :string
    field :number_of_checkouts, :integer, default: 0
    field :department, :string

    field :checkout_amount, :integer, virtual: true, default: 0
    field :original_balance, :integer, virtual: true
    field :negative_checkout_message, :string, virtual: true, default: ""

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:part_number, :description, :balance, :minimum, :location, :vendor, :tool_info, :number_of_checkouts, :status, :department, :checkout_amount, :original_balance, :negative_checkout_message])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
    |> validate_number(:minimum, greater_than_or_equal_to: 0)
    |> validate_number(:number_of_checkouts, greater_than_or_equal_to: 0)
    |> checkout_amount_message() #used to send custom message if number is negative
    |> validate_required([:part_number, :description, :balance, :minimum, :location, :vendor, :tool_info, :number_of_checkouts, :status])
    |> unique_constraint(:part_number)
    |> set_status()
    |> clear_amount_to_be_checked_out()
  end

  defp checkout_amount_message(changeset) do
    case get_change(changeset, :checkout_amount) do
      nil -> changeset
      checkout_amount when checkout_amount >= 0 -> changeset
      _ ->
        put_change(changeset, :negative_checkout_message, "Using a negative number will ADD to the balance")
        #add_error(changeset, :checkout_amount, "Using a negative number will add to the balance")
    end
  end

  defp clear_amount_to_be_checked_out(changeset) do
    checkout_amount = get_field(changeset, :checkout_amount)
    if checkout_amount == 0 do
      put_change(changeset, :checkout_amount, "")
    else
      changeset
    end
  end

  defp set_status(changeset) do
    if get_field(changeset, :balance) >= get_field(changeset, :minimum) do
      put_change(changeset, :status, "stocked")
    else
      put_change(changeset, :status, "needs restock")
    end
  end

end
