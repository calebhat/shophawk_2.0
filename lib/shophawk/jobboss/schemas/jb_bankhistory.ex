defmodule Shophawk.Jb_BankHistory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "bank_history" do
    field :statement_date, :naive_datetime
    field :beginning_balance, :float
    field :ending_balance, :float
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:statement_date, :beginning_balance, :ending_balance])
    |> validate_required([:statement_date, :beginning_balance, :ending_balance])
  end
end
