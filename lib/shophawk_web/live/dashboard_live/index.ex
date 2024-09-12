defmodule ShophawkWeb.DashboardLive.Index do
  use ShophawkWeb, :live_view
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
    socket =
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
      |> assign(:yearly_sales_loading, false)
      |> assign(:yearly_sales_data, [])
      |> assign(:total_sales, 0)
      |> assign(:complete_yearly_sales_data, [])

      #late Deliveries
      |> assign(:late_deliveries, [])
      |> assign(:late_delivery_count, 0)
      |> assign(:late_deliveries_loaded, false)
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
      |> load_checkbook_component() #5 seconds
      |> load_open_invoices_component() #5 sec
      |> load_travelors_released_componenet() #1 second
      |> load_anticipated_revenue_component() #2 sec
      |> load_monthly_sales_chart_component() #instant
      |> load_hot_jobs()
      |> load_time_off()
      |> load_late_shipments()
    }
  end

  def handle_info({ref, result}, socket) do #load chart data once complete
    if socket.assigns.task.ref == ref do
      # Update the socket with the result of the task and stop loading
      socket =
        socket
        |> assign(:yearly_sales_data, result.yearly_sales_data)
        |> assign(:total_sales, result.total_sales)
        |> assign(:complete_yearly_sales_data, result.complete_yearly_sales_data)
        |> assign(:yearly_sales_loading, false)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
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
    socket = calc_current_revenue(socket, data)
  end
  def calc_current_revenue(socket, data) do
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

    percentage_diff =
      (1- (Enum.at(data, 1).six_week_revenue / six_weeks_revenue_amount)) * 100
      |> Float.round(2)
      |> Number.Percentage.number_to_percentage(precision: 2)

    socket
    |> assign(:six_weeks_revenue_amount, six_weeks_revenue_amount)
    |> assign(:total_revenue, total_revenue)
    |> assign(:active_jobs, Enum.count(jobs))
    |> assign(:percentage_diff, percentage_diff)
  end

  def load_monthly_sales_chart_component(socket) do
    beginning_of_this_month = Date.beginning_of_month(Date.utc_today())
    current_months_sales = generate_monthly_sales(beginning_of_this_month, Date.add(Date.utc_today, 1)) |> List.first()
    sales_table_data =
      Dashboard.list_monthly_sales
      |> Enum.map(fn op ->
        map =
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
    # Combine existing data with all months, preferring existing data
    final_sales_table_data =
      ([%{date: beginning_of_this_month, amount: current_months_sales.amount} | sales_table_data] ++ all_months)
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
    min_amount = Enum.min_by(sales_table_data, fn m -> m.amount end)
    sales_chart_data =
      if current_months_sales.amount > min_amount do
        case Enum.find(sales_table_data, fn month -> month.date == beginning_of_this_month end) do
          nil -> [%{date: beginning_of_this_month, amount: current_months_sales.amount} | sales_table_data]
          found_month -> Map.put(found_month, :amount, current_months_sales.amount)
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
      |> assign(:sales_table_data, final_sales_table_data)
      |> assign(:this_months_sales, current_months_sales.amount)
      |> assign(:this_years_sales, this_years_sales + current_months_sales.amount)
      |> assign(:projected_yearly_sales, (this_years_sales / Date.utc_today().month) * 12)
      |> assign(:monthly_average, monthly_average)
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
    weekday_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    travelor_count = generate_travelors_released(Date.add(Date.utc_today, -7), Date.utc_today, [])
    |> Enum.reject(fn job -> job.total == 0 end)
    |> Enum.reverse
    |> Enum.take(5)

    travelor_totals = Enum.reduce(travelor_count, %{dave_total: 0, jamie_total: 0, brent_total: 0, greg_total: 0, caleb_total: 0, mike_total: 0, total_total: 0}, fn t, acc->
      acc
      |> Map.put(:dave_total, acc.dave_total + t.dave)
      |> Map.put(:jamie_total, acc.jamie_total + t.jamie)
      |> Map.put(:brent_total, acc.brent_total + t.brent)
      |> Map.put(:greg_total, acc.greg_total + t.greg)
      |> Map.put(:caleb_total, acc.caleb_total + t.caleb)
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
      totals_list = %{date: nil, caleb: 0, dave: 0, greg: 0, brent: 0, jamie: 0, mike: 0, total: 0}
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
            true -> acc
          end
        end)
        generate_travelors_released(Date.add(start_date, 1), end_date, [job_totals | list])
      end
  end

  def load_hot_jobs(socket) do
    assign(socket, :hot_jobs, Shophawk.Shop.get_hot_jobs())
  end

  def load_yearly_sales_chart() do
    first_day_of_year = Date.new!(Date.utc_today().year, 1, 1)
    matching_map = %{
      ["alro"] => "Alro Plastics",
      ["amcor"] => "Amcor",
      ["applied"] => "Applied",
      ["ball"] => "Ball Container",
      ["bdi"] => "BDI",
      ["bw"] => "BW Papersystems",
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
    deliveries_this_year = case Jobboss_db.load_deliveries(~D[2024-08-01], Date.utc_today()) do
    #deliveries_this_year = case Jobboss_db.load_deliveries(first_day_of_year, Date.utc_today()) do
      [] -> [] #if no deliveries found
      deliveries ->
        jobs =
          Enum.chunk_every(deliveries, 1000)
          |> Enum.map(fn chunk ->
            Enum.map(chunk, fn d -> d.job end)
            |> Jobboss_db.load_delivery_jobs()
          end)
          |> List.flatten()
        addresses =
          Enum.chunk_every(jobs, 1000)
          |> Enum.map(fn chunk ->
            Enum.map(chunk, fn d -> d.ship_to end)
            |> Jobboss_db.load_addresses()
          end)
          |> List.flatten()
          |> Enum.uniq
        updated_jobs =
          Enum.reduce(jobs, [], fn job, acc ->
            address =
              case job.customer do
                "EDG GEAR" ->
                  ad = Enum.find(addresses, fn ad -> ad.address == job.ship_to end)
                  case ad.name do
                    "MARQUIP WARD UNITED" -> %{customer: "bw"}
                    _ -> %{}
                  end
                _ -> %{}
              end
            acc ++ [Map.merge(job, address)]
          end)
        Enum.reduce(deliveries, [], fn d, acc ->
          job = Enum.find(updated_jobs, fn job -> job.job == d.job end)

          acc ++ [Map.merge(d, job)]
        end)
        |> Enum.sort_by(&(&1.promised_date), Date)
    end
    |> Enum.group_by(&customer_key(&1, matching_map))
    |> Enum.map(fn {customer, sales_list} ->
      total_sales = Enum.reduce(sales_list, 0, fn map, acc -> (map.unit_price * map.promised_quantity) + acc end)
      %{customer: customer, sales: Float.round(total_sales, 2)}
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
    %{yearly_sales_data: Jason.encode!(yearly_sales_data), total_sales: total_sales, complete_yearly_sales_data: yearly_sales_data}
  end

  def load_late_shipments(socket) do
    runlists =
      case :ets.lookup(:runlist, :active_jobs) do
        [{:active_jobs, runlists}] -> Enum.reverse(runlists)
        [] -> []
      end
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
      IO.inspect(Enum.count(two_week_late_history))

    assign(socket, :late_deliveries, late_deliveries)
    |> assign(:late_delivery_count, Enum.count(two_week_late_history))
    |> assign(:late_deliveries_loaded, true)
  end

  def load_time_off(socket) do
    weekly_dates = ShophawkWeb.SlideshowLive.Index.load_weekly_dates()
    {week1_timeoff, week2_timeoff} = ShophawkWeb.SlideshowLive.Index.load_timeoff(weekly_dates)

    socket =
      assign(socket, :weekly_dates, weekly_dates)
      |> assign(:week1_timeoff, week1_timeoff)
      |> assign(:week2_timeoff, week2_timeoff)
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

  def handle_event("load_yearly_sales_customer", _, socket) do
    task = Task.async(fn -> load_yearly_sales_chart() end)
    {:noreply, assign(socket, :task, task) |> assign(:yearly_sales_loading, true)}
  end

  def handle_event("monthly_sales_toggle", _, socket) do
    {:noreply, assign(socket, :show_monthly_sales_table, !socket.assigns.show_monthly_sales_table)}
  end

  def handle_event("test_click", _params, socket) do

    #socket = load_yearly_sales_chart(socket)



    #socket =
    #  assign(socket, :yearly_sales_data, Jason.encode!(empty_yearly_sales_data))
    #  |> assign(:complete_yearly_sales_data, yearly_sales_data)
    #Jobboss_db.load_addresses(addresses)




    ######################Functions to load history into db for first load with new dashboard####################
    #load_10_year_history_into_db()
    {:noreply, socket}
  end
  def customer_key(map, matching_map) do
    Enum.find(matching_map, fn {substrings, _group} ->
      Enum.any?(substrings, fn substring -> String.contains?(String.downcase(map.customer), substring) end)
    end)
    |> case do
      {_, group} -> group
      nil -> map.customer  # If no match is found, return the original customer name
    end
  end




  ###############################################
    #Function to load history and save to DB
    def load_10_year_history_into_db() do
      save_revenue_history() #10 years of revenue history
      save_monthly_sales(Date.add(Date.utc_today, -4015), Date.utc_today) #10 years of monthly sales history
    end

    def save_monthly_sales(start_date, end_date) do
      monthly_sales = generate_monthly_sales(start_date, end_date, [])
      Enum.each(monthly_sales, fn r -> Shophawk.Dashboard.create_monthly_sales(r) end)
    end

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
