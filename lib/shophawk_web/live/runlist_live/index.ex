defmodule ShophawkWeb.RunlistLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shop
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop.Department
  alias Shophawk.Shop.Csvimport
  alias Shophawk.Shop.Assignment

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do

      departments = Shop.list_departments
      department_loads =
        Enum.reduce(departments, %{}, fn department, acc ->
          workcenter_list = for %Shophawk.Shop.Workcenter{workcenter: wc} <- department.workcenters, do: wc
          Map.put(acc, department.department, workcenter_list)
        end)
        |> Enum.reduce([], fn {department_name, workcenters}, acc ->
          {_runlist, weekly_load} = Shop.list_runlists(workcenters, Shop.get_department_by_name(department_name))
          acc ++ [weekly_load]
        end)

        #IO.inspect(department_loads)

      #socket = apply_action(socket, socket.assigns.live_action, %{})
      {:ok, socket |> assign(department_id: nil) |> stream(:runlists, []) |> assign(:department, %{}) |> assign(:department_name, "") |> assign(:department_loads, department_loads)}
    else
     {:ok, socket |> assign(department_id: nil) |> stream(:runlists, []) |> assign(:department, %{}) |> assign(:department_name, "") |> assign(:department_loads, nil)}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:departments,  ["Select Department" | Shop.list_departments() |> Enum.map(&(&1.department)) |> Enum.sort] )
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do




    #{_runlist, weekly_load} =
    #  Shop.list_runlists(workcenter_list, department)
    #socket
    #|> assign(weekly_load: weekly_load)


    socket
    |> assign(:page_title, "Listing Runlists")
    |> assign(:runlist, nil)
    |> load_runlist(socket.assigns.department_id)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Runlist")
    |> assign(:runlist, Shop.get_runlist!(id))
  end

  defp apply_action(socket, :edit_department, _) do
    Csvimport.update_workcenters()
    socket =
      socket
      |> assign(:page_title, "Edit Department")
  end

  defp apply_action(socket, :new_department, _) do
    Csvimport.update_workcenters()
    socket =
        socket
      |> assign(:page_title, "New Department")
      |> assign(:workcenters, Shop.list_workcenters())
      |> assign(:department, %Department{})
  end

  defp apply_action(socket, :new_assignment, _) do
    socket =
      socket
      |> assign(:page_title, "New Assignment")
      |> assign(:assignment, %Assignment{})
  end

  defp apply_action(socket, :assignments, %{"id" => id}) do
      socket
      |> assign(:page_title, "View Assignments")
      |> load_runlist(id)
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
    socket =
      case socket.assigns.department_id do
        nil -> socket
        _ -> load_runlist(socket, socket.assigns.department_id)
      end
    {:noreply, socket}
  end

  def handle_info({ShophawkWeb.RunlistLive.ViewAssignments, {:delete}}, socket) do
    {:noreply, socket}
  end

  def handle_event("select_department", %{"selection" => department}, socket) do
    case department do
      "Select Department" ->
        {:noreply, socket
        |> assign(department_id: nil)
        |> stream(:runlists, [], reset: true)}
      _ ->
        {:noreply, load_runlist(socket, Shop.get_department_by_name(department).id)}
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
    {:noreply, load_runlist(socket, socket.assigns.department_id)}
  end

  def handle_event("change_assignment", %{"id" => id, "selection" => selection } = params, socket) do
    Shop.update_runlist(Shop.get_runlist!(id), %{assignment: selection})
    {:noreply, load_runlist(socket, socket.assigns.department_id)}
  end

  def handle_event("assignments_name_change", %{"target" => assignment}, socket) do
    {:noreply, socket}
  end

  def handle_event("importall", _, socket) do
    tempjobs = Csvimport.import_operations()
    count = Enum.count(tempjobs)
    socket

    {:noreply, stream(socket, :runlists, [])}
  end



  def handle_event("5_minute_import", _, socket) do
    Csvimport.update_operations()
    socket

    {:noreply, stream(socket, :runlists, [])}
  end

  defp load_runlist(socket, department_id) do
    socket =
      case department_id do
        nil ->
            socket
            |> assign(department_id: nil)
            |> stream(:runlists, [], reset: true)

        _ ->
        department = Shop.get_department!(department_id)
        workcenter_list = for %Shophawk.Shop.Workcenter{workcenter: wc} <- department.workcenters, do: wc
        assignment_list = for %Shophawk.Shop.Assignment{assignment: a} <- department.assignments, do: a
        {runlist, weekly_load} =
          Shop.list_runlists(workcenter_list, department)
        socket
        |> assign(department_name: department.department)
        |> assign(department: department)
        |> assign(department_id: department.id)
        |> assign(assignments: [""] ++ assignment_list)
        |> assign(weekly_load: weekly_load)
        |> stream(:runlists, runlist, reset: true)
      end
  end

end
