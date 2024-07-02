defmodule Shophawk.Jb_user_values do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "user_values" do
    field :user_values, :integer
    field :text1, :string
    field :date1, :naive_datetime
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:user_values, :text1, :date1])
    |> validate_required([:user_values])
  end
end
