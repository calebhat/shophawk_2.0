defmodule Shophawk.Jb_job_operation_time do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "job_operation_time" do
    field :job_operation, :integer
    field :employee, :string, default: ""
    field :work_date, :naive_datetime
    field :act_setup_hrs, :float, default: 0.0
    field :act_run_hrs, :float, default: 0.0
    field :act_run_qty, :float, default: 0.0
    field :act_scrap_qty, :float, default: 0.0
    field :last_updated, :naive_datetime

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job_operation, :employee, :work_date, :act_setup_hrs, :act_run_hrs, :act_run_qty, :act_run_qty, :act_scrap_qty, :last_updated])
    |> validate_required([:job_operation])
  end
end
