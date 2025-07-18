# lib/shophawk_web/live/dashboard_live/office.ex
defmodule ShophawkWeb.DashboardLive.Accounting do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJobLive.ShowJobMacroFunctions #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover
  alias ShophawkWeb.UserAuth
  alias ShophawkWeb.DashboardLive.Index # Import the helper functions from Index
  alias ShophawkWeb.CheckbookComponent
  alias ShophawkWeb.InvoicesComponent

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user} />
        <div class="px-4 py-4 sm:px-6 lg:px-8">
          <div class="grid grid-cols-1 place-content-center text-stone-100">

            <!-- open invoices -->
            <.live_component module={InvoicesComponent} id="invoices-1"
              open_invoices={@open_invoices}
              selected_range={@selected_range}
              open_invoice_values={@open_invoice_values}
              height={%{border: "h-[800px]", frame: "h-[88%]", content: "h-[68vh]"}}
              expanded_invoices={@expanded_invoices || []}
            />

            <!-- Checkbook Balance/tx's -->
            <.live_component module={CheckbookComponent} id="checkbook-1"
              current_balance={@current_balance}
              checkbook_entries={@checkbook_entries}
              height={%{border: "h-[800px]", frame: "h-[78vh]"}}
            />



          </div>
        </div>

        <.modal :if={@live_action in [:add_comment]} id="add-comment-modal" show on_cancel={JS.patch("/dashboard/accounting")}>
          <.live_component
            module={ShophawkWeb.InvoiceCommentcomponent}
            id={@document_to_add_comment}
            title={@page_title}
            action={@live_action}
            document={@document_to_add_comment}
          />
        </.modal>

        <.showjob_modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.patch(~p"/dashboard/accounting")}>
          <.live_component
              module={ShophawkWeb.ShowJobLive.ShowJob}
              id={@id || :show_job}
              job_ops={@job_ops}
              job_info={@job_info}
              title={@page_title}
              action={@live_action}
              current_user={@current_user}
              expanded={@expanded || []}
          />
        </.showjob_modal>

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
    |> assign(:open_invoices, [])
    |> assign(:selected_range, "")
    |> assign(:open_invoice_values, [])
    |> assign_new(:expanded_invoices, fn -> [] end)
    |> assign(:page_title, "Accounting")
  end

  @impl true
  def handle_info(:load_data, socket) do
    {:noreply,
      socket
      |> Index.load_checkbook_component()
      |> Index.load_open_invoices_component()
    }
  end

  def handle_info({ShophawkWeb.InvoiceCommentcomponent, {:saved, invoice_comment}}, socket) do
    updated_open_invoices =
      Enum.map(socket.assigns.open_invoices, fn invoice ->
        case invoice.document == invoice_comment.invoice do
          false -> invoice
          true -> merge_invoice_comment(invoice, invoice_comment)
        end
      end)

    socket =
      socket
      |> assign(:page_title, "Accounting")
      |> assign(:open_invoices, updated_open_invoices)

    {:noreply, socket}
  end

  def merge_invoice_comment(invoice, comment_struct) do
    existing_comments = if Map.has_key?(invoice, :comments), do: invoice.comments, else: []
    merged_comments =
      [comment_struct | existing_comments]
      |> Enum.sort_by(&(&1.inserted_at), :desc)

   Map.put(invoice, :comments, merged_comments)
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

  def handle_event("toggle_invoice_expand", %{"op-id" => op_id}, socket) do
    expanded = socket.assigns.expanded_invoices
    updated_expanded_list =
      case op_id in expanded do
        true -> List.delete(expanded, op_id)
        false -> [op_id | expanded]
      end
    {:noreply, assign(socket, :expanded_invoices, updated_expanded_list)}
  end

  def handle_event("create_comment", %{"document" => document}, socket) do
    socket =
      socket
      |> assign(:document_to_add_comment, document)
      |> assign(:page_title, "Add Comment")
      |> assign(:live_action, :add_comment)
    {:noreply, socket}
  end

  def handle_event("delete_comment", %{"id" => id}, socket) do
    comment = Shophawk.Dashboard.get_invoice_comment(id)
    {:ok, _} = Shophawk.Dashboard.delete_invoice_comment(comment)
    invoices_with_removed_comment =
      Enum.map(socket.assigns.open_invoices, fn inv ->
        case Map.has_key?(inv, :comments) do
          true -> Map.put(inv, :comments, List.delete(inv.comments, comment))
          false -> inv
        end
      end)
    {:noreply, assign(socket, :open_invoices, invoices_with_removed_comment)}
  end

  def handle_event("edit_comment", %{"id" => id}, socket) do

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

end
