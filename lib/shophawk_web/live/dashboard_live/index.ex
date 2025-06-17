defmodule ShophawkWeb.DashboardLive.Index do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJob #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover
  alias ShophawkWeb.UserAuth
  alias Shophawk.Jobboss_db
  import Number.Currency
  alias ShophawkWeb.CheckbookComponent
  alias ShophawkWeb.InvoicesComponent
  alias ShophawkWeb.RevenueComponent
  alias ShophawkWeb.MonthlySalesChartComponent
  alias ShophawkWeb.TravelorcountComponent
  alias ShophawkWeb.HotjobsComponent
  alias ShophawkWeb.WeekoneTimeoffComponent
  alias ShophawkWeb.WeektwoTimeoffComponent
  alias ShophawkWeb.YearlySalesChartComponent
  alias ShophawkWeb.LateShipmentsComponent
  alias ShophawkWeb.TopVendorsComponent
  alias Shophawk.Dashboard


  @impl true
  def mount(_params, _session, socket) do
    case UserAuth.ensure_admin_access(socket.assigns.current_user.email) do
      :ok -> {:ok, set_default_assigns(socket)}
      {:error, message} ->
        {:ok,
          socket
          |> put_flash(:error, message)
          |> redirect(to: "/")}
    end
  end

  def set_default_assigns(socket) do
    socket
    #Checkbook
    |> assign(:checkbook_entries, [])
    |> assign(:current_balance, "Loading...")
    #Invoices
    |> assign(:open_invoices, %{})
    |> assign(:selected_range, "")
    |> assign(:open_invoice_values, [])

    #anticated revenue
    |> assign(:six_weeks_revenue_amount, 0)
    |> assign(:total_revenue, 0)
    |> assign(:active_jobs, 0)
    |> assign(:revenue_chart_data, [])
    |> assign(:sales_chart_data, [])
    |> assign(:percentage_diff, 0)

    #monthly Sales Chart
    |> assign(:monthly_sales, 0)
    |> assign(:this_months_sales, 0)
    |> assign(:this_years_sales, 0)
    |> assign(:projected_yearly_sales, 0)
    |> assign(:sales_table_data, [])
    |> assign(:show_monthly_sales_table, false)
    |> assign(:monthly_average, 0)

    #Travelor Count
    |> assign(:travelor_count, [])
    |> assign(:travelor_totals, %{})

    #hot jobs
    |> assign(:hot_jobs, [])

    #timeoff
    |> assign(:weekly_dates, %{})
    |> assign(:week1_timeoff, [])
    |> assign(:week2_timeoff, [])

    #Yearly Sales Chart
    |> assign(:yearly_sales_data, [])
    |> assign(:total_sales, 0)
    |> assign(:complete_yearly_sales_data, [])
    |> assign(:top_10_startdate, Date.new!(Date.utc_today().year, 1, 1))
    |> assign(:top_10_enddate, Date.utc_today())

    #late Deliveries
    |> assign(:late_deliveries, [])
    |> assign(:late_delivery_count, 0)
    |> assign(:late_deliveries_loaded, false)

    #Top Vendors
    |> assign(:top_vendors, [])
    |> assign(:top_vendors_startdate, Date.new!(Date.utc_today().year, 1, 1))
    |> assign(:top_vendors_enddate, Date.utc_today())
    |> assign(:empty_vendor_list, false)
  end

  @impl true
  def handle_params(params, _url, socket) do
    case Map.has_key?(params, "reload") do
      true -> {:noreply, socket}
      _ -> {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end
  end

  defp apply_action(socket, :index, _params) do
    Process.send(self(), :load_data, [:noconnect])
    socket
    |> assign(:page_title, "Dashboard")
  end

  @impl true
  def handle_info(:load_data, socket) do
    {:noreply,
      socket
      |> load_checkbook_component() #5 seconds
      |> load_open_invoices_component() #5 sec
      |> load_travelors_released_componenet() #1 second
      |> load_hot_jobs()
      |> load_time_off()
      |> load_late_shipments()
      |> load_anticipated_revenue_component() #2 sec
      |> load_monthly_sales_chart_component() #instant
      |> load_yearly_sales_chart(socket.assigns.top_10_startdate, socket.assigns.top_10_enddate)
      |> load_top_vendors(socket.assigns.top_vendors_startdate, socket.assigns.top_vendors_enddate)
    }
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, socket) do
    # Handle task errors
    {:noreply, assign(socket, loading: false, error: reason)}
  end

  def load_checkbook_component(socket) do
    bank_statements =
      Jobboss_db.bank_statements
      |> Enum.reverse

    last_statement = List.first(bank_statements)
    ending_balance = last_statement.ending_balance

    {:ok, days_to_load} = NaiveDateTime.new(Date.add(last_statement.statement_date, -30), ~T[00:00:00.000])

    checkbook_entries = #journal entries from 30 days before last bank statement
      Jobboss_db.journal_entry(days_to_load, elem(NaiveDateTime.new(Date.utc_today(), ~T[00:00:00.000]), 1))
      |> Enum.map(fn entry -> if entry.reference == "9999", do: Map.put(entry, :reference, "9999 - ACH Check"), else: entry end)
      |> Enum.reverse

    checkbook_entries_as_strings = #journal entries from 30 days before last bank statement
      Enum.map(checkbook_entries, fn entry ->
        Map.put(entry, :amount, :erlang.float_to_binary(entry.amount, [{:decimals, 2}]))
      end)

    current_balance =
      Enum.filter(checkbook_entries, fn entry -> Date.after?(entry.transaction_date, last_statement.statement_date) end)
      |> Enum.reduce(ending_balance, fn entry, acc ->
        acc + entry.amount
      end)
      |> Float.round(2)
      |> number_to_currency

      socket
      |> assign(:current_balance, current_balance)
      |> assign(:checkbook_entries, checkbook_entries_as_strings)
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
        Map.put(acc, :all, acc.all + inv.open_invoice_amount)
      end)

    assign(socket, :open_invoices, open_invoices)
    |> assign(:open_invoice_storage, open_invoices) #used when changing range of invoices viewed
    |> assign(:open_invoice_values, open_invoice_values)
  end

  def load_anticipated_revenue_component(socket) do

    case Shophawk.Dashboard.list_revenue do
      [] -> socket
      nil -> socket
      data ->
        chart_data =
          %{
            total_revenue: Enum.map(data, fn %{week: week, total_revenue: revenue} -> [week |> Date.to_iso8601(), revenue] end),
            six_week_revenue: Enum.map(data, fn %{week: week, six_week_revenue: revenue} -> [week |> Date.to_iso8601(), revenue] end)
          }


        {six_weeks_revenue_amount, total_revenue, active_jobs} = calc_current_revenue()

        #Add current anticipated rev to chart
        current_six_week_rev = [Date.to_iso8601(Date.utc_today), Float.round(six_weeks_revenue_amount, 2)]
        current_total_rev = [Date.to_iso8601(Date.utc_today), Float.round(total_revenue, 2)]

        six_week_data = Map.get(chart_data, :six_week_revenue)
        total_week_data = Map.get(chart_data, :total_revenue)

        updated_six_week = [current_six_week_rev] ++ six_week_data
        updated_total = [current_total_rev] ++ total_week_data

        chart_data_with_this_weeks_revenue =
          %{
            total_revenue: updated_total,
            six_week_revenue: updated_six_week
          }

        six_weeks_moving_avg_6_weeks = %{six_week_moving_avg: calculate_moving_average(chart_data_with_this_weeks_revenue.six_week_revenue, 12)}
        total_moving_avg_20_weeks = %{total_moving_avg: calculate_moving_average(chart_data_with_this_weeks_revenue.total_revenue, 24)}
        chart_data_with_moving_averages =
          Map.merge(chart_data_with_this_weeks_revenue, total_moving_avg_20_weeks)
          |> Map.merge(six_weeks_moving_avg_6_weeks)


        percentage_diff =
          case Enum.at(data, 1) do
            nil -> "0.0"
            found_data ->
              (1- (found_data.six_week_revenue / six_weeks_revenue_amount)) * 100
              |> Float.round(2)
              |> Number.Percentage.number_to_percentage(precision: 1)
            end

        socket
        |> assign(:revenue_chart_data, Jason.encode!(chart_data_with_moving_averages))
        |> assign(:six_weeks_revenue_amount, six_weeks_revenue_amount)
        |> assign(:total_revenue, total_revenue)
        |> assign(:active_jobs, active_jobs)
        |> assign(:percentage_diff, percentage_diff)
    end
  end

  def calculate_moving_average(entries, weeks) do
    # Sort entries by date to ensure correct order (oldest to newest)
    sorted_entries = Enum.sort_by(entries, fn [date, _value] -> date end)

    # Calculate moving averages
    sorted_entries
    |> Enum.with_index()
    |> Enum.map(fn {[date, _value], index} ->
      # Get the previous (weeks - 1) entries plus the current one (up to 'weeks' total)
      window = Enum.slice(sorted_entries, max(0, index - (weeks - 1)), weeks)
      # Extract just the values (revenues) from the window
      values = Enum.map(window, fn [_d, v] -> v end)
      # Calculate the average
      avg = Enum.sum(values) / Enum.count(values)
      [date, Float.round(avg, 2)]
    end)
  end

  def calc_current_revenue() do
    jobs = Jobboss_db.active_jobs_with_cost()
    job_numbers = Enum.map(jobs, fn job -> job.job end)
    deliveries = Jobboss_db.load_active_deliveries(job_numbers)
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

    {six_weeks_revenue_amount, total_revenue, Enum.count(jobs)}
  end

  def load_monthly_sales_chart_component(socket) do
    beginning_of_this_month = Date.beginning_of_month(Date.utc_today())
    beginning_of_last_month = Date.add(beginning_of_this_month, -5) |> Date.beginning_of_month()
    {current_months_sales, last_months_sales} =
      case generate_monthly_sales(beginning_of_last_month, Date.add(Date.utc_today, 1)) do
        [current_months_sales, last_months_sales] -> {current_months_sales, last_months_sales}
        [last_months_sales] -> { %{date: beginning_of_this_month, amount: 0.0}, last_months_sales}
        _ -> {%{date: beginning_of_this_month, amount: 0.0}, %{date: beginning_of_last_month, amount: 0.0}}
      end

    sales_table_data =
      Dashboard.list_monthly_sales
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.drop([:id])
        |> Map.drop([:inserted_at])
        |> Map.drop([:updated_at])
      end)

    ### Prepare sales table data ###
    # Create a list of all months in the current year
    all_months = for month <- 1..12, do: %{date: Date.new!(Date.utc_today().year, month, 1), amount: nil}
    # Filter for future months
    all_months = Enum.filter(all_months, fn %{date: date} -> Date.compare(date, Date.utc_today()) == :gt end)

    #add in last months sales if not present
    #last months sales might not be there because the code waits 2 days after the end of month to
    #save the previous months sales to let all checks clear.
    contains_last_months_sales = if List.first(sales_table_data).date == beginning_of_last_month, do: true, else: false
    #add to chart data if needed
    sales_table_data =
      case contains_last_months_sales do
        false -> [last_months_sales] ++ sales_table_data
        true -> sales_table_data
      end
    #add to table data if needed
    months_to_add_to_list =
      case contains_last_months_sales do
        false -> [current_months_sales, last_months_sales]
        true -> [current_months_sales]
      end

    # Combine existing data with all months, preferring existing data
    final_sales_table_data =
      (months_to_add_to_list ++ sales_table_data ++ all_months)
      |> Enum.sort_by(& &1.date, {:desc, Date})
      |> Enum.uniq_by(& {&1.date.year, &1.date.month})
      |> Enum.reduce({0, %{}, []}, fn map, {year, current_year_map, acc} ->
        if map.date.year == year do
          {map.date.year, add_date_key_and_amount(current_year_map, map.date.month, map.amount), acc}
        else
          {map.date.year, add_date_key_and_amount(%{year: map.date.year, total: 0}, map.date.month, map.amount), [current_year_map | acc]}
        end
      end)
      |> elem(2)
      |> Enum.reject(fn map -> map == %{} end)
      |> Enum.reverse

    ### 12 month Average ###
    twelve_month_sum =
      Enum.take(sales_table_data, 12)
      |> Enum.reduce(0, fn month, acc -> month.amount + acc end)
    monthly_average = twelve_month_sum / 12

    #if this months sales are less than the min value from other months, don't add it to the chart data
    #This keeps the y axis autoscaled correctly
    min_amount =
      case sales_table_data do
        [] -> 0.0
        data -> Enum.min_by(data, fn m -> m.amount end).amount
      end
    sales_chart_data =
      if current_months_sales.amount >= min_amount do
        case Enum.find(sales_table_data, fn month -> month.date == beginning_of_this_month end) do
          nil -> [%{date: beginning_of_this_month, amount: current_months_sales.amount} | sales_table_data]
          found_month -> [Map.put(found_month, :amount, current_months_sales.amount) | sales_table_data]
        end
      else
        sales_table_data
      end
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

    this_year_data =
      case Enum.find(sales_chart_data, fn data -> data.name == Integer.to_string(Date.utc_today().year) end) do
        nil -> %{data: [current_months_sales.amount], name: Integer.to_string(Date.utc_today().year)}
        data -> data
      end
    this_years_sales =
      Enum.reduce(this_year_data.data, 0, fn d, acc ->
        case d do
          nil -> acc
          amount -> amount + acc
        end
      end)
    days_in_this_month = Date.days_in_month(Date.utc_today())
    progress_into_current_month = Date.utc_today().day / days_in_this_month
    total_months_of_year_progress = Date.utc_today().month + progress_into_current_month - 1.0
    years_monthly_average = this_years_sales / total_months_of_year_progress
    project_sales = years_monthly_average * 12

    socket
    |> assign(:sales_chart_data, Jason.encode!(%{series: sales_chart_data}))
    |> assign(:sales_table_data, final_sales_table_data)
    |> assign(:this_months_sales, current_months_sales.amount)
    |> assign(:this_years_sales, this_years_sales)
    |> assign(:projected_yearly_sales, project_sales)
    |> assign(:monthly_average, monthly_average)
  end

  def generate_monthly_sales(start_date, end_date, list \\ []) do
    if Date.after?(start_date, end_date) do
      list
    else
      start_date = Date.beginning_of_month(start_date)
      case Jobboss_db.load_invoices(start_date, Date.end_of_month(start_date)) do
        [] -> list #if no deliveries found
        invoices ->
          invoice_total = Enum.reduce(invoices, 0, fn inv, acc -> inv.orig_invoice_amt + acc end) |> Float.round(2)
          total_sales = %{amount: invoice_total, date: start_date}
          generate_monthly_sales(Date.add(start_date, 35), end_date, [total_sales | list])
      end
    end
  end
  def add_date_key_and_amount(map, int, amount) do
    map =
      case amount do
        nil -> map
        value -> Map.put(map, :total, map.total + value)
      end
    case int do
      1 -> Map.put(map, :jan, amount)
      2 -> Map.put(map, :feb, amount)
      3 -> Map.put(map, :mar, amount)
      4 -> Map.put(map, :apr, amount)
      5 -> Map.put(map, :may, amount)
      6 -> Map.put(map, :jun, amount)
      7 -> Map.put(map, :jul, amount)
      8 -> Map.put(map, :aug, amount)
      9 -> Map.put(map, :sep, amount)
      10 -> Map.put(map, :oct, amount)
      11 -> Map.put(map, :nov, amount)
      12 -> Map.put(map, :dec, amount)
    end
  end

  def load_travelors_released_componenet(socket) do
    travelor_count = generate_travelors_released(Date.add(Date.utc_today, -7), Date.utc_today, [])
    |> Enum.reject(fn job -> job.total == 0 end)
    |> Enum.reverse
    |> Enum.take(5)

    travelor_totals = Enum.reduce(travelor_count, %{dave_total: 0, jamie_total: 0, brent_total: 0, greg_total: 0, caleb_total: 0, mike_total: 0, nolan_total: 0, total_total: 0}, fn t, acc->
      acc
      |> Map.put(:dave_total, acc.dave_total + t.dave)
      |> Map.put(:jamie_total, acc.jamie_total + t.jamie)
      |> Map.put(:brent_total, acc.brent_total + t.brent)
      |> Map.put(:greg_total, acc.greg_total + t.greg)
      |> Map.put(:caleb_total, acc.caleb_total + t.caleb)
      |> Map.put(:nolan_total, acc.nolan_total + t.nolan)
      |> Map.put(:mike_total, acc.mike_total + t.mike)
      |> Map.put(:total_total, acc.total_total + t.total)
    end)

    assign(socket, :travelor_count, travelor_count)
    |> assign(:travelor_totals, travelor_totals)
  end

  def generate_travelors_released(start_date, end_date, list \\ []) do
    if Date.after?(start_date, end_date) do
      list
    else
      released_jobs = Jobboss_db.released_jobs(start_date)
      totals_list = %{date: nil, caleb: 0, dave: 0, greg: 0, brent: 0, jamie: 0, mike: 0, nolan: 0, total: 0}
      job_totals =
        Enum.reduce(released_jobs, totals_list, fn job, acc ->
          acc = if acc.date == nil, do: Map.put(acc, :date, job.released_date), else: acc
          note_text = String.downcase(job.note_text)
          acc = Map.put(acc, :total, acc.total + 1)
          cond do
            String.contains?(note_text, "caleb") -> Map.put(acc, :caleb, acc.caleb + 1)
            String.contains?(note_text, "dave") -> Map.put(acc, :dave, acc.dave + 1)
            String.contains?(note_text, "greg") -> Map.put(acc, :greg, acc.greg + 1)
            String.contains?(note_text, "brent") -> Map.put(acc, :brent, acc.brent + 1)
            String.contains?(note_text, "jamie") -> Map.put(acc, :jamie, acc.jamie + 1)
            String.contains?(note_text, "mike") -> Map.put(acc, :mike, acc.mike + 1)
            String.contains?(note_text, "nolan") -> Map.put(acc, :nolan, acc.nolan + 1)
            true -> acc
          end
        end)
        generate_travelors_released(Date.add(start_date, 1), end_date, [job_totals | list])
      end
  end

  def load_hot_jobs(socket) do
    assign(socket, :hot_jobs, Shophawk.Shop.get_hot_jobs())
  end

  def load_yearly_sales_chart(socket, start_date, end_date) do
    matching_map = %{
      ["alro"] => "Alro Plastics",
      ["amcor"] => "Amcor",
      ["applied"] => "Applied",
      ["ball"] => "Ball Container",
      ["bdi"] => "BDI",
      ["bw - hunt"] => "BW Hunt Valley",
      ["bw - phill"] => "BW Phillips",
      ["bw convert"] => "BW Paper Converting",
      ["cope"] => "Cope",
      ["domtar"] => "Domtar",
      ["gates"] => "Gates",
      ["inter-wait", "inter-wauk"] => "Interstate Bearing",
      ["kaman"] => "Kaman",
      ["kraft"] => "Kraft",
      ["midland"] => "Midland Plastics",
      ["mo-", "motion"] => "Motion Industries",
      ["pcmc"] => "Paper Converting",
      ["premier"] => "Premier",
      ["psa"] => "Pneumatic Scale",
      ["quad"] => "Quad Graphics",
      ["rr don"] => "RR Donnelly",
      ["seneca"] => "Seneca Foods",
      ["stoughton"] => "Stoghton Trailers",
      ["sonoco"] => "Sonoco",
      ["stolle"] => "Stolle",
      ["tetra"] => "Tetra",
      ["trane"] => "Trane",
      ["tyson"] => "Tyson Foods",
      ["valmet"] => "Valmet"
    }
    deliveries_this_year = case Jobboss_db.load_invoices(start_date, end_date) do
      [] -> [] #if no deliveries found
      invoices -> invoices
    end
    |> Enum.group_by(&customer_key(&1, matching_map))
    |> Enum.map(fn {customer, sales_list} ->
      total_sales = Enum.reduce(sales_list, 0, fn map, acc -> map.orig_invoice_amt + acc end) |> Float.round(2)
      %{customer: customer, sales: total_sales}
    end)
    |> Enum.sort_by(&(&1.sales), :desc)
    top_ten_customers = Enum.take(deliveries_this_year, 10)
    rest_of_customers = Enum.reject(deliveries_this_year, fn c -> c.customer in Enum.map(top_ten_customers, &(&1.customer)) end)
    rest_of_customers_sales = Enum.reduce(rest_of_customers, 0, fn c, acc -> c.sales + acc end)
    total_sales = Enum.reduce(deliveries_this_year, 0, fn c, acc -> c.sales + acc end)
    yearly_sales_data =
      %{
        series: Enum.map(top_ten_customers, &(&1.sales)) ++ [rest_of_customers_sales],
        labels: Enum.map(top_ten_customers, &(&1.customer)) ++ ["All Customers Minus the Top 10"]
      }

    socket
    |> assign(:yearly_sales_data, Jason.encode!(yearly_sales_data))
    |> assign(:total_sales, total_sales)
    |> assign(:complete_yearly_sales_data, yearly_sales_data)
    |> assign(:top_10_startdate, start_date)
    |> assign(:top_10_enddate, end_date)
  end

  def load_top_vendors(socket, start_date, end_date) do
    payments = case Jobboss_db.load_vendor_payments(start_date, end_date) do
      [] -> [] #if no deliveries found
      checks -> checks
    end
    |> Enum.group_by(fn v -> v.vendor end)
    |> Enum.map(fn {vendor, sales_list} ->
      total_payments = Enum.reduce(sales_list, 0, fn map, acc -> map.check_amt + acc end) |> Float.round(2)
      %{vendor: vendor, payments: total_payments}
    end)
    |> Enum.sort_by(&(&1.payments), :desc)

    top_vendors = Enum.take(payments, 30)

    total_sales = Enum.reduce(payments, 0, fn c, acc -> c.payments + acc end)
    empty_vendor_list = if top_vendors == [], do: true, else: false

    socket
    |> assign(:top_vendors, top_vendors)
    |> assign(:top_vendors_startdate, start_date)
    |> assign(:top_vendors_enddate, end_date)
    |> assign(:total_payments, total_sales)
    |> assign(:empty_vendor_list, empty_vendor_list)
  end

  def load_late_shipments(socket) do
    runlists =
      Cachex.stream!(:active_jobs, Cachex.Query.build(output: :value))
      |> Enum.to_list
      |> Enum.map(fn job_data -> job_data.job_ops end)
      |> List.flatten

    late_deliveries = case Shophawk.Jobboss_db.load_late_deliveries() do
        [] -> [] #if no deliveries found
        deliveries ->
          Enum.reduce(deliveries, [], fn d, acc ->
            case Enum.find(runlists, fn op -> op.job == d.job end) do
              nil -> acc
              job ->
                if job.job_status == "Active" do
                  acc ++ [Map.merge(d, job)]
                else
                  acc
                end
            end
          end)
          |> Enum.sort_by(&(&1.promised_date), Date)
      end
      |> Enum.reject(fn op -> op.customer == "EDG GEAR" end)

    two_week_late_history =
      case Shophawk.Jobboss_db.load_late_delivery_history() do
        [] -> [] #if no deliveries found
        deliveries ->
          Enum.reduce(deliveries, [], fn d, acc ->
            case Enum.find(runlists, fn op -> op.job == d.job end) do
              nil -> acc
              job -> acc ++ [Map.merge(d, job)]
            end
          end)
          |> Enum.sort_by(&(&1.promised_date), Date)
      end
      |> Enum.reject(fn op -> op.customer == "EDG GEAR" end)

    assign(socket, :late_deliveries, late_deliveries)
    |> assign(:late_delivery_count, Enum.count(two_week_late_history) + Enum.count(late_deliveries))
    |> assign(:late_deliveries_loaded, true)
  end

  def load_time_off(socket) do
    weekly_dates = ShophawkWeb.SlideshowLive.Index.load_weekly_dates()
    {week1_timeoff, week2_timeoff} = ShophawkWeb.SlideshowLive.Index.load_timeoff(weekly_dates)

    assign(socket, :weekly_dates, weekly_dates)
    |> assign(:week1_timeoff, week1_timeoff)
    |> assign(:week2_timeoff, week2_timeoff)
  end

  @impl true
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

  def handle_event("add_yearly_sales_customer", _, socket) do
    complete_data = socket.assigns.complete_yearly_sales_data
    labels = Jason.decode!(socket.assigns.yearly_sales_data) |> Map.get("labels")
    series = Jason.decode!(socket.assigns.yearly_sales_data) |> Map.get("series")
    currently_shown_data = Jason.decode!(socket.assigns.yearly_sales_data) |> Map.get("labels") |> Enum.count

    updated_yearly_sales_data =
      case Enum.count(labels) do
        11  -> %{labels: labels, series: series}
        _ ->  %{
              labels: [Enum.at(Enum.reverse(complete_data.labels), currently_shown_data)] ++ labels,
              series: [Enum.at(Enum.reverse(complete_data.series), currently_shown_data)] ++ series
            }
        end

    send_update(ShophawkWeb.YearlySalesChartComponent, id: "yearly_sales_1", yearly_sales_data: Jason.encode!(updated_yearly_sales_data))

    {:noreply, assign(socket, :yearly_sales_data, Jason.encode!(updated_yearly_sales_data))}
  end

  def handle_event("subtract_yearly_sales_customer", _, socket) do
    labels = Jason.decode!(socket.assigns.yearly_sales_data) |> Map.get("labels")
    series = Jason.decode!(socket.assigns.yearly_sales_data) |> Map.get("series")
    updated_yearly_sales_data =
      case Enum.count(labels) do
        1 -> %{labels: labels, series: series}
        _ ->
          [_label_head | label_tail] = labels
          [_series_head | series_tail] = series
          %{labels: label_tail, series: series_tail}
      end
    send_update(ShophawkWeb.YearlySalesChartComponent, id: "yearly_sales_1", yearly_sales_data: Jason.encode!(updated_yearly_sales_data))
    {:noreply, assign(socket, :yearly_sales_data, Jason.encode!(updated_yearly_sales_data))}
  end

  def handle_event("clear_yearly_sales_customer", _, socket) do
    labels = Jason.decode!(socket.assigns.yearly_sales_data) |> Map.get("labels") |> List.last
    series = Jason.decode!(socket.assigns.yearly_sales_data) |> Map.get("series") |> List.last
    updated_yearly_sales_data =  %{labels: [labels], series: [series]}
    send_update(ShophawkWeb.YearlySalesChartComponent, id: "yearly_sales_1", yearly_sales_data: Jason.encode!(updated_yearly_sales_data))
    {:noreply, assign(socket, :yearly_sales_data, Jason.encode!(updated_yearly_sales_data))}
  end

  def handle_event("monthly_sales_toggle", _, socket) do
    {:noreply, assign(socket, :show_monthly_sales_table, !socket.assigns.show_monthly_sales_table)}
  end

  def handle_event("reload_top_10_dates", %{"end_date" => enddate, "start_date" => startdate}, socket) do
    {:noreply, load_yearly_sales_chart(socket, Date.from_iso8601!(startdate), Date.from_iso8601!(enddate))}
  end

  def handle_event("reload_top_vendor_dates", %{"end_date" => enddate, "start_date" => startdate}, socket) do
    {:noreply, load_top_vendors(socket, Date.from_iso8601!(startdate), Date.from_iso8601!(enddate))}
  end

  def handle_event("test_click", _params, socket) do
    beginning_of_this_month = Date.utc_today() |> Date.add(-30) |> Date.beginning_of_month()
    end_of_month = Date.utc_today() |> Date.add(-30) |> Date.end_of_month()
    generate_monthly_sales(beginning_of_this_month, end_of_month) |> List.first()


    ######################Functions to load history into db for first load with new dashboard####################
    #load_10_year_history_into_db()
    {:noreply, socket}
  end

  @spec customer_key(any(), any()) :: any()
  def customer_key(map, matching_map) do
    Enum.find(matching_map, fn {substrings, _group} ->
      Enum.any?(substrings, fn substring -> String.contains?(String.downcase(map.customer), substring) end)
    end)
    |> case do
      {_, group} -> group
      nil -> map.customer  # If no match is found, return the original customer name
    end
  end


  ############## Scheduled jobs to run via quantum ##########
  def save_last_months_sales() do
    today = Date.utc_today() |> Date.add(-2)
    beginning_of_last_month = today |> Date.beginning_of_month() |> Date.add(-1) |> Date.beginning_of_month()
    end_of_last_month = beginning_of_last_month |> Date.end_of_month()

    case Dashboard.list_monthly_sales(beginning_of_last_month) do
      [] ->
        # Generate and save last month's sales
        last_months_sales = generate_monthly_sales(beginning_of_last_month, end_of_last_month)
        case List.first(last_months_sales) do
          nil ->
            IO.puts("No sales data to save for last month.")
            :ok
          sales_data ->
            case Shophawk.Dashboard.create_monthly_sales(sales_data) do
              {:ok, _result} ->
                IO.puts("Monthly sales successfully saved.")
              {:error, reason} ->
                IO.puts("Failed to save monthly sales: #{inspect(reason)}")
            end
        end

      _existing_sales ->
        IO.puts("Monthly sales for last month already exist.")
        :ok
    end
  end

  def save_this_weeks_revenue() do
    beginning_of_week = Date.utc_today |> Date.beginning_of_week()
    case Dashboard.list_revenue(beginning_of_week) do
      [] ->
        {six_weeks_revenue, total_revenue, total_jobs} = calc_current_revenue()
        revenue_to_save = %{
          six_week_revenue: Float.round(six_weeks_revenue, 2),
          total_revenue: Float.round(total_revenue, 2),
          total_jobs: total_jobs,
          week: beginning_of_week
        }
        Shophawk.Dashboard.create_revenue(revenue_to_save)
      _ -> :ok
    end
    IO.puts("this week revenue saved")
  end

  ###############################################
    #Function to load history and save to DB
    def load_10_year_history_into_db() do
      #save_revenue_history() #10 years of revenue history
      save_monthly_sales(Date.add(Date.utc_today, -4015), Date.utc_today) #10 years of monthly sales history
    end

    def save_monthly_sales(start_date, end_date) do
      monthly_sales = generate_monthly_sales(start_date, end_date, [])
      Enum.each(monthly_sales, fn r -> Shophawk.Dashboard.create_monthly_sales(r) end)
    end

    def save_revenue_history() do
      revenue_history = generate_full_revenue_history(Date.beginning_of_week(~D[2014-01-06]), Date.add(Date.utc_today, 1))
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
