defmodule Shophawk.Jb_job_operation_time do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @schema_prefix "dbo"  # Explicitly setting the schema if needed

  schema "job_operation_time" do
    field :job_operation, :integer
    field :employee, :string, default: ""
    field :work_date, :naive_datetime
    field :act_run_qty, :float, default: 0.0
    field :act_scrap_qty, :float, default: 0.0
    field :last_updated, :naive_datetime
    field :act_run_labor_hrs, :float, default: 0.0

    #timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:job_operation, :employee, :work_date, :act_run_qty, :act_run_qty, :act_scrap_qty, :last_updated, :act_run_labor_hrs])
    |> validate_required([:job_operation])
  end
end
