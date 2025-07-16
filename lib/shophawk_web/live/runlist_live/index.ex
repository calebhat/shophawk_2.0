defmodule ShophawkWeb.RunlistLive.Index do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJobLive.ShowJobMacroFunctions #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  alias Shophawk.Shop
  alias Shophawk.Shop.Department
  alias Shophawk.Shop.Assignment

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  def mount(_params, _session, socket) do
    if connected?(socket) do
      #ScheduledTasks.update_all_runlist_loads  #reloads all department loads on refresh
      department_loads = get_runlist_loads()
      socket = if Enum.any?(department_loads, fn list -> list != [] end), do: assign(socket, show_department_loads: true), else: assign(socket, show_department_loads: false)
      {:ok, set_default_assigns(socket) |> assign(:department_loads, department_loads) }
    else
     {:ok, set_default_assigns(socket) |> assign(:department_loads, nil) |> assign(show_department_loads: false)}
    end
  end

  def set_default_assigns(socket) do
    socket
    |> assign(department_id: nil)
    |> assign(workcenter_id: nil)
    |> stream(:runlists, [], reset: true)
    |> assign(:department, %{})
    |> assign(:department_name, "")
    |> assign(show_runlist_table: false)
    |> assign(show_workcenter_table: false)
    |> assign(updated: 0)
    |> assign(:search_value, "")
  end

  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:departments,  ["Select Department" | Shop.list_departments() |> Enum.map(&(&1.department)) |> Enum.sort])
      |> assign(:workcenters, ["Select Workcenter" | Shop.list_workcenters() |> Enum.map(&(&1.workcenter)) |> Enum.sort])
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def get_runlist_loads() do
    {:ok, data} = Cachex.get(:runlist_loads, :data)
    data
  end

  defp apply_action(socket, :index, _params) do
    cond do
      socket.assigns.department_id != nil ->
        socket
        |> assign(:page_title, "Listing Runlists")
      socket.assigns.workcenter_id != nil ->
        socket
        |> assign(:page_title, "Listing Runlists")
      true ->
        socket
        |> assign(:page_title, "Listing Runlists")
        |> assign(:runlist, nil)
        |> finalize_department_stream(socket.assigns.department_id)
    end
  end

  #defp apply_action(socket, :edit, %{"id" => id}) do
  #  socket
  #  |> assign(:page_title, "Edit Runlist")
  #  |> assign(:runlist, Shop.get_runlist!(id))
  #end

  defp apply_action(socket, :edit_department, _) do
    Shophawk.Jobboss_db.update_workcenters()
    socket
    |> assign(:page_title, "Edit Department")
  end

  defp apply_action(socket, :new_department, _) do
    Shophawk.Jobboss_db.update_workcenters()
    socket
    |> assign(:page_title, "New Department")
    |> assign(:department, %Department{})
  end

  defp apply_action(socket, :new_assignment, _) do
    socket
    |> assign(:page_title, "New Assignment")
    |> assign(:assignment, %Assignment{})
  end

  defp apply_action(socket, :assignments, %{"id" => id}) do
      socket
      |> assign(:page_title, "View Assignments")
      |> finalize_department_stream(id)
  end

  def handle_info({ShophawkWeb.RunlistLive.DepartmentForm, {:saved, department}}, socket) do
    workcenter_list = Enum.map(department.workcenters, fn w -> w.workcenter end)
    {_runlist, weekly_load, _jobs_that_ship_today} = Shop.list_runlists(workcenter_list, department)
    {:ok, weekly_loads} = Cachex.get(:runlist_loads, :data)
    merged_loads = [weekly_load] ++ weekly_loads #merge new department into weekly loads
    sorted_loads = Enum.sort_by(merged_loads, &(&1.department))
    Cachex.put(:runlist_loads, :data, sorted_loads)

    socket =
      finalize_department_stream(socket, department.id)
      |> assign(:department_loads, sorted_loads)
    {:noreply, apply_action(socket, :index, nil)}
  end

  def handle_info({ShophawkWeb.RunlistLive.DepartmentForm, {:destroyed, _department}}, socket) do
    {:noreply, socket}
  end

  def handle_info({ShophawkWeb.RunlistLive.AssignmentForm, {:saved, _assignment}}, socket) do
    case socket.assigns.department_id do
      nil -> socket
      _ -> finalize_department_stream(socket, socket.assigns.department_id)
    end
    {:noreply, socket}
  end

  def handle_info({ShophawkWeb.RunlistLive.ViewAssignments, {:delete}}, socket) do
    {:noreply, socket}
  end

  def handle_info({:send_runlist, updated_socket}, _socket) do
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


  #TESTING PURPOSES
  def handle_info({:refresh_department, socket}, _sock) do
    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      :timer.sleep(300)
      Process.send(process, {:send_runlist, finalize_department_stream(socket, socket.assigns.department_id)}, [])
    end)
    update_number = socket.assigns.updated + 1
    {:noreply, assign(socket, :updated, update_number) |> assign(department_loads: nil)}
  end

  def handle_event("select_department", %{"selection" => department}, socket) do
    case department do
      "Select Department" ->
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          socket =
            socket
            |> assign(department_id: nil)
            |> assign(show_runlist_table: false)
            |> assign(show_workcenter_table: false)
            |> assign(show_department_loads: true)
            |> assign(department_loads: get_runlist_loads())
            |> stream(:runlists, [], reset: true)
          Process.send(process, {:send_runlist, socket}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
      _ ->
        department_id = Shop.get_department_by_name(department).id
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          Process.send(process, {:send_runlist, finalize_department_stream(socket, department_id)}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
    end
  end

  def handle_event("select_workcenter", %{"choice" => workcenter}, socket) do
    case workcenter do
      "Select Workcenter" ->
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          socket =
            socket
            |> assign(workcenter_id_id: nil)
            |> assign(show_runlist_table: false)
            |> assign(show_workcenter_table: false)
            |> assign(show_department_loads: true)
            |> assign(department_loads: get_runlist_loads())
            |> stream(:runlists, [], reset: true)
          Process.send(process, {:send_runlist, socket}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
      _ ->
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          Process.send(process, {:send_runlist, finalize_workcenter_stream(socket, Shop.get_workcenter_by_name(workcenter))}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
    end
  end

  def handle_event("color_key", _, socket) do
    {:noreply, assign(socket, :live_action, :color_key)}
  end

  def handle_event("mat_waiting_toggle", %{"job-operation" => job_operation, "job" => job}, socket) do

    case Shop.get_runlist_by_job_operation(String.to_integer(job_operation)) do
      nil ->
        Shophawk.RunlistCache.update_key_value(job, String.to_integer(job_operation), :material_waiting, true)
        Shop.create_runlist(%{job_operation: job_operation, material_waiting: true})
      op ->
        runlists =
          Cachex.stream!(:active_jobs, Cachex.Query.build(output: :value))
          |> Enum.to_list
          |> Enum.map(fn job_data -> job_data.job_ops end)
          |> List.flatten

        job_number = Enum.find(runlists, fn o -> o.job_operation == op.job_operation end).job
        job_ops = Enum.filter(runlists, fn o -> o.job == job_number end)
        Enum.each(job_ops, fn o ->
          Shophawk.RunlistCache.update_key_value(job, o.job_operation, :material_waiting, !op.material_waiting)
          case Shop.get_runlist_by_job_operation(o.job_operation) do
            nil -> :noop
            operation -> Shop.update_runlist(operation, %{material_waiting: !op.material_waiting})
          end
        end)

    end
    {:noreply, socket}
  end

  def handle_event("change_assignment", %{"job-operation" => job_operation, "selection" => selection, "job" => job} = _params, socket) do
    Shophawk.RunlistCache.update_key_value(job, String.to_integer(job_operation), :assignment, selection)
    case Shop.get_runlist_by_job_operation(String.to_integer(job_operation)) do
      nil -> Shop.create_runlist(%{job_operation: job_operation, assignment: selection})
      op -> Shop.update_runlist(op, %{assignment: selection})
    end
    {:noreply, socket}
  end

  def handle_event("assignments_name_change", %{"target" => _assignment}, socket) do
    {:noreply, socket}
  end

  def handle_event("test", _, socket) do

    #Shophawk.Jobboss_db.update_workcenters

    #{:ok, previous_check} = Cachex.get(:runlist_refresh_time, :refresh_time)
    #Cachex.put(:runlist, {:refresh_time, NaiveDateTime.utc_now()})
    #jobs = Shophawk.Jobboss_db.sync_recently_updated_jobs(previous_check)


    #Enum.each(runlists, fn op ->
    #if op.job =="135480" do
    #end
    #end)

    {:noreply, socket}
  end

  def handle_event("refresh_department", _, socket) do
    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      :timer.sleep(300)
      Process.send(process, {:send_runlist, finalize_department_stream(socket, socket.assigns.department_id)}, [])
    end)
    update_number = socket.assigns.updated + 1
    {:noreply, assign(socket, :updated, update_number) |> assign(department_loads: nil)}
  end

  def handle_event("refresh_workcenter", _, socket) do
    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      :timer.sleep(300)
      Process.send(process, {:send_runlist, finalize_workcenter_stream(socket, Shop.get_workcenter_by_name(socket.assigns.name))}, [])
    end)
    update_number = socket.assigns.updated + 1
    {:noreply, assign(socket, :updated, update_number) |> assign(department_loads: nil)}
  end

  defp finalize_department_stream(socket, department_id) do
    case department_id do
      nil ->
          socket
          |> assign(department_id: nil)
          |> stream(:runlists, [], reset: true)

      _ ->
      department = Shop.get_department!(department_id)
      workcenter_list = for %Shophawk.Shop.Workcenter{workcenter: wc} <- department.workcenters, do: wc
      {runlist, weekly_load, jobs_that_ship_today} = Shop.list_runlists(workcenter_list, department)
      if runlist != [] do
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
          |> Enum.reject(fn %{date_row_identifer: date_row_identifer} -> date_row_identifer in  [0, -1] end)
          |> Enum.reject(fn %{id: id} -> id in  [0, -1] end)
          |> Enum.reduce(%{}, fn row, acc ->
            case row.dots do
              1 -> Map.put_new(acc, :one, "bg-cyan-500 text-stone-950")  |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              2 -> Map.put_new(acc, :two, "bg-amber-500 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              3 -> Map.put_new(acc, :three, "bg-red-600 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              _ -> acc
            end
          end)
        dots = case Kernel.map_size(dots) do
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
            Map.put(dots, :ops, unique_ops_list)
          else
            dots
          end
        socket
        |> assign(runlist_id_list: Enum.map(runlist, fn op -> op.id end))
        |> assign(show_runlist_table: true)
        |> assign(show_workcenter_table: false)
        |> assign(show_department_loads: false)
        |> assign(dots: dots)
        |> assign(name: department.department)
        |> assign(department: department)
        |> assign(department_id: department.id)
        |> assign(workcenter_id: nil)
        |> assign(assignments: [""] ++ assignment_list ++ started_assignment_list)
        |> assign(saved_assignments: assignment_list)
        |> assign(started_assignment_list: started_assignment_list)
        |> assign(weekly_load: weekly_load)
        |> assign(jobs_that_ship_today: jobs_that_ship_today)
        |> stream(:runlists, runlist, reset: true)
      else
        socket
        |> assign(runlist_id_list: [])
        |> assign(show_runlist_table: false)
        |> assign(show_workcenter_table: false)
        |> assign(show_department_loads: false)
        |> assign(dots: %{dot_columns: ""})
        |> assign(name: department.department)
        |> assign(department: department)
        |> assign(department_id: department.id)
        |> assign(workcenter_id: nil)
        |> assign(assignments: [""] )
        |> assign(saved_assignments: [])
        |> assign(started_assignment_list: [])
        |> assign(weekly_load: [])
        |> stream(:runlists, [], reset: true)
      end
    end
  end

  defp finalize_workcenter_stream(socket, workcenter) do
    workcenter_name = workcenter.workcenter
    case workcenter do
      nil ->
          socket
          |> assign(department_id: nil)
          |> stream(:runlists, [], reset: true)

      _ ->
      runlist = Shop.list_workcenter(workcenter_name)
      if runlist != [] do
        started_assignment_list =
          Enum.filter(runlist, fn op ->
            if Map.has_key?(op, :assignment) do
              op.assignment != "" and op.assignment != nil
            else
              false
            end
          end)
          |> Enum.map(fn op -> op.assignment end)
          |> Enum.uniq

        dots =
          runlist
          |> Enum.reject(fn %{date_row_identifer: date_row_identifer} -> date_row_identifer in  [0, -1] end)
          |> Enum.reduce(%{}, fn row, acc ->
            case row.dots do
              1 -> Map.put_new(acc, :one, "bg-cyan-500 text-stone-950")  |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              2 -> Map.put_new(acc, :two, "bg-amber-500 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              3 -> Map.put_new(acc, :three, "bg-red-600 text-stone-950") |> Map.update(:ops, [row], fn list -> list ++ [row] end)
              _ -> acc
            end
          end)
        dots = case Kernel.map_size(dots) do
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
            Map.put(dots, :ops, unique_ops_list)
          else
            dots
          end
        socket
        |> assign(show_runlist_table: false)
        |> assign(show_workcenter_table: true)
        |> assign(show_department_loads: false)
        |> assign(dots: dots)
        |> assign(name: workcenter.workcenter)
        |> assign(department: workcenter)
        |> assign(department_id: nil)
        |> assign(workcenter_id: workcenter.id)
        |> assign(assignments: [""] ++ started_assignment_list)
        |> assign(saved_assignments: [])
        |> assign(started_assignment_list: started_assignment_list)
        |> assign(weekly_load: nil)
        |> stream(:runlists, runlist, reset: true)
      else
        socket
        |> assign(show_runlist_table: false)
        |> assign(show_workcenter_table: false)
        |> assign(show_department_loads: false)
        |> assign(dots: %{dot_columns: ""})
        |> assign(name: workcenter.workcenter)
        |> assign(department: workcenter)
        |> assign(department_id: nil)
        |> assign(workcenter_id: workcenter.id)
        |> assign(assignments: [""])
        |> assign(saved_assignments: [])
        |> assign(started_assignment_list: [])
        |> assign(weekly_load: nil)
        |> stream(:runlists, [], reset: true)
      end
    end
  end

  def calculate_color(load) do
    cond do
      load < 90 -> "bg-stone-300"
      load >= 90 and load < 100 -> "bg-amber-300"
      load >= 100 -> "bg-red-500"
    end
  end

  def create_material_string(material_reqs) do
    if Map.has_key?(List.first(material_reqs), :material) do
      case Enum.count(material_reqs) do
        1 ->
          Enum.reduce(material_reqs, "", fn mat, _acc ->
            mat.material
          end)
        _ ->
          Enum.reduce(material_reqs, "", fn mat, acc ->
            mat.material <> " | " <> acc
          end)
      end
    end


  end

end
