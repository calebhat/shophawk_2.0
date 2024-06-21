defmodule Shophawk.Jb_job_operation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed



  schema "job_operation" do
    field :job, :string
    field :job_operation, :integer
    field :wc_vender, :string
    field :operation_service, :string
    field :sched_start, :naive_datetime
    field :sched_end, :naive_datetime
    field :sequence, :integer
    field :status, :string
    field :est_total_hours, :float
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :job_operation])
    |> validate_required([:job, :job_operation])
  end
end
