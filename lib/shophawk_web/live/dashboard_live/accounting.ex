# lib/shophawk_web/live/dashboard_live/office.ex
defmodule ShophawkWeb.DashboardLive.Accounting do
  use ShophawkWeb, :live_view
  alias ShophawkWeb.UserAuth
  alias ShophawkWeb.DashboardLive.Index # Import the helper functions from Index
  alias ShophawkWeb.CheckbookComponent
  alias ShophawkWeb.InvoicesComponent

  @impl true
  def render(assigns) do
    ~H"""
      <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user} />
      <div class="px-4 py-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-2 place-content-center text-stone-100">

            <!-- Checkbook Balance/tx's -->
            <.live_component module={CheckbookComponent} id="checkbook-1"
            current_balance={@current_balance}
            checkbook_entries={@checkbook_entries}
            height={%{border: "h-[88vh]", frame: "h-[70%] 2xl:h-[94%]"}}
            />


            <!-- open invoices -->
            <.live_component module={InvoicesComponent} id="invoices-1"
            open_invoices={@open_invoices}
            selected_range={@selected_range}
            open_invoice_values={@open_invoice_values}
            height={%{border: "h-[88vh]", frame: "h-[70%] 2xl:h-[88%]", content: "h-[60%] 2xl:h-[68vh]"}}
            />
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
    #Checkbook
    |> assign(:checkbook_entries, [])
    |> assign(:current_balance, "Loading...")
    #Invoices
    |> assign(:open_invoices, %{})
    |> assign(:selected_range, "")
    |> assign(:open_invoice_values, [])
  end

  @impl true
  def handle_info(:load_data, socket) do
    {:noreply,
      socket
      |> Index.load_checkbook_component()
      |> Index.load_open_invoices_component()
    }
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

end
