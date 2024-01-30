defmodule ShophawkWeb.RunlistLive.AssignmentForm do
  use ShophawkWeb, :live_component

  alias Shophawk.Shop

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage assignment records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="runlist-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:assignment]} type="text" label="Assignment" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Assignment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{assignment: assignment} = assigns, socket) do
    changeset = Shop.change_assignment(assignment)

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
