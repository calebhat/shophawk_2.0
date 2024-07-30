defmodule Shophawk.Jb_JournalEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "journal_entry" do
    field :source, :string
    field :amount, :float
    field :transaction_date, :naive_datetime
    field :last_updated, :naive_datetime
    field :reference, :integer
    field :type, :string
    field :gl_account, :string
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:source, :amount, :transaction_date, :last_updated, :reference, :type, :gl_account])
    |> validate_required([:source, :amount, :transaction_date, :last_updated, :reference, :type, :gl_account])
  end
end
