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
      {:ok, socket |> assign(department_id: nil) |> stream(:runlists, []) |> assign(:department, %{}) |> assign(:department_name, "") |> assign(:department_loads, load_all_runlist_loads()) |> assign(show_runlist_table: false) |> assign(updated: 0)}
    else
     {:ok, socket |> assign(department_id: nil) |> stream(:runlists, []) |> assign(:department, %{}) |> assign(:department_name, "") |> assign(:department_loads, nil) |> assign(show_runlist_table: false) |> assign(updated: 0)}
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
      department_loads: nil,
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
        |> assign(department_loads: load_all_runlist_loads())
        |> stream(:runlists, [], reset: true)}
      _ ->

        socket =
          socket
          |> assign(department_loads: nil)
          |> load_runlist(Shop.get_department_by_name(department).id)

        {:noreply, socket}
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

  def handle_event("show_job", %{"job" => job}, socket) do

    {jobs, job_info} = Shop.list_job(job)
    socket =
      socket
      |> assign(id: job)
      |> assign(page_title: "Job #{job}")
      |> assign(:live_action, :show_job)
      |> assign(:job_ops, jobs) #Load job data here and send as a list of ops in order
      |> assign(:job_info, job_info)

      #IO.inspect(socket)

    {:noreply, socket}
  end

  def handle_event("importall", _, socket) do
    #Csvimport.import_last_year()
    Csvimport.import_all_history
    socket

    {:noreply, stream(socket, :runlists, [])}
  end

  def handle_event("time_based_import", _, socket) do
    Csvimport.update_operations(nil, 0)
    {:noreply, stream(socket, :runlists, [])}
  end

  def handle_event("rework_to_do", _, socket) do
    Csvimport.rework_to_do()
  {:noreply, socket}
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
        {runlist, weekly_load} = Shop.list_runlists(workcenter_list, department)
        assignment_list = for %Shophawk.Shop.Assignment{assignment: a} <- department.assignments, do: a
        started_assignment_list =
          Enum.filter(runlist, fn op ->
            if Map.has_key?(op, :assignment) do
              op.assignment != "" and op.assignment != nil and not Enum.member?(assignment_list, op.assignment)
            else
              false
            end
          end)
          |> Enum.map(fn op -> op.assignment end)
          |> Enum.uniq


        dots =
          runlist
          |> Enum.reject(fn %{id: id} -> id == 0 end)
          |> Enum.reduce(%{}, fn row, acc ->
            case row.dots do
              1 -> Map.put_new(acc, :one, "bg-cyan-500 text-stone-950")  |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              2 -> Map.put_new(acc, :two, "bg-amber-500 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              3 -> Map.put_new(acc, :three, "bg-red-600 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              _ -> acc
            end
          end)
        dots = case Map.size(dots) do
          2 -> Map.put_new(dots, :dot_columns, "grid-cols-1")
          3 -> Map.put_new(dots, :dot_columns, "grid-cols-2")
          4 -> Map.put_new(dots, :dot_columns, "grid-cols-3")
          _ -> dots
        end
        dots =
          if dots[:ops] != nil do
            unique_ops_list =
              Enum.reduce(dots[:ops], %{}, fn runlist, acc ->
                if Map.has_key?(acc, runlist.job) do
                  acc
                else
                  Map.put(acc, runlist.job, runlist)
                end
              end)
              |> Map.values
              |> Enum.reverse
            dots = Map.put(dots, :ops, unique_ops_list)
          else
            dots
          end
        socket =
          socket
          |> assign(show_runlist_table: true)
          |> assign(dots: dots)
          |> assign(department_name: department.department)
          |> assign(department: department)
          |> assign(department_id: department.id)
          |> assign(assignments: [""] ++ assignment_list ++ started_assignment_list)
          |> assign(saved_assignments: assignment_list)
          |> assign(started_assignment_list: started_assignment_list)
          |> assign(weekly_load: weekly_load)
          |> stream(:runlists, runlist, reset: true)


        socket
      end
  end

  def handle_event("refresh_department", _, socket) do

    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      :timer.sleep(300)
      Process.send(process, {:send_runlist, load_runlist(socket, socket.assigns.department_id)}, [])
    end)
    update_number = socket.assigns.updated + 1
    {:noreply, assign(socket, :updated, update_number) |> assign(department_loads: nil)}
  end

  def handle_info({:send_runlist, updated_socket}, socket) do
    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      Process.send_after(process, :clear_updated, 0)
    end)
    {:noreply, updated_socket}
  end

  def handle_info(:clear_updated, socket) do
    update_number = socket.assigns.updated + 2
    {:noreply, assign(socket, :updated, update_number)}
  end

  def load_all_runlist_loads() do
    departments = Shop.list_departments |> Enum.sort_by(&(&1).department)
    department_loads =
      Enum.reduce(departments, %{}, fn department, acc ->
        workcenter_list = for %Shophawk.Shop.Workcenter{workcenter: wc} <- department.workcenters, do: wc
        Map.put(acc, department.department, workcenter_list)
      end)
      |> Enum.reduce([], fn {department_name, workcenters}, acc ->
        {_runlist, weekly_load} = Shop.list_runlists(workcenters, Shop.get_department_by_name(department_name))
        acc ++ [weekly_load]
      end)
  end

  def calculate_color(load) do
    cond do
      load < 90 -> "bg-stone-300"
      load >= 90 and load < 100 -> "bg-amber-300"
      load >= 100 -> "bg-red-500"
    end
  end

end
