defmodule Shophawk.Jb_material do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "material_req" do
    field :job, :string
    field :material, :string
    field :vendor, :string
    field :description, :string
    field :pick_buy_indicator, :string
    field :status, :string
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :material, :vendor, :description, :pick_buy_indicator, :status])
    |> validate_required([:job, :material])
  end
end
