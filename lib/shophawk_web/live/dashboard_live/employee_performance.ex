# lib/shophawk_web/live/dashboard_live/office.ex
defmodule ShophawkWeb.DashboardLive.EmployeePerformance do
  use ShophawkWeb, :live_view
  alias ShophawkWeb.UserAuth

  @impl true
  def render(assigns) do
    ~H"""
      <div class="relative"  style="z-index: 8">

        <!-- material column -->
        <div class="bg-cyan-900 fixed rounded-t inset-0 top-[5.71rem] left-4 right-auto w-[12rem] pb-2 pt-2 px-2 overflow-y-auto">
          <!-- <div><.button class="" phx-click="test">Reload material</.button></div> -->
          <%= for employee <- @employees do %>
            <div
              class="flex justify-between items-center rounded m-1 mr-6 p-1 bg-stone-200 hover:cursor-pointer w-[8rem]"
              phx-click="load_employee_operation_history"
              phx-value-employee={employee.employee}
            >
            <%= employee.first_name %> <%= employee.last_name %>
            </div>
          <% end %>

        </div>

        <!-- Primary Center block -->
        <div class="bg-cyan-900 fixed rounded-t inset-0 ml-[17rem] top-[5.71rem] right-[2vw] left-[2vw]">
          <div>
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
  end

  @impl true
  def handle_info(:load_data, socket) do
    shop_employees =
      Shophawk.Jobboss_db.load_employees()
      |> Enum.filter(fn s-> s.department not in ["CustomerService", "Other Labor", "Accounting"] end)
    |> IO.inspect
    {:noreply, assign(socket, :employees, shop_employees)}
  end

  @impl true
  def handle_event("load_employee_operation_history", %{"employee" => _employee}, socket) do

    {:noreply, socket}
  end

end
