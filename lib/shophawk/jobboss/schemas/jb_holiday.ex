defmodule Shophawk.Jb_holiday do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "holiday" do
    field :shift, :string
    field :holiday, :string
    field :holidayname, :string
    field :holidaystart, :naive_datetime
    field :holidayend, :naive_datetime

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:holiday, :holidayname, :holidaystart, :holidayend])
    |> validate_required([:holiday, :holidayname, :holidaystart, :holidayend])
  end
end
