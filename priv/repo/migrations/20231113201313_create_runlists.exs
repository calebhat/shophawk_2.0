defmodule Shophawk.Repo.Migrations.CreateRunlists do
  use Ecto.Migration

  def change do
    create table(:runlists) do
      add :job, :string
      add :job_operation, :integer
      add :wc_vendor, :string
      add :operation_service, :string
      add :sched_start, :date
      add :sched_end, :date
      add :sequence, :integer
      add :customer, :string
      add :order_date, :date
      add :part_number, :string
      add :job_status, :string
      add :rev, :string
      add :description, :string
      add :order_quantity, :integer
      add :extra_quantity, :integer
      add :pick_quantity, :integer
      add :make_quantity, :integer
      add :open_operations, :integer
      add :shipped_quantity, :integer
      add :customer_po, :string
      add :customer_po_line, :integer
      add :job_sched_end, :date
      add :job_sched_start, :date
      add :note_text, :string
      add :released_date, :date
      add :material, :string
      add :mat_vendor, :string
      add :mat_description, :string
      add :mat_pick_or_buy, :string
      add :mat_status, :string
      add :assignment, :string
      add :dots, :integer
      add :currentop, :string
      add :material_waiting, :boolean, default: false, null: false
      add :status, :string
      add :est_total_hrs, :float

      timestamps()
    end
  end
end
