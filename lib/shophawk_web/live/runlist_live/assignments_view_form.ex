defmodule ShophawkWeb.RunlistLive.ViewAssignments do
  use ShophawkWeb, :live_component

  alias Shophawk.Shop

  def render(assigns) do
    ~H"""
    <div class="text-center">
    <div class="text-2xl">
    <%= @department_name %> Assignments
    </div>
    <br><br><br>
      <body>

      <%= for form <- @form_list do %>
        <.tight_simple_form for={form.source} phx-change="assignments_name_change" phx-value-id={form.source["id"]} phx-value-old_assignment={form.source["assignment"]} phx-target={@myself}>
          <div class="grid grid-cols-2">
            <div class="flex justify-center">
              <.input name="assignment" value={form.source["assignment"]} field={form.source["assignment"]} phx-debounce="500"/>
            </div>
            <div class="pl-8 pr-8 pt-3 pb-3 flex justify-center">
              <.delete_button phx-click="delete" phx-value-assignment={form.source["assignment"]} phx-value-id={form.source["id"]} phx-value-department_id={@department_id} phx-target={@myself} class="w-44">Delete</.delete_button>
            </div>
          </div>
          </.tight_simple_form>

        <% end %>


        <br>
        <div class="grid grid-cols-1">
        <div class="flex justify-center">
          <.link patch={~p"/runlists/#{@department_id}/new_assignment"}>
          <button
            type="button"
            class={[
              "phx-submit-loading:opacity-75 rounded-lg bg-lime-800 hover:bg-lime-700 py-1.5 px-3",
              "text-sm font-semibold leading-6 text-white active:text-white/80 w-44"
            ]}
          >
            New Assignment
          </button>
          </.link>
          </div>
        </div>
      </body>
    </div>
    """
  end

  def update(%{assignments: assignments} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(assignments: assignments)
     |> assign(form_list: load_assignment_form(assignments, assigns.department_id))
    }
  end

  defp load_assignment_form(assignments, department_id) do
      Enum.with_index(assignments, fn a, _index ->
        %{"assignment" => a, "id" => Integer.to_string(Shop.get_assignment(a, department_id).id)}
      end)
      |> Enum.map(&to_form/1)
  end

  def handle_event("assignments_name_change", %{"assignment" => new_assignment, "id" => id, "old_assignment" => old_assignment} = _params, socket) do
    selected_keys = [:ed, :title, :action, :patch, :department_id, :department_name, :assignments]
    if new_assignment == "" do
      {:noreply, socket}
    else
      old_assigns = Map.take(socket.assigns, selected_keys)

      new_assignments = Enum.map(old_assigns.assignments, fn item ->
        if item == old_assignment do
          new_assignment
        else
          item
        end
      end)
      Shop.update_assignment(id, new_assignment, old_assignment)
      {:noreply,
      socket
      |> assign(assignments: new_assignments)
      |> assign(form_list: load_assignment_form(new_assignments, socket.assigns.department_id))}
    end
  end

  def handle_event("delete", %{"id" => id, "department_id" => _department_id}, socket) do
    Shop.delete_assignment(id)
    {:noreply, socket }
  end

end
