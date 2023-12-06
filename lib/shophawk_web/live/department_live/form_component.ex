defmodule ShophawkWeb.DepartmentLive.FormComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Shop

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage department records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="department-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:department]} type="text" label="Department" />
        <.input field={@form[:capacity]} type="number" label="Capacity" step="any" />
        <.input field={@form[:machine_count]} type="number" label="Machine count" step="any" />
        <.input field={@form[:show_jobs_started]} type="checkbox" label="Show jobs started" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Department</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{department: department} = assigns, socket) do
    changeset = Shop.change_department(department)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"department" => department_params}, socket) do
    changeset =
      socket.assigns.department
      |> Shop.change_department(department_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"department" => department_params}, socket) do
    IO.puts(socket.assigns.action)
    save_department(socket, socket.assigns.action, department_params)
  end

  defp save_department(socket, :edit, department_params) do
    case Shop.update_department(socket.assigns.department, department_params) do
      {:ok, department} ->
        notify_parent({:saved, department})

        {:noreply,
         socket
         |> put_flash(:info, "Department updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_department(socket, :new_department, department_params) do
    case Shop.create_department(department_params) do
      {:ok, department} ->
        notify_parent({:saved, department})

        {:noreply,
         socket
         |> put_flash(:info, "Department created successfully")
         |> push_patch(to: "/runlists")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
