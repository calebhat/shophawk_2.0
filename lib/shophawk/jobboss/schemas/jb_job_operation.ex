defmodule Shophawk.Jb_job_operation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed



  schema "job_operation" do
    field :job, :string
    field :job_operation, :integer
    field :wc_vendor, :string
    field :inside_oper, :boolean
    field :operation_service, :string
    field :sched_start, :naive_datetime
    field :sched_end, :naive_datetime
    field :sequence, :integer
    field :status, :string, default: "nil"
    field :est_total_hrs, :float
    field :last_updated, :naive_datetime
    field :note_text, :string
    field :act_run_qty, :integer
    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job, :job_operation, :wc_vendor, :inside_oper, :operation_service, :sched_end, :sched_end, :sequence, :status, :est_total_hrs, :note_text, :act_run_qty])
    |> validate_required([:job, :job_operation, :status])
  end
end
