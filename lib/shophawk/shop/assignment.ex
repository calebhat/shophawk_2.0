defmodule Shophawk.Shop.Assignment do
  use Ecto.Schema

  schema "assignments" do
    field :assignment, :string
    belongs_to :department, Shophawk.Shop.Department

    timestamps()
  end

  def changeset(assignment, params \\ %{}) do
    assignment
    |> Ecto.Changeset.cast(params, [:assignment])
    |> Ecto.Changeset.validate_required([:assignment])
  end

end
