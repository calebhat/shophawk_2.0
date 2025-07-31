defmodule Shophawk.Jb_Quote_req do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "quote_req" do
    field :quote_req, :integer
    field :quote, :string
    field :material, :string
    field :pick_buy_indicator, :string
    field :uofm, :string
    field :cost_uofm, :string
    field :est_unit_cost, :float
    field :part_length, :float
    field :cutoff, :float
    field :note_text, :string
    field :cost_unit_conv, :float
    field :quantity_per, :float


    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:quote_req, :quote, :material, :pick_buy_indicator, :uofm, :costuofm, :est_unit_cost, :part_length, :cutoff, :note_text, :cost_unit_conv, :quantity_per])
    |> validate_required([:quote_req, :quote, :material, :pick_buy_indicator, :uofm, :costuofm, :est_unit_cost, :part_length, :cutoff, :note_text, :cost_unit_conv, :quantity_per])
  end
end
