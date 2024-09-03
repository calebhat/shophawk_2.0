defmodule Shophawk.Jb_job_note_text do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "job" do
    field :job, :string
    field :released_date, :naive_datetime
    field :note_text, :string
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :released_date, :note_text])
    |> validate_required([:job, :released_date])
  end
end
