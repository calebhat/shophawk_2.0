defmodule Shophawk.Jb_attachment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "attachment" do
    field :owner_id, :string
    field :attach_path, :string
    field :description, :string

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:owner_id, :attach_path, :description])
    |> validate_required([:owner_id, :attach_path])
  end
end
