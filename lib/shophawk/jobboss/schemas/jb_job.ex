defmodule Shophawk.Jb_job do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "job" do
    field :job, :string
    field :customer, :string
    field :order_date, :naive_datetime
    field :part_number, :string
    field :status, :string
    field :rev, :string
    field :description, :string
    field :order_quantity, :integer
    field :extra_quantity, :integer
    field :pick_quantity, :integer
    field :make_quantity, :integer
    field :customer_po, :string
    field :customer_po_ln, :string
    field :sched_end, :naive_datetime
    field :sched_start, :naive_datetime
    field :note_text, :string
    field :released_date, :naive_datetime
    field :user_values, :integer
    field :last_updated, :naive_datetime
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :customer, :order_date, :part_number, :status, :rev, :description, :order_quantity, :extra_quantity, :pick_quantity, :make_quantity, :customer_po, :customer_po_ln, :sched_end, :sched_start, :note_text, :released_date, :user_values, :last_updated])
    |> validate_required([:job, :customer])
  end
end
