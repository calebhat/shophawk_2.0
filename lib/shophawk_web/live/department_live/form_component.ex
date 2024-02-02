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

        <%= for workcenter <- @workcenters do %>

          <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
            <input type="hidden" name={workcenter.workcenter} value="false" />
            <input
              type="checkbox"
              id={"workcenter-" <> Integer.to_string(workcenter.id)}
              name="workcenter_ids[]"
              value={workcenter.id}
              checked={workcenter.id in @selected_workcenters}
              class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
            />
            <%= workcenter.workcenter %>
          </label>

        <% end %>
    <br>

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
    workcenters = Enum.map(Shop.list_workcenters(), &Map.from_struct/1)
    selected_workcenters =
      if department.id != nil do
        Enum.map(department.workcenters, &(&1.id)) #makes list of associated workcenter ID's for editing a department
      else
        []
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:workcenters, workcenters) #workcenters for checkboxes
     |> assign(:selected_workcenters, selected_workcenters) #keeps track of which workcenters are selected.
     |> assign(department_id: assigns.department.id)
    }
  end


  def handle_event("validate", %{"department" => department_params} = params, socket) do
    workcenters =
      Map.get(params, "workcenter_ids", []) #gets checked workcenters, defaults to empty list "[]" if none checked
      #|> Enum.map(fn id -> %{"id" => id} end)
    department_params = Map.put(department_params, "workcenters", workcenters) #merges workcenters to department params

    changeset =
      socket.assigns.department
      |> Shop.change_department(department_params)
      |> Map.put(:action, :validate)

      socket =
        socket
        |> assign_form(changeset)
        |> assign(:selected_workcenters, Enum.map(workcenters, &String.to_integer/1))

    {:noreply, socket}
  end

  def handle_event("save", %{"department" => department_params} = params, socket) do
    #Make workcenters into a map for changeset and saving
    workcenters =
      Map.get(params, "workcenter_ids", [])
      |> Enum.map(fn id -> %{"workcenter" => Shop.get_workcenter!(id).workcenter} end)

    department_params = Map.put(department_params, "workcenters", workcenters) #merges workcenters into params
    save_department(socket, socket.assigns.action, department_params)
  end

  defp save_department(socket, :edit_department, department_params) do
    case Shop.update_department(socket.assigns.department, department_params) do
      {:ok, department} ->
        notify_parent({:saved, department})

        {:noreply,
         socket
         |> assign(department_id: department.id)
         |> put_flash(:info, "Department updated successfully")
         |> push_patch(to: "/runlists", replace: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_department(socket, :new_department, department_params) do

    case Shop.create_department(department_params) do
      {:ok, department} ->
        notify_parent({:saved, department})
        #IO.inspect()
        {:noreply,
         socket
         |> put_flash(:info, "Department created successfully")
         |> push_patch(to: "/runlists", replace: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
