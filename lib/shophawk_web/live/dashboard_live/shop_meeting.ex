# lib/shophawk_web/live/dashboard_live/office.ex
defmodule ShophawkWeb.DashboardLive.ShopMeeting do
  use ShophawkWeb, :live_view
  alias ShophawkWeb.DashboardLive.Index # Import the helper functions from Index
  alias ShophawkWeb.RevenueComponent
  alias ShophawkWeb.MonthlySalesChartComponent
  alias ShophawkWeb.HotjobsFullScreenComponent
  alias ShophawkWeb.LateShipmentsComponent

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <div class="grid grid-cols-2 place-content-center text-stone-100">

          <!-- Hot Jobs -->


      </div> <!-- end of grid -->



      <div class="grid grid-cols-1 place-content-center text-stone-100">

        <.live_component module={HotjobsFullScreenComponent} id="hot_jobs-1"
          hot_jobs={@hot_jobs}
          height={%{border: "h-[88vh]", frame: "h-[85%] 2xl:h-[90%]", style: "font-size: 1.25vw"}}
          header_font_size="text-6xl"
        />
        <br><br><br><br>

        <.live_component module={LateShipmentsComponent} id="late_shipments-1"
          late_deliveries={@late_deliveries}
          late_deliveries_loaded={@late_deliveries_loaded}
          late_delivery_count={@late_delivery_count}
          height={%{border: "h-[88vh]", frame: "h-[85%] 2xl:h-[90%]", style: "font-size: 1.25vw"}}
          header_font_size="text-6xl"
        />
        <br><br><br><br>

        <.live_component module={RevenueComponent} id="revenue-2"
        six_weeks_revenue_amount={@six_weeks_revenue_amount}
        total_revenue={@total_revenue}
        active_jobs={@active_jobs}
        revenue_chart_data={@revenue_chart_data}
        percentage_diff={@percentage_diff}
        header_font_size="text-4xl"
        height={%{frame: "h-[84%] 2xl:h-[86%]"}}
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
        header_font_size="text-4xl"
        height={%{frame: "h-[75%] 2xl:h-[80%]"}}
        />
      </div>

      <.modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.patch(~p"/dashboard/shop_meeting")}>
      <.live_component
          module={ShophawkWeb.RunlistLive.ShowJob}
          id={@id || :show_job}
          job_ops={@job_ops}
          job_info={@job_info}
          title={@page_title}
          action={@live_action}
      />
      </.modal>

      <.modal :if={@live_action in [:job_attachments]} id="job-attachments-modal" show on_cancel={JS.push("show_job", value: %{job: @id})}>
      <.live_component
          module={ShophawkWeb.RunlistLive.JobAttachments}
          id={@id || :job_attachments}
          attachments={@attachments}
          title={@page_title}
          action={@live_action}
      />
      </.modal>


      </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Process.send(self(), :load_data, [:noconnect])
    {:ok, set_default_assigns(socket)}
  end

  def set_default_assigns(socket) do
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

  @impl true
  def handle_info(:load_data, socket) do
    {:noreply,
      socket
      |> Index.load_hot_jobs()
      |> Index.load_late_shipments()
      |> Index.load_anticipated_revenue_component() #2 sec
      |> Index.load_monthly_sales_chart_component() #instant
    }
  end

  def handle_info({:load_attachments, job}, socket) do
    :ets.insert(:job_attachments, {:data, Shophawk.Jobboss_db.export_attachments(job)})  # Store the data in ETS
    {:noreply, socket}
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

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("monthly_sales_toggle", _, socket) do
    {:noreply, assign(socket, :show_monthly_sales_table, !socket.assigns.show_monthly_sales_table)}
  end

  ###### Showjob and attachments downloads ########
  def handle_event("show_job", %{"job" => job}, socket) do
    #Process.send(self(), {:load_attachments, job}, [:noconnect]) #loads attachement and saves them now for faster UX
    socket = ShophawkWeb.RunlistLive.Index.showjob(socket, job)
    {:noreply, socket}
  end

  def handle_event("attachments", _, socket) do
    job = socket.assigns.id
    #[{:data, attachments}] = :ets.lookup(:job_attachments, :data)
    attachments = Shophawk.Jobboss_db.export_attachments(job)
    socket =
      socket
      |> assign(id: job)
      |> assign(attachments: attachments)
      |> assign(page_title: "Job #{job} attachments")
      |> assign(:live_action, :job_attachments)

    {:noreply, socket}
  end

  def handle_event("download", %{"file-path" => file_path}, socket) do
    {:noreply, push_event(socket, "trigger_file_download", %{"url" => "/download/#{URI.encode(file_path)}"})}
  end

  def handle_event("download", _params, socket) do
    {:noreply, socket |> assign(:not_found, "File not found")}
  end

  def handle_event("close_job_attachments", _params, socket) do
    {:noreply, assign(socket, live_action: :show_job)}
  end

end
