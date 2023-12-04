defmodule Shophawk.Shop.Runlist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "runlists" do
    field :dots, :integer
    field :mat_description, :string
    field :description, :string
    field :sched_start, :date
    field :open_operations, :integer
    field :job_sched_end, :date
    field :wc_vendor, :string
    field :pick_quantity, :integer
    field :job_sched_start, :date
    field :job_operation, :integer
    field :status, :string
    field :job_status, :string
    field :rev, :string
    field :currentop, :string
    field :sequence, :integer
    field :customer, :string
    field :order_date, :date
    field :part_number, :string
    field :shipped_quantity, :integer
    field :material_waiting, :boolean, default: false
    field :mat_vendor, :string
    field :job, :string
    field :order_quantity, :integer
    field :note_text, :string
    field :assignment, :string
    field :make_quantity, :integer
    field :operation_service, :string
    field :customer_po, :string
    field :sched_end, :date
    field :est_total_hrs, :float
    field :extra_quantity, :integer
    field :customer_po_line, :integer
    field :released_date, :date
    field :material, :string

    timestamps()
  end

  @doc false
  def changeset(runlist, attrs) do
    runlist
    |> cast(attrs, [:job, :job_operation, :wc_vendor, :operation_service, :sched_start, :sched_end, :sequence, :customer, :order_date, :part_number, :rev, :job_status, :description, :order_quantity, :extra_quantity, :pick_quantity, :make_quantity, :open_operations, :shipped_quantity, :customer_po, :customer_po_line, :job_sched_end, :job_sched_start, :note_text, :released_date, :material, :mat_vendor, :mat_description, :assignment, :dots, :currentop, :material_waiting, :status, :est_total_hrs])
    |> validate_required([:job, :job_operation, :wc_vendor, :operation_service, :sched_start, :sched_end, :sequence, :material_waiting, :status, :est_total_hrs])
  end
end
