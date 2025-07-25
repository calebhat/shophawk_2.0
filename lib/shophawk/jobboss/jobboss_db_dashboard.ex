defmodule Shophawk.Jobboss_db_dashboard do
  import Ecto.Query, warn: false
  import Shophawk.Jobboss_db
  alias DateTime
  alias Shophawk.Jb_job
  alias Shophawk.Jb_BankHistory
  alias Shophawk.Jb_JournalEntry
  alias Shophawk.Jb_InvoiceHeader
  alias Shophawk.Jb_job_delivery
  alias Shophawk.Jb_delivery
  alias Shophawk.Jb_job_note_text
  alias Shophawk.Jb_address
  alias Shophawk.Jb_Ap_Check

  def bank_statements do #monthly bank statements
    ten_years_ago = NaiveDateTime.add(NaiveDateTime.utc_now(), -3650, :day)
    query =
      from r in Jb_BankHistory,
      where: r.statement_date > ^ten_years_ago,
      where: r.bank == "Johnson Bank"
      #order_by: [asc: r.employee]

    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> Map.drop([:bank]) |> sanitize_map() end)
  end

  def journal_entry(start_date, end_date) do #start_date and end_date are naive Time format
    query =
      from r in Jb_JournalEntry,
      where: r.transaction_date >= ^start_date and r.transaction_date <= ^end_date,
      where: r.gl_account == "104",
      order_by: [asc: r.transaction_date]
    failsafed_query(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def open_invoices() do
    query =
      from r in Jb_InvoiceHeader,
      where: r.open_invoice_amt > 0.0

    open_invoices =
      failsafed_query(query)
        |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
        |> Enum.sort_by(&(&1.customer), :desc)
        |> Enum.with_index()
        |> Enum.map(fn {inv, index} -> Map.put(inv, :id, index) end)
        |> Enum.reverse
        |> Enum.map(fn inv ->
          inv =
            cond do
              inv.terms in ["Net 30 days", "1% 10 Net 30", "2% 10 Net 30", "Due On Receipt"] -> Map.put(inv, :terms, 30)
              inv.terms in ["Net 45 Days", "2% 10 NET 45", "NET 40 DAYS"] -> Map.put(inv, :terms, 45)
              inv.terms in ["NET 60 DAYS"] -> Map.put(inv, :terms, 60)
              inv.terms in ["Net 75 Days", "Net 60 mth end"] -> Map.put(inv, :terms, 75)
              inv.terms in ["NET 90 DAYS"] -> Map.put(inv, :terms, 90)
              true -> inv
            end
          inv = Map.put(inv, :open_invoice_amount, Float.round(inv.open_invoice_amt, 2))
          inv = Map.put(inv, :days_open, Date.diff(Date.utc_today(), inv.document_date))
          inv = if Date.diff(inv.due_date, Date.utc_today()) <= 0, do: Map.put(inv, :late, true), else: Map.put(inv, :late, false)

          cond do
            inv.days_open < 30 -> Map.put(inv, :column, 1)
            inv.days_open >= 30 and inv.days_open <= 60 -> Map.put(inv, :column, 2)
            inv.days_open > 60 and inv.days_open <= 90 -> Map.put(inv, :column, 3)
            inv.days_open > 90 -> Map.put(inv, :column, 4)
            true -> Map.put(inv, :column, 0)
          end
        end)
      open_invoices
  end

  def active_jobs_with_cost() do
    query =
      from r in Jb_job_delivery,
      where: r.status == "Active"

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def released_jobs(date) do
    date = NaiveDateTime.new(date, ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_job_note_text,
      where: r.released_date == ^date

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def load_late_deliveries() do #All active deliveries
    today = NaiveDateTime.new(Date.utc_today(), ~T[00:00:00]) |> elem(1)
    two_years_ago = NaiveDateTime.new(Date.add(Date.utc_today(), -730), ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_delivery,
      where: is_nil(r.shipped_date) and
            r.promised_date < ^today and
            r.promised_date > ^two_years_ago and
            not like(r.job, "%lbr%") and
            not like(r.job, "%lvl%")

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_late_delivery_history() do #All active deliveries
    query =
      from r in Jb_delivery,
      where: r.shipped_date > r.promised_date and
            not like(r.job, "%lbr%") and
            not like(r.job, "%lvl%")

    failsafed_query(query)
      |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_deliveries() do
    two_years_ago = NaiveDateTime.new(Date.add(Date.utc_today(), -730), ~T[00:00:00]) |> elem(1)

    query =
      from r in Jb_delivery,
      where: r.promised_date >= ^two_years_ago and r.promised_quantity > r.shipped_quantity

      list =
        failsafed_query(query)
        |> Enum.map(fn op ->
          Map.from_struct(op)
          |> Map.drop([:__meta__])
          |> Map.put(:deliveryo, Integer.to_string(op.delivery))
          |> Map.drop([:delivery])
          |> sanitize_map()
        end)

        Enum.map(list, fn op ->
          Map.put(op, :delivery, op.deliveryo)
          |> Map.drop([:deliveryo])
        end)
        |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_deliveries(job_numbers) do
    query =
      from r in Jb_delivery,
      where: r.job in ^job_numbers and r.promised_quantity > 0 and is_nil(r.shipped_date) and is_nil(r.packlist)

    list =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.put(:deliveryo, Integer.to_string(op.delivery))
        |> Map.drop([:delivery])
        |> sanitize_map()
      end)

      Enum.map(list, fn op ->
        Map.put(op, :delivery, op.deliveryo)
        |> Map.drop([:deliveryo])
      end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  #not used?
  def load_all_deliveries(job_numbers) do
    query =
      from r in Jb_delivery,
      where: r.job in ^job_numbers and r.promised_quantity > 0

    list =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.put(:deliveryo, Integer.to_string(op.delivery))
        |> Map.drop([:delivery])
        |> sanitize_map()
      end)

      Enum.map(list, fn op ->
        Map.put(op, :delivery, op.deliveryo)
        |> Map.drop([:deliveryo])
      end)
      |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_active_deliveries(job_numbers) do
    query =
      from r in Jb_delivery,
      where: r.job in ^job_numbers and is_nil(r.shipped_date) and r.promised_quantity > 0

    failsafed_query(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
    |> Enum.sort_by(&(&1.job), :desc)
  end

  def load_invoices(start_date, end_date) do
    start_date = NaiveDateTime.new(start_date, ~T[00:00:00]) |> elem(1)
    end_date = NaiveDateTime.new(end_date, ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_InvoiceHeader,
      where: r.document_date >= ^start_date and r.document_date <= ^end_date
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def load_vendor_payments(start_date, end_date) do
    start_date = NaiveDateTime.new(start_date, ~T[00:00:00]) |> elem(1)
    end_date = NaiveDateTime.new(end_date, ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_Ap_Check,
      where: r.check_date >= ^start_date and r.check_date <= ^end_date and r.vendor not in ["DH", "DTH REAL"]
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  #not used?
  def load_jobs(job_numbers) do
    query = from r in Jb_job, where: r.job in ^job_numbers
    failsafed_query(query)
    |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  #not used?
  def load_delivery_jobs(job_numbers) do
    query = from r in Jb_job_delivery, where: r.job in ^job_numbers
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  #not used?
  def load_addresses(addresses) do
    query = from r in Jb_address, where: r.address in ^addresses
    failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) |> sanitize_map() end)
  end

  def total_revenue_at_date(date) do
    naive_datetime = NaiveDateTime.new(date, ~T[00:00:00]) |> elem(1)
    query = from j in Jb_job_delivery,
          join: d in Jb_delivery,
          on: j.job == d.job,
          where: j.order_date <= ^naive_datetime,
          where: d.promised_date >= ^naive_datetime or d.shipped_date >= ^naive_datetime,
          distinct: true,
          select: j.total_price
    failsafed_query(query)
    |> Enum.sum()
  end

  def total_jobs_at_date(date) do
    naive_datetime = NaiveDateTime.new(date, ~T[00:00:00]) |> elem(1)
    query = from j in Jb_job_delivery,
          join: d in Jb_delivery,
          on: j.job == d.job,
          where: j.order_date <= ^naive_datetime,
          where: d.promised_date >= ^naive_datetime or d.shipped_date >= ^naive_datetime,
          distinct: true,
          select: count(j.job)
    failsafed_query(query)
    |> Enum.sum()
  end

  def total_worth_of_orders_in_six_weeks_from_date(date) do
    # Convert the date to a NaiveDateTime at the start of the day
    naive_datetime = NaiveDateTime.new(date, ~T[00:00:00]) |> elem(1)

    # Calculate the end date, which is 6 weeks from the input date
    end_date = NaiveDateTime.add(naive_datetime, 6 * 7 * 24 * 60 * 60, :second)

    query = from j in Jb_job_delivery,
            join: d in Jb_delivery,
            on: j.job == d.job,
            where: j.order_date <= ^naive_datetime,
            where: d.promised_date >= ^naive_datetime and d.promised_date <= ^end_date,
            distinct: true,
            select: j.total_price

    failsafed_query(query)
    |> Enum.sum()
  end

end
