defmodule Shophawk.Shop.Delivery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "deliveries" do
    field :delivery, :string
    field :job, :string
    field :packaged, :boolean
    field :user_comment, :string

    timestamps()
  end

  @doc false
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:delivery, :job, :packaged, :user_comment])
    |> validate_required([:delivery])
  end
end
