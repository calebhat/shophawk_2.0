defmodule ShophawkWeb.RunlistLive.FormComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Shop

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage runlist records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="runlist-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:job]} type="text" label="Job" />
        <.input field={@form[:job_operation]} type="number" label="Job operation" />
        <.input field={@form[:wc_vendor]} type="text" label="Wc vendor" />
        <.input field={@form[:operation_service]} type="text" label="Operation service" />
        <.input field={@form[:vendor]} type="text" label="Vendor" />
        <.input field={@form[:sched_start]} type="date" label="Sched start" />
        <.input field={@form[:sched_end]} type="date" label="Sched end" />
        <.input field={@form[:sequence]} type="number" label="Sequence" />
        <.input field={@form[:customer]} type="text" label="Customer" />
        <.input field={@form[:order_date]} type="date" label="Order date" />
        <.input field={@form[:part_number]} type="text" label="Part number" />
        <.input field={@form[:rev]} type="text" label="Rev" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:order_quantity]} type="number" label="Order quantity" />
        <.input field={@form[:extra_quantity]} type="number" label="Extra quantity" />
        <.input field={@form[:pick_quantity]} type="number" label="Pick quantity" />
        <.input field={@form[:make_quantity]} type="number" label="Make quantity" />
        <.input field={@form[:open_operations]} type="number" label="Open operations" />
        <.input field={@form[:complete_operations]} type="number" label="Complete operations" />
        <.input field={@form[:shipped_quantity]} type="number" label="Shipped quantity" />
        <.input field={@form[:customer_po]} type="text" label="Customer po" />
        <.input field={@form[:customer_po_line]} type="number" label="Customer po line" />
        <.input field={@form[:job_sched_end]} type="date" label="Job sched end" />
        <.input field={@form[:job_sched_start]} type="date" label="Job sched start" />
        <.input field={@form[:note_text]} type="text" label="Note text" />
        <.input field={@form[:released_date]} type="date" label="Released date" />
        <.input field={@form[:material]} type="text" label="Material" />
        <.input field={@form[:mat_vendor]} type="text" label="Mat vendor" />
        <.input field={@form[:mat_description]} type="text" label="Mat description" />
        <.input field={@form[:employee]} type="text" label="Employee" />
        <.input field={@form[:dots]} type="number" label="Dots" />
        <.input field={@form[:currentop]} type="text" label="Currentop" />
        <.input field={@form[:material_waiting]} type="checkbox" label="Material waiting" />
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:est_total_hrs]} type="number" label="Est total hrs" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Runlist</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{runlist: runlist} = assigns, socket) do
    changeset = Shop.change_runlist(runlist)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"runlist" => runlist_params}, socket) do
    changeset =
      socket.assigns.runlist
      |> Shop.change_runlist(runlist_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"runlist" => runlist_params}, socket) do
    save_runlist(socket, socket.assigns.action, runlist_params)
  end

  defp save_runlist(socket, :edit, runlist_params) do
    case Shop.update_runlist(socket.assigns.runlist, runlist_params) do
      {:ok, runlist} ->
        notify_parent({:saved, runlist})

        {:noreply,
         socket
         |> put_flash(:info, "Runlist updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_runlist(socket, :new, runlist_params) do
    case Shop.create_runlist(runlist_params) do
      {:ok, runlist} ->
        notify_parent({:saved, runlist})

        {:noreply,
         socket
         |> put_flash(:info, "Runlist created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
