defmodule ShophawkWeb.RunlistLive.ViewAssignments do
  use ShophawkWeb, :live_component

  alias Shophawk.Shop

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center">
    <div class="text-2xl">
    <%= @department_name %> Assignments
    </div>
    (Assignments save as changes are typed)
    <br><br><br>
      <body>

      <%= for {key, value} <- @form.source do %>
        <.tight_simple_form for={@form} phx-change="assignments_name_change" phx-value-id={key} phx-value-assignment={value} phx-target={@myself}>
          <div class="grid grid-cols-2">
            <div class="flex justify-center">
              <.input field={@form[key]}/>
            </div>
            <div class="pl-8 pr-8 pt-3 pb-3 flex justify-center">
              <.delete_button phx-click="delete" phx-value-assignment={value} phx-value-id={key} phx-target={@myself} class="w-full">Delete</.delete_button>
            </div>
          </div>
          </.tight_simple_form>
        <% end %>


        <br>
        <button >Add Assignment</button>
      </body>
    </div>
    """
  end

  @impl true
  def update(%{assignments: assignments} = assigns, socket) do


    {:ok,
     socket
     |> assign(assigns)
     |> assign(assignments: assignments)
     |> assign(form: load_assignment_form(assignments))
    }
  end

  defp load_assignment_form(assignments) do
      List.delete_at(assignments, 0)
      |> Enum.with_index( fn a, index ->
        #IO.inspect(Shop.get_assignment(a).id)
        {Integer.to_string(Shop.get_assignment(a).id), a}
      end)

      |> Map.new
      |> IO.inspect
      |> to_form
  end

  def handle_event("assignments_name_change", %{"id" => id, "assignment" => old_assignment} = params, socket) do
    IO.inspect(params)
    [{_, new_assignment}] =
    params
    |> Map.take([hd(Map.keys(params))])
    |> Map.to_list()
    IO.inspect(new_assignment)

    Shop.update_assignment(id, new_assignment, old_assignment)
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Shop.delete_assignment(id)

    {:noreply,
            socket
            |> assign(form: load_assignment_form(socket.assigns.assignments))
            #|> push_patch(to: "/runlists/#{socket.assigns.department_id}/assignments")}
  }
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
