defmodule Shophawk.Jb_Quote_operation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "quote_operation" do
    field :quote, :string
    field :quote_operation, :integer
    field :wc_vendor, :string
    field :inside_oper, :boolean
    field :operation_service, :string
    field :description, :string
    field :sequence, :integer
    field :run_labor_rate, :float
    field :note_text, :string
    field :run, :float
    field :run_method, :string
    field :est_setup_hrs, :float

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:quote, :quote_operation, :wc_vendor, :inside_oper, :operation_service, :description, :sequence, :run_labor_rate, :note_text, :run, :run_method, :est_setup_hrs])
    |> validate_required([:quote, :quote_operation, :wc_vendor, :inside_oper, :operation_service, :description, :sequence, :run_labor_rate, :note_text, :run, :run_method, :est_setup_hrs])
    #|> put_quoted_unit_price_float()
  end

end
