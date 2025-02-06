defmodule Shophawk.Jb_employees do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "employee" do
    field :employee, :string
    field :user_values, :integer, default: 0
    field :first_name, :string
    field :last_name, :string
    field :status, :string
    field :department, :string
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:employee, :user_values, :user_values, :first_name, :last_name, :status, :department])
    |> validate_required([:employee, :first_name])
  end
end
