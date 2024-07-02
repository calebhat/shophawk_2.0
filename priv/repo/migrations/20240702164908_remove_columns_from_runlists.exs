defmodule Shophawk.Repo.Migrations.RemoveColumnsFromRunlists do
  use Ecto.Migration

  def change do
    alter table(:runlists) do
      remove :job
      remove :wc_vendor
      remove :operation_service
      remove :sched_start
      remove :sched_end
      remove :sequence
      remove :customer
      remove :order_date
      remove :part_number
      remove :job_status
      remove :rev
      remove :description
      remove :order_quantity
      remove :extra_quantity
      remove :pick_quantity
      remove :make_quantity
      remove :open_operations
      remove :shipped_quantity
      remove :customer_po
      remove :customer_po_line
      remove :job_sched_end
      remove :job_sched_start
      remove :note_text
      remove :released_date
      remove :material
      remove :mat_vendor
      remove :mat_description
      remove :mat_pick_or_buy
      remove :mat_status
      remove :dots
      remove :currentop
      remove :status
      remove :est_total_hrs
      remove :employee
      remove :work_date
      remove :act_setup_hrs
      remove :act_run_hrs
      remove :act_run_qty
      remove :act_scrap_qty
      remove :data_collection_note_text
    end
  end
end
