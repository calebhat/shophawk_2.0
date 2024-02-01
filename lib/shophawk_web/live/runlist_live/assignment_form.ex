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
  def handle_event("validate", %{"assignment" => assignment_params}, socket) do
    changeset =
      socket.assigns.assignment
      |> Shop.change_assignment(assignment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"assignment" => assignment_params}, socket) do
    save_assignment(socket, socket.assigns.action, assignment_params)
  end

  defp save_assignment(socket, :edit_assignment, assignment_params) do
    case Shop.update_assignment(socket.assigns.assignment, assignment_params) do
      {:ok, assignment} ->
        notify_parent({:saved, assignment})

        {:noreply,
         socket
         |> put_flash(:info, "assignment updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_assignment(socket, :new_assignment, assignment_params) do
    case Shop.create_assignment(socket.assigns.department_id, assignment_params) do
      {:ok, assignment} ->
        notify_parent({:saved, assignment})

        {:noreply,
         socket
         |> put_flash(:info, "Assignment created successfully")
         |> push_patch(to: socket.assigns.patch, replace: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
