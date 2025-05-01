# lib/shophawk_web/live/dashboard_live/office.ex
defmodule ShophawkWeb.DashboardLive.EmployeePerformance do
  use ShophawkWeb, :live_view
  alias ShophawkWeb.UserAuth

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def render(assigns) do
    ~H"""
      <div class="relative"  style="z-index: 8">

        <!-- material column -->
        <div class="bg-cyan-900 fixed rounded-t inset-0 top-[5.71rem] left-4 right-auto w-[13.5rem] pb-2 pt-2 px-2 overflow-y-auto"
        style="scrollbar-width: none; -ms-overfloow-style: none;">
          <!-- <div><.button class="" phx-click="test">Reload material</.button></div> -->
          <%= for employee <- @employees do %>
            <div
              class={["flex justify-between items-center rounded m-1 mr-6 p-1 hover:cursor-pointer w-[12rem]",
              (if employee.employee == @selected_emp_initial, do: "bg-cyan-500 ml-2", else: "bg-stone-200")
              ]}
              phx-click="load_employee_operation_history"
              phx-value-employee={employee.employee}
            >
            <%= employee.first_name %> <%= employee.last_name %>
            </div>
          <% end %>

        </div>
        <!--
        <div class="bg-cyan-900 fixed rounded-t inset-0 top-[5.71rem] left-[12.6rem] right-auto w-[2rem] pb-2 pt-2 overflow-y-auto">



        </div>
        -->
        <!-- Primary Center block -->
        <div class="bg-cyan-900 fixed rounded-t inset-0 ml-[17rem] top-[5.71rem] right-[2vw] left-[2vw]">
          <div>

            <div class="">
              <.form for={%{}} as={:dates} phx-submit="reload_dates">
                <div class="flex justify-center text-white">
                  <div class="text-xl self-center mx-4">Start:</div>
                  <.input type="date" name="start_date" value={@performance_startdate} />
                  <div class="text-xl self-center mx-4">End:</div>
                  <.input type="date" name="end_date" value={@performance_enddate} />
                  <div class="hidden">
                  <.input type="text" name="employee_initial" value={@selected_emp_initial}  />
                  </div>
                  <.button class="mx-4 mt-2" type="submit">Reload</.button>
                </div>
              </.form>
            </div>
            <%= if @operations != [] do %>
            <div class="text-white text-bold text-lg mx-6">
              Average Job Efficiency: <%= @total_efficiency %>%
            </div>
            <div class="text-white text-bold text-lg mx-6">
              Average hours logged per day: <%= @average_hours_logged_per_day %>
            </div>

            <br>
            <div class="grid grid-cols-[repeat(auto-fit,minmax(200px,1fr))] gap-2 ml-6 mr-2 pr-4 max-h-[45rem] overflow-y-auto">
              <%= for op <- @operations do %>
                <div
                  class={["flex justify-between items-center rounded p-1 hover:cursor-pointer",
                          (set_operation_color(op.efficiency_percentage))]}
                          phx-click="show_job" phx-value-job={op.job}
                  phx-value-employee={op.employee}
                >
                  <%= op.job %>-<%= op.job_operation %>-<%= op.efficiency_percentage %>%
                </div>
              <% end %>
            </div>
            <% end %>



            <div id="loading-content" class="loader" style={if !@loading, do: "display: none;"}>Loading...</div>
          </div>

        </div>

        <.modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.patch(~p"/dashboard/employee_performance")}>
          <.live_component
              module={ShophawkWeb.RunlistLive.ShowJob}
              id={@id || :show_job}
              job_ops={@job_ops}
              job_info={@job_info}
              title={@page_title}
              action={@live_action}
              current_user={@current_user}
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
    case UserAuth.ensure_admin_access(socket.assigns.current_user.email) do
      :ok -> #if correct user is logged in.
        Process.send(self(), :load_data, [:noconnect])
        {:ok, set_default_assigns(socket)}
      {:error, message} ->
        {:ok,
          socket
          |> put_flash(:error, message)
          |> redirect(to: "/")}
    end
  end

  def set_default_assigns(socket) do
    socket
    |> assign(:loading, false)
    |> assign(:employees, [])
    |> assign(:selected_emp_initial, "")

    |> assign(:performance_startdate, Date.new!(Date.utc_today().year, 1, 1))
    |> assign(:performance_enddate, Date.utc_today())

    |> assign(:operations, [])
    |> assign(:total_efficiency, 0.0)
    |> assign(:average_hours_logged_per_day, 0.0)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, "Dashboard")}
  end

  @impl true
  def handle_info(:load_data, socket) do
    shop_employees =
      Shophawk.Jobboss_db.load_employees()
      |> Enum.filter(fn s-> s.department not in ["CustomerService", "Other Labor", "Accounting"] end)
    #|> IO.inspect
    {:noreply, assign(socket, :employees, shop_employees)}
  end

  @impl true
  def handle_event("load_employee_operation_history", %{"employee" => employee_initial}, socket) do

    {:noreply,
    socket
    |> assign(:selected_emp_initial, employee_initial)
    |> load_performance_for_dates(employee_initial, socket.assigns.performance_startdate, socket.assigns.performance_enddate)
    }
  end

  def handle_event("reload_dates", %{"employee_initial" => employee_initial, "end_date" => enddate, "start_date" => startdate}, socket) do
    {:noreply, load_performance_for_dates(socket, employee_initial, Date.from_iso8601!(startdate), Date.from_iso8601!(enddate))}
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
  #####

  def load_performance_for_dates(socket, employee_initial, startdate, enddate) do
    employee_entries = Shophawk.Jobboss_db.load_job_operation_time_by_employee(employee_initial, startdate, enddate)
    average_hours_logged_per_day =
      case employee_entries do
        [] -> 0.0
        _ -> calc_average_hours_logged_per_day(employee_entries)
      end

    #Filter out job operations with more than one employee logging time to make performance % accurate.
    job_operations_without_other_employee_time_entered =
      Enum.map(employee_entries, fn e -> e.job_operation end)
      |> Enum.uniq()
      |> Shophawk.Jobboss_db.load_job_operation_employee_time()
      |> Enum.group_by(&{&1.job_operation})
      |> Enum.reduce([], fn {{key}, maps}, acc ->
        first_employee = List.first(maps).employee
        case Enum.all?(maps, &(&1.employee == first_employee)) do
          true -> acc ++ [key]
          _ -> acc
        end
      end)

    filtered_employee_entries = Enum.filter(employee_entries, fn e -> e.job_operation in job_operations_without_other_employee_time_entered end)

    aggregated_entries = Enum.reduce(filtered_employee_entries, [], fn e, acc ->
        case Enum.find(acc, fn a -> a.job_operation == e.job_operation end) do
          nil -> acc ++ [e]
          found ->
            updated_map =
              Map.put(found, :act_run_labor_hrs, Float.round((found.act_run_labor_hrs + e.act_run_labor_hrs), 2))
              |> Map.put(:act_run_qty, Float.round((found.act_run_qty + e.act_run_qty), 2))
              |> Map.put(:act_scrap_qty, Float.round((found.act_scrap_qty + e.act_scrap_qty), 2))
            updated_acc = Enum.reject(acc, fn e -> e.job_operation == found.job_operation end)
            updated_acc ++ [updated_map]
            #Enum.map(acc, fn a -> if found.job_operation == a.job_operation, do: found, else: a end)
        end
      end)
      |> Enum.reject(fn a -> a.act_run_labor_hrs <= 0.001 end)

    operation_numbers = Enum.map(aggregated_entries, fn e -> e.job_operation end) |> Enum.uniq()
    job_operations = Shophawk.Jobboss_db.load_job_operations(operation_numbers)
    merged_entries =
      Enum.map(aggregated_entries, fn a ->
        case Enum.find(job_operations, fn j -> j.job_operation == a.job_operation end) do
          nil -> a
          found ->
            total_efficiency =
              ((found.est_total_hrs / a.act_run_labor_hrs) * 100)
              |> Float.round(2)
            Map.put(a, :est_total_hrs, found.est_total_hrs)
            |> Map.put(:wc_vendor, found.wc_vendor)
            |> Map.put(:job, found.job)
            |> Map.put(:efficiency_percentage, total_efficiency)
        end
      end)
      |> Enum.reject(fn a -> a.est_total_hrs <= 0.001 end)
      |> Enum.reject(fn a -> a.act_run_labor_hrs <= 0.01 end)
      |> Enum.sort_by(&(&1.efficiency_percentage))
    total_efficiency =
      case Enum.count(merged_entries) do
        0 -> "N/A"
        _ -> Enum.reduce(merged_entries, 0, fn m, acc -> m.efficiency_percentage + acc end) / Enum.count(merged_entries) |> Float.round(2)
      end


    #IO.inspect(List.first(merged_entries))
    #Example of ending map
    #%{
    #  employee: "BS",
    #  job_operation: 803094,
    #  act_run_labor_hrs: 10.0,
    #  act_run_qty: 5.0,
    #  act_scrap_qty: 0.0,
    #  est_total_hrs: 13.0,
    #  wc_vendor: "L 600",
    #  job: "137355",
    #  work_date: ~N[2025-01-02 00:00:00],
    #  last_updated: ~N[2025-01-02 11:25:43],
    #  efficiency_percentage: 1.3
    #}
    socket
    |> assign(:operations, merged_entries)
    |> assign(:total_efficiency, total_efficiency)
    |> assign(:average_hours_logged_per_day, average_hours_logged_per_day)
  end

  def calc_average_hours_logged_per_day(entries) do
    grouped_entries_by_date = Enum.group_by(entries, &{&1.work_date})
    total_hours_logged =
      Enum.map(grouped_entries_by_date, fn {_date, op_list} ->
        Enum.reduce(op_list, 0.0, fn op, acc -> op.act_run_labor_hrs + acc end)
      end)
      |> Enum.sum()

    Float.round((total_hours_logged / Enum.count(grouped_entries_by_date)), 2)
  end

  def set_operation_color(performance) do
    cond do
      performance < 20.0 -> "bg-red-800"
      performance >= 20.0 and performance < 30.0 -> "bg-red-700"
      performance >= 30.0 and performance < 40.0 -> "bg-red-600"
      performance >= 40.0 and performance < 50.0 -> "bg-red-500"
      performance >= 50.0 and performance < 60.0 -> "bg-red-400"
      performance >= 60.0 and performance < 80.0 -> "bg-red-300"
      performance >= 70.0 and performance < 80.0 -> "bg-red-200"
      performance >= 80.0 and performance < 90.0 -> "bg-red-100"
      performance >= 90.0 and performance <= 110.0 -> "bg-white"
      performance > 110.0 and performance <= 120.0 -> "bg-green-100"
      performance > 120.0 and performance <= 130.0 -> "bg-green-200"
      performance > 130.0 and performance <= 140.0 -> "bg-green-300"
      performance > 140.0 and performance <= 150.0 -> "bg-green-400"
      performance > 150.0 and performance <= 160.0 -> "bg-green-500"
      performance > 160.0 and performance <= 170.0 -> "bg-green-600"
      performance > 170.0 and performance <= 180.0 -> "bg-green-600"
      performance > 180.0 -> "bg-green-600"
      true -> "bg-white"
    end
  end

end
