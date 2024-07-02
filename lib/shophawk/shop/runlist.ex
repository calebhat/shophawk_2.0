defmodule Shophawk.Shop.Runlist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "runlists" do
    field :job_operation, :integer
    field :material_waiting, :boolean, default: false
    field :assignment, :string

    timestamps()
  end

  @doc false
  def changeset(runlist, attrs) do
    runlist
    |> cast(attrs, [:job_operation, :material_waiting, :assignment])
    |> validate_required([:job_operation, :material_waiting, :assignment])
  end
end
