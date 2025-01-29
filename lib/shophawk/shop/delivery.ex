defmodule Shophawk.Shop.Delivery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "deliveries" do
    field :delivery, :string, default: nil
    field :job, :string
    field :packaged, :boolean
    field :user_comment, :string
    field :promised_date, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:delivery, :job, :packaged, :user_comment, :promised_date])
    |> validate_required([:delivery, :job, :promised_date])
  end
end
