defmodule Shophawk.Jb_Quote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "quote" do
    field :rfq, :string
    field :quote, :string
    field :part_number, :string
    field :rev, :string
    field :quoted_by, :string
    field :description, :string
    field :ext_description, :string
    field :comment, :string
    field :line, :string
    field :status_date, :naive_datetime

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:rfq, :quote, :part_number, :quoted_by, :description, :ext_description, :comment, :line, :status_date])
    |> validate_required([:rfq, :quote, :part_number, :quoted_by, :description, :ext_description, :comment, :line, :status_date])
  end
end
