defmodule Shophawk.Jb_material do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "material" do
    field :job, :string
    field :material, :integer
    field :vendor, :string
    field :description, :string
    field :pick_buy_indicator, :string
    field :status, :string
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :material])
    |> validate_required([:job, :material])
  end
end
