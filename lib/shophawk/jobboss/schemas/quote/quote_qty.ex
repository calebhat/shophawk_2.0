defmodule Shophawk.Jb_Quote_qty do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "quote_qty" do
    field :quote, :string
    field :quote_qty, :integer
    field :quoted_unit_price, :decimal
    field :quoted_unit_price_float, :float, virtual: true # Virtual field for float
    field :total_price, :float
    field :labor_markup_pct, :float
    field :mat_markup_pct, :float
    field :serv_markup_pct, :float
    field :quote_qty_key, :integer

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:quote, :quote_qty, :quoted_unit_price, :total_price, :labor_markup_pct, :mat_markup_pct, :serv_markup_pct, :quote_qty_key])
    |> validate_required([:quote, :quote_qty, :quoted_unit_price, :total_price, :labor_markup_pct, :mat_markup_pct, :serv_markup_pct, :quote_qty_key])
    |> put_quoted_unit_price_float()
  end

  defp put_quoted_unit_price_float(changeset) do
    case get_field(changeset, :quoted_unit_price) do
      %Decimal{} = decimal ->
        put_change(changeset, :quoted_unit_price_float, Decimal.to_float(decimal))
      nil ->
        changeset
    end
  end

  @doc """
  Fetches quote_qty records by quote_id and applies changeset to populate virtual fields.
  """
  def get_by_quote_id(quote_id) do
    Shophawk.Jb_Quote_qty
    |> where([j], j.quote == ^quote_id)
    |> Shophawk.Repo_jb.all()
    |> Enum.map(fn record ->
      record
      |> changeset(Map.from_struct(record))
      |> Ecto.Changeset.apply_changes()
    end)
  end

end
