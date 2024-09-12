# lib/shophawk_web/live/dashboard_live/office.ex
defmodule ShophawkWeb.DashboardLive.ShopMeeting do
  use ShophawkWeb, :live_view
  alias ShophawkWeb.UserAuth
  alias ShophawkWeb.DashboardLive.Index # Import the helper functions from Index
  import Number.Currency
  alias ShophawkWeb.RevenueComponent
  alias ShophawkWeb.MonthlySalesChartComponent
  alias ShophawkWeb.TravelorcountComponent
  alias ShophawkWeb.HotjobsFullScreenComponent
  alias ShophawkWeb.WeekoneTimeoffComponent
  alias ShophawkWeb.WeektwoTimeoffComponent
  alias ShophawkWeb.YearlySalesChartComponent
  alias ShophawkWeb.LateShipmentsComponent


  def render(assigns) do
    ~H"""
      <div>
        <div class="grid grid-cols-2 place-content-center text-stone-100">

          <!-- Hot Jobs -->


      </div> <!-- end of grid -->



      <div class="grid grid-cols-1 place-content-center text-stone-100">

        <.live_component module={HotjobsFullScreenComponent} id="hot_jobs-1"
          hot_jobs={@hot_jobs}
          height={%{border: "h-[88vh]", frame: "h-[70%] 2xl:h-[94%]", style: "font-size: 1.25vw"}}
        />
        <br><br><br><br>

        <.live_component module={LateShipmentsComponent} id="late_shipments-1"
          late_deliveries={@late_deliveries}
          late_deliveries_loaded={@late_deliveries_loaded}
          late_delivery_count={@late_delivery_count}
          height={%{border: "h-[88vh]", frame: "h-[70%] 2xl:h-[94%]", style: "font-size: 1.25vw"}}
        />
        <br><br><br><br>

        <.live_component module={RevenueComponent} id="revenue-2"
        six_weeks_revenue_amount={@six_weeks_revenue_amount}
        total_revenue={@total_revenue}
        active_jobs={@active_jobs}
        revenue_chart_data={@revenue_chart_data}
        percentage_diff={@percentage_diff}
        />
      </div>
      <br><br><br><br>
      <div class="grid grid-cols-1 place-content-center text-stone-100">
        <.live_component module={MonthlySalesChartComponent} id="monthly_sales"
        sales_chart_data={@sales_chart_data}
        this_months_sales={@this_months_sales}
        this_years_sales={@this_years_sales}
        projected_yearly_sales={@projected_yearly_sales}
        show_monthly_sales_table={@show_monthly_sales_table}
        sales_table_data={@sales_table_data}
        monthly_average={@monthly_average}
        />
      </div>


      </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_data, [:noconnect])
    {:ok, set_default_assigns(socket)}
  end

  def set_default_assigns(socket) do
    socket =
      socket
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

          #late Deliveries
          |> assign(:late_deliveries, [])
          |> assign(:late_deliveries_loaded, false)
          |> assign(:late_delivery_count, 0)
  end

  def handle_info(:load_data, socket) do
    {:noreply,
      socket
      |> Index.load_hot_jobs()
      |> Index.load_late_shipments()
      |> Index.load_anticipated_revenue_component() #2 sec
      |> Index.load_monthly_sales_chart_component() #instant
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

  def handle_event("monthly_sales_toggle", _, socket) do
    {:noreply, assign(socket, :show_monthly_sales_table, !socket.assigns.show_monthly_sales_table)}
  end

end
