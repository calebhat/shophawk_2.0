defmodule Shophawk.Jb_Ap_Check do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "ap_check" do
    field :vendor, :string
    field :check_date, :naive_datetime
    field :check_amt, :float

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:vendor, :check_date, :check_amt])
    |> validate_required([:vendor, :check_date, :check_amt])
  end
end
