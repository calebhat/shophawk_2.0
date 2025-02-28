# lib/shophawk_web/live/dashboard_live/office.ex
defmodule ShophawkWeb.DashboardLive.EmployeePerformance do
  use ShophawkWeb, :live_view
  alias ShophawkWeb.UserAuth

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
            <!-- to order and receive buttons -->



            <div id="loading-content" class="loader" style={if !@loading, do: "display: none;"}>Loading...</div>
          </div>

        </div>
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
  def handle_event("load_employee_operation_history", %{"employee" => employee}, socket) do

    {:noreply, assign(socket, :selected_emp_initial, employee)}
  end

  def handle_event("reload_dates", %{"employee_initial" => employee_initial, "end_date" => enddate, "start_date" => startdate}, socket) do
    {:noreply, load_performance_for_dates(socket, employee_initial, Date.from_iso8601!(startdate), Date.from_iso8601!(enddate))}
  end

  def load_performance_for_dates(socket, employee_initial, startdate, enddate) do
    employee_entries =
      Shophawk.Jobboss_db.load_job_operation_time_by_employee(employee_initial, startdate, enddate)
      |> Enum.reduce([], fn e, acc ->
        case Enum.find(acc, fn a -> a.job_operation == e.job_operation end) do
          nil -> acc ++ [e]
          found ->
            Map.put(found, :act_run_labor_hrs, found.act_run_labor_hrs + e.act_run_labor_hrs)
            Enum.map(acc, fn a -> if found.job_operation == a.job_operation, do: found, else: a end)
        end
      end)
    IO.inspect(List.first(employee_entries))
    operation_numbers = Enum.map(employee_entries, fn e -> e.job_operation end) |> Enum.uniq()
    job_operations = Shophawk.Jobboss_db.load_job_operations(operation_numbers)
    IO.inspect(List.first(job_operations))

    socket
  end

end
