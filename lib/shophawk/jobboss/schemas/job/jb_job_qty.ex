defmodule Shophawk.Jb_job_qty do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "job" do
    field :job, :string
    field :make_quantity, :integer
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :make_quantity])
    |> validate_required([:job, :make_quantity])
  end
end
