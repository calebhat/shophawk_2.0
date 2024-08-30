defmodule ShophawkWeb.DashboardLive.Index do
  use ShophawkWeb, :live_view
  alias Shophawk.Jobboss_db
  import Number.Currency
  alias ShophawkWeb.CheckbookComponent
  alias ShophawkWeb.InvoicesComponent
  alias ShophawkWeb.RevenueComponent
  alias ShophawkWeb.MonthlySalesChartComponent
  alias Shophawk.Dashboard

  @impl true
  def mount(_params, _session, socket) do
      {:ok, socket
      |> assign(:checkbook_entries, [])
      |> assign(:current_balance, "Loading...")
      |> assign(:open_invoices, %{})
      |> assign(:selected_range, "")
      |> assign(:open_invoice_values, [])
      |> assign(:six_weeks_revenue_amount, 0)
      |> assign(:total_revenue, 0)
      |> assign(:active_jobs, 0)
      |> assign(:revenue_chart_data, [])
      |> assign(:sales_chart_data, [])
      #Yearly Sales Chart
      |> assign(:monthly_sales, 0)
      |> assign(:this_months_sales, 0)
      |> assign(:this_years_sales, 0)
      |> assign(:projected_yearly_sales, 0)

      }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    Process.send(self(), :load_data, [:noconnect])

    socket
    |> assign(:page_title, "Dashboard")
  end

  def handle_info(:load_data, socket) do
    {:noreply,
      socket
      #|> load_checkbook_component()
      #|> load_open_invoices_component()
      |> load_anticipated_revenue_component()
      |> load_monthly_sales_chart_component()
    }
  end

  def load_checkbook_component(socket) do
    bank_statements =
      Jobboss_db.bank_statements
      |> Enum.reverse

    last_statement = List.first(bank_statements)
    ending_balance = last_statement.ending_balance


    {:ok, days_to_load} = NaiveDateTime.new(Date.add(last_statement.statement_date, -30), ~T[00:00:00.000])

    checkbook_entries = #journal entries from 30 days before last bank statement
      Jobboss_db.journal_entry(days_to_load, NaiveDateTime.utc_now())
      |> Enum.map(fn entry -> if entry.reference == "9999", do: Map.put(entry, :reference, "9999 - ACH Check"), else: entry end)
      |> Enum.reverse

    current_balance =
      Enum.filter(checkbook_entries, fn entry -> Date.after?(entry.transaction_date, last_statement.statement_date) end)
      |> Enum.reduce(ending_balance, fn entry, acc ->
        acc + entry.amount
      end)
      |> Float.round(2)
      |> number_to_currency

      socket
      |> assign(:current_balance, current_balance)
      |> assign(:checkbook_entries, checkbook_entries)
  end

  def load_open_invoices_component(socket) do
    open_invoices = Jobboss_db.open_invoices

    open_invoice_values = Enum.reduce(open_invoices, %{zero_to_thirty: 0, thirty_to_sixty: 0, sixty_to_ninety: 0, ninety_plus: 0, late: 0, all: 0}, fn inv, acc ->
        days_open = Date.diff(Date.utc_today(), inv.document_date)
        acc = cond do
          days_open > 0 and days_open <= 30 -> Map.put(acc, :zero_to_thirty, acc.zero_to_thirty + inv.open_invoice_amount)
          days_open > 30 and days_open <= 60 -> Map.put(acc, :thirty_to_sixty, acc.thirty_to_sixty + inv.open_invoice_amount)
          days_open > 60 and days_open <= 90 -> Map.put(acc, :sixty_to_ninety, acc.sixty_to_ninety + inv.open_invoice_amount)
          days_open > 90 -> Map.put(acc, :ninety_plus, acc.ninety_plus + inv.open_invoice_amount)
          true -> acc
        end
        acc = if inv.late == true, do: Map.put(acc, :late, acc.late + inv.open_invoice_amount), else: acc
        acc = Map.put(acc, :all, acc.all + inv.open_invoice_amount)

      end)

    socket =
      assign(socket, :open_invoices, open_invoices)
      |> assign(:open_invoice_storage, open_invoices) #used when changing range of invoices viewed
      |> assign(:open_invoice_values, open_invoice_values)
  end

  def load_anticipated_revenue_component(socket) do
    data = Shophawk.Dashboard.list_revenue
    chart_data =
      %{
        total_revenue: Enum.map(data, fn %{week: week, total_revenue: revenue} -> [week |> Date.to_iso8601(), revenue] end),
        six_week_revenue: Enum.map(data, fn %{week: week, six_week_revenue: revenue} -> [week |> Date.to_iso8601(), revenue] end)
      }
    socket = assign(socket, :revenue_chart_data, Jason.encode!(chart_data))
    socket = calc_current_revenue(socket)
  end

  def load_monthly_sales_chart_component(socket) do
    beginning_of_this_month = Date.beginning_of_month(Date.utc_today())
    current_months_sales = generate_monthly_sales(beginning_of_this_month, Date.add(Date.utc_today, 1)) |> List.first()
    sales_chart_data =
      Dashboard.list_monthly_sales
      |> Enum.map(fn op ->
        map =
          Map.from_struct(op)
          |> Map.drop([:__meta__])
          |> Map.drop([:id])
          |> Map.drop([:inserted_at])
          |> Map.drop([:updated_at])
        case Map.get(map, :date) do #replace or add current months sales with updated value
          ^beginning_of_this_month -> Map.put(map, :amount, current_months_sales.amount)
          nil ->
            Map.put(map, :date, beginning_of_this_month)
            |> Map.put(:amount, current_months_sales.amount)
          _ -> map
        end
      end)
      |> Enum.group_by(fn d -> d.date.year end)
      |> Enum.map(fn {year, entries} ->
        month_amounts =
          Enum.reduce(1..12, [], fn n, acc ->
            amount =
              case Enum.find(entries, fn entry -> entry.date.month == n end) do
                nil -> nil
                found_entry -> found_entry.amount
              end
              [amount | acc]
          end)
          |> Enum.reverse
        %{name: "#{year}", data: month_amounts}
      end)
    this_year_data = Enum.find(sales_chart_data, fn data -> data.name == Integer.to_string(Date.utc_today().year) end)
    this_years_sales =
      Enum.reduce(this_year_data.data, 0, fn d, acc ->
        case d do
          nil -> acc
          amount -> amount + acc
          _ -> acc
        end
      end)

    socket =
      socket
      |> assign(:sales_chart_data, Jason.encode!(%{series: sales_chart_data}))
      |> assign(:this_months_sales, current_months_sales.amount)
      |> assign(:this_years_sales, this_years_sales)
      |> assign(:projected_yearly_sales, (this_years_sales / Date.utc_today().month) * 12)
  end

  def calc_current_revenue(socket) do
    jobs = Jobboss_db.active_jobs_with_cost()
    job_numbers = Enum.map(jobs, fn job -> job.job end)
    deliveries = Jobboss_db.load_deliveries(job_numbers)
    merged_deliveries = Enum.reduce(deliveries, [], fn d, acc ->
      job = Enum.find(jobs, fn job -> job.job == d.job end)
      acc ++ [Map.merge(d, job)]
    end)
    |> Enum.filter(fn d -> d.unit_price > 0 end)
    |> Enum.sort_by(&(&1.promised_date), Date)
    total_revenue = Enum.reduce(merged_deliveries, 0, fn d, acc -> (d.promised_quantity * d.unit_price) + acc end)
    six_weeks_out_deliveries =
      Enum.filter(merged_deliveries, fn d -> Date.before?(d.promised_date, Date.add(Date.utc_today(), 43)) end)
    six_weeks_revenue_amount = Enum.reduce(six_weeks_out_deliveries, 0, fn d, acc -> (d.promised_quantity * d.unit_price) + acc end)

    socket
    |> assign(:six_weeks_revenue_amount, six_weeks_revenue_amount)
    |> assign(:total_revenue, total_revenue)
    |> assign(:active_jobs, Enum.count(jobs))
  end

  def handle_event("load_invoice_late_range", %{"range" => range}, socket) do
    open_invoices = socket.assigns.open_invoice_storage
    ranged_open_invoices =
      Enum.filter(open_invoices, fn inv ->
        case range do
          "0-30" -> inv.days_open > 0 and inv.days_open <= 30
          "31-60" -> inv.days_open > 30 and inv.days_open <= 60
          "61-90" -> inv.days_open > 60 and inv.days_open <= 90
          "90+" -> inv.days_open > 90
          "late" -> inv.late == true
          "all" -> true
          _ -> false
        end
      end)
    {:noreply, assign(socket, :open_invoices, ranged_open_invoices) |> assign(:selected_range, range)}
  end

  def handle_event("test_click", _params, socket) do

    #socket = load_monthly_sales_chart_component(socket)

    ######################Functions to load history into db for first load with new dashboard####################
    #save_monthly_sales(Date.add(Date.utc_today, -4015), Date.add(Date.utc_today, -240))
    #save_revenue_history()
    {:noreply, socket}
  end

  def save_monthly_sales(start_date, end_date) do
    monthly_sales = generate_monthly_sales(start_date, end_date, [])
    #Enum.each(monthly_sales, fn month -> IO.inspect(month) end)

    Enum.each(monthly_sales, fn r -> Shophawk.Dashboard.create_monthly_sales(r) end)
  end

  def generate_monthly_sales(start_date, end_date, list \\ []) do
    if Date.after?(start_date, end_date) do
      list
    else
      start_date = Date.beginning_of_month(start_date)
      case Jobboss_db.load_deliveries(start_date, Date.end_of_month(start_date)) do
        [] -> list #if no deliveries found
        deliveries ->
          jobs = Enum.map(deliveries, fn d -> d.job end) |> Jobboss_db.load_delivery_jobs()
          merged_deliveries = Enum.reduce(deliveries, [], fn d, acc ->
            job = Enum.find(jobs, fn job -> job.job == d.job end)
            acc ++ [Map.merge(d, job)]
            end)
            |> Enum.sort_by(&(&1.promised_date), Date)
          total_sales =
            %{amount: Enum.reduce(merged_deliveries, 0, fn d, acc -> Float.round((d.promised_quantity * d.unit_price) + acc, 2) end),
              date: start_date}
          generate_monthly_sales(Date.add(start_date, 35), end_date, [total_sales | list])
      end
    end
  end

  ###############################################
    #Function to load history and save to DB
    def save_revenue_history() do
      revenue_history = generate_full_revenue_history(~D[2014-01-06], Date.add(Date.utc_today, 1))
      Enum.each(revenue_history, fn r -> Shophawk.Dashboard.create_revenue(r) end)
    end

    #Input startdate and an end date t going forward in time to generate load for each week in between.
    def generate_full_revenue_history(start_date, end_date, list \\ []) do
      if Date.after?(start_date, end_date) do
        list
      else
        total_revenue = Jobboss_db.total_revenue_at_date(start_date)
        six_week_revenue = Jobboss_db.total_worth_of_orders_in_six_weeks_from_date(start_date)
        total_jobs = Jobboss_db.total_jobs_at_date(start_date)
        map = %{total_revenue: Float.round(total_revenue, 2), six_week_revenue: Float.round(six_week_revenue, 2), total_jobs: total_jobs, week: start_date}
        generate_full_revenue_history(Date.add(start_date, 7), end_date, [map | list])
      end
    end

end
