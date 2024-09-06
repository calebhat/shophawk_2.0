# lib/shophawk_web/live/dashboard_live/office.ex
defmodule ShophawkWeb.DashboardLive.Office do
  use ShophawkWeb, :live_view
  alias ShophawkWeb.DashboardLive.Index # Import the helper functions from Index
  import Number.Currency
  alias ShophawkWeb.RevenueComponent
  alias ShophawkWeb.MonthlySalesChartComponent
  alias ShophawkWeb.TravelorcountComponent
  alias ShophawkWeb.HotjobsComponent
  alias ShophawkWeb.WeekoneTimeoffComponent
  alias ShophawkWeb.WeektwoTimeoffComponent
  alias ShophawkWeb.YearlySalesChartComponent


  def render(assigns) do
    ~H"""
      <div>
        <div class="grid grid-cols-2 place-content-center text-stone-100">

            <!-- Travelor Count -->
          <.live_component module={TravelorcountComponent} id="travelor_count-1"
          travelor_count={@travelor_count}
          travelor_totals={@travelor_totals}
          />

          <!-- Hot Jobs -->
          <.live_component module={HotjobsComponent} id="hot_jobs-1"
          hot_jobs={@hot_jobs}
          />

          <!-- Hot Jobs -->
          <.live_component module={WeekoneTimeoffComponent} id="weekonetimeoff-1"
          weekly_dates={@weekly_dates}
          week1_timeoff={@week1_timeoff}
          />

          <!-- Hot Jobs -->
          <.live_component module={WeektwoTimeoffComponent} id="weektwotimeoff-1"
          weekly_dates={@weekly_dates}
          week2_timeoff={@week2_timeoff}
          />
      </div> <!-- end of grid -->

      <div class="grid grid-cols-1 place-content-center text-stone-100">
          <.live_component module={MonthlySalesChartComponent} id="monthly_sales"
          sales_chart_data={@sales_chart_data}
          this_months_sales={@this_months_sales}
          this_years_sales={@this_years_sales}
          projected_yearly_sales={@projected_yearly_sales}
          />
      </div>

      <div class="grid grid-cols-1 place-content-center text-stone-100">
          <.live_component module={RevenueComponent} id="revenue-2"
          six_weeks_revenue_amount={@six_weeks_revenue_amount}
          total_revenue={@total_revenue}
          active_jobs={@active_jobs}
          revenue_chart_data={@revenue_chart_data}
          />
      </div>

      <div class="grid grid-cols-1 place-content-center text-stone-100">
          <.live_component module={YearlySalesChartComponent} id="yearly_sales_1"
          yearly_sales_loading={@yearly_sales_loading}
          yearly_sales_data={@yearly_sales_data}
          complete_yearly_sales_data={@complete_yearly_sales_data}
          total_sales={@total_sales}
          />
      </div>
      </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_data, [:noconnect])
    {:ok,
      socket
      #anticated revenue
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
    }
  end

  def handle_info(:load_data, socket) do
    {:noreply,
      socket

      |> Index.load_travelors_released_componenet() #1 second
      |> Index.load_anticipated_revenue_component() #2 sec
      |> Index.load_monthly_sales_chart_component() #instant
      |> Index.load_hot_jobs()
      |> Index.load_time_off()
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

  def handle_event("add_yearly_sales_customer", _, socket) do
    complete_data = socket.assigns.complete_yearly_sales_data |> IO.inspect
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
    task = Task.async(fn -> Index.load_yearly_sales_chart() end)
    {:noreply, assign(socket, :task, task) |> assign(:yearly_sales_loading, true)}
  end

end
