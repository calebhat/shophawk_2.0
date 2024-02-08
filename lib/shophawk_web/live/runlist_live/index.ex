defmodule ShophawkWeb.RunlistLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shop
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop.Department
  alias Shophawk.Shop.Csvimport
  alias Shophawk.Shop.Assignment

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(department_id: nil) |> stream(:runlists, []) |> assign(:department, %{}) |> assign(:department_name, "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:departments,  ["Select Department" | Shop.list_departments() |> Enum.map(&(&1.department)) |> Enum.sort] )

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
        socket =
          socket
          |> assign(:page_title, "Listing Runlists")
          |> assign(:runlist, nil)

          socket =
          if Map.has_key?(socket.assigns, :department_name) do
            if is_nil(socket.assigns.department_name) do
              load_runlist(socket, "Select Department")
            else
              load_runlist(socket, socket.assigns.department_id)
            end
          else
            socket
          end

          socket
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Runlist")
    |> assign(:runlist, Shop.get_runlist!(id))
  end

  defp apply_action(socket, :edit_department, %{"id" => id}) do
    Csvimport.update_workcenters()
    socket =
      socket
      |> assign(:page_title, "Edit Department")

    load_runlist(socket, id)
  end

  defp apply_action(socket, :new_department, params) do
    Csvimport.update_workcenters()

    socket =
        socket
      |> assign(:page_title, "New Department")
      |> assign(:workcenters, Shop.list_workcenters())
      |> load_runlist(socket.assigns.department_id)
      |> assign(:department, %Department{})
  end

  defp apply_action(socket, :new_assignment, %{"id" => id}) do
    socket =
      socket
      |> assign(:page_title, "New Assignment")
      |> assign(:assignment, %Assignment{})
      |> load_runlist(id)
  end

  defp apply_action(socket, :assignments, %{"id" => id}= params) do
    IO.inspect(params)
    socket =
      socket
      |> assign(:page_title, "View Assignments")
      |> load_runlist(id)
      #|>
      #|> assigns(assignments: assignments)
  end

  #@impl true
  #def handle_info({ShophawkWeb.RunlistLive.FormComponent, {:saved, runlist}}, socket) do
  #  {:noreply, stream_insert(socket, :runlists, runlist)}
  #end

  @impl true
  def handle_info({ShophawkWeb.RunlistLive.DepartmentForm, {:saved, department}}, socket) do
    socket =
      assign(socket,
        department_id: department.id,
        deparment_name: department.department)

    {:noreply, apply_action(socket, :index, nil)}
  end

  def handle_info({ShophawkWeb.RunlistLive.DepartmentForm, {:destroyed, department}}, socket) do
    {:noreply, socket}
  end

  def handle_info({ShophawkWeb.RunlistLive.AssignmentForm, {:saved, assignment}}, socket) do
    {:noreply, socket}
  end

  def handle_event("select_department", %{"selection" => department}, socket) do
    {:noreply, load_runlist(socket, Shop.get_department_by_name(department).id)}
  end

  defp load_runlist(socket, department_id) do
    socket =
      case department_id do
        "Select Department" ->
          socket =
            socket
            |> assign(department_id: nil)
            |> stream(:runlists, [], reset: true)

        "" ->
          socket =
            socket
            |> assign(department_id: nil)
            |> stream(:runlists, [], reset: true)
        nil ->
          socket =
            socket
            |> assign(department_id: nil)
            |> stream(:runlists, [], reset: true)

        _ ->
        department = Shop.get_department!(department_id)
        workcenter_list = for %Shophawk.Shop.Workcenter{workcenter: wc} <- department.workcenters, do: wc
        assignment_list = for %Shophawk.Shop.Assignment{assignment: a} <- department.assignments, do: a
        runlists =
          Shop.list_runlists(workcenter_list)
        socket =
          socket
          |> assign(department_name: department.department)
          |> assign(department: department)
          |> assign(department_id: department.id)
          |> assign(assignments: [""] ++ assignment_list)
          |> stream(:runlists, runlists, reset: true)
      end
  end

  defp operation_alteration(operation) do
    new_value =
      if operation == "NULL" do
        ""
      else
        operation
      end
  end

  def handle_event("mat_waiting_toggle", %{"id" => id}, socket) do
    Shop.toggle_mat_waiting(id)
    {:noreply, socket}
  end

  def handle_event("change_assignment", %{"id" => id, "selection" => selection } = params, socket) do
    Shop.update_runlist(Shop.get_runlist!(id), %{assignment: selection})
    {:noreply, socket}
  end

  def handle_event("assignments_name_change", %{"target" => assignment}, socket) do
    {:noreply, socket}
  end

  def handle_event("importall", _, socket) do
    tempjobs = Csvimport.import_operations()
    count = Enum.count(tempjobs)
    socket

    {:noreply, stream(socket, :runlists, [])}
    #{:noreply, stream(socket, :runlists, Shop.list_runlists())}
  end



  def handle_event("5_minute_import", _, socket) do
    Csvimport.update_operations()
    socket

    {:noreply, stream(socket, :runlists, [])}
    #{:noreply, stream(socket, :runlists, Shop.list_runlists())}
  end

end
