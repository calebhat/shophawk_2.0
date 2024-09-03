defmodule Shophawk.Jb_job_delivery do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "job" do
    field :job, :string
    field :status, :string
    field :total_price, :float
    field :unit_price, :float
    field :order_date, :naive_datetime
    field :customer, :string
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :status, :total_price, :unit_price, :order_date, :customer])
    |> validate_required([:job, :status, :total_price, :unit_price, :order_date, :customer])
  end
end
