defmodule ShophawkWeb.RunlistLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shop
  alias Shophawk.Shop.Department
  alias Shophawk.Shop.Assignment
  alias Shophawk.GeneralExports
  alias Shophawk.RunlistImports
  alias Shophawk.Jobboss

  def mount(_params, _session, socket) do
    if connected?(socket) do
      department_loads = get_runlist_loads()
      socket = if Enum.any?(department_loads, fn list -> list != [] end), do: assign(socket, show_department_loads: true), else: assign(socket, show_department_loads: false)
      {:ok, socket |> assign(department_id: nil) |> assign(workcenter_id: nil) |> stream(:runlists, [], reset: true) |> assign(:department, %{}) |> assign(:department_name, "") |> assign(:department_loads, department_loads) |> assign(show_runlist_table: false) |> assign(show_workcenter_table: false) |> assign(updated: 0)}
    else
     {:ok, socket |> assign(department_id: nil) |> assign(workcenter_id: nil) |> stream(:runlists, [], reset: true) |> assign(:department, %{}) |> assign(:department_name, "") |> assign(:department_loads, nil) |> assign(show_runlist_table: false) |> assign(show_workcenter_table: false) |> assign(show_department_loads: false)|> assign(updated: 0)}
    end
  end

  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:departments,  ["Select Department" | Shop.list_departments() |> Enum.map(&(&1.department)) |> Enum.sort])
      |> assign(:workcenters, ["Select Workcenter" | Shop.list_workcenters() |> Enum.map(&(&1.workcenter)) |> Enum.sort])
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def get_runlist_loads() do
    [data: data] = :ets.lookup(:runlist_loads, :data)
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
        |> load_runlist(socket.assigns.department_id)
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
      |> load_runlist(id)
  end

  def handle_info({ShophawkWeb.RunlistLive.DepartmentForm, {:saved, department}}, socket) do
    socket = load_runlist(socket, Shop.get_department_by_name(department.department).id)
    {:noreply, apply_action(socket, :index, nil)}
  end

  def handle_info({ShophawkWeb.RunlistLive.DepartmentForm, {:destroyed, _department}}, socket) do
    {:noreply, socket}
  end

  def handle_info({ShophawkWeb.RunlistLive.AssignmentForm, {:saved, _assignment}}, socket) do
    case socket.assigns.department_id do
      nil -> socket
      _ -> load_runlist(socket, socket.assigns.department_id)
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

  def handle_info({:load_attachments, job}, socket) do
    :ets.insert(:job_attachments, {:data, Shophawk.Jobboss_db.export_attachments(job)})  # Store the data in ETS
    {:noreply, socket}
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
        process = self()
        Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
          :timer.sleep(300)
          Process.send(process, {:send_runlist, load_runlist(socket, Shop.get_department_by_name(department).id)}, [])
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
          Process.send(process, {:send_runlist, load_workcenter(socket, Shop.get_workcenter_by_name(workcenter))}, [])
        end)
        update_number = socket.assigns.updated + 1
        {:noreply, assign(socket, :updated, update_number)}
    end
  end

  def handle_event("color_key", _, socket) do
    {:noreply, assign(socket, :live_action, :color_key)}
  end

  def handle_event("mat_waiting_toggle", %{"job-operation" => job_operation}, socket) do
    case Shop.get_runlist_by_job_operation(String.to_integer(job_operation)) do
      nil -> Shop.create_runlist(%{job_operation: job_operation, material_waiting: true})
      op -> Shop.update_runlist(op, %{material_waiting: !op.material_waiting})
    end
    {:noreply, socket}
  end

  def handle_event("change_assignment", %{"job-operation" => job_operation, "selection" => selection } = _params, socket) do
    case Shop.get_runlist_by_job_operation(String.to_integer(job_operation)) do
      nil -> Shop.create_runlist(%{job_operation: job_operation, assignment: selection})
      op -> Shop.update_runlist(op, %{assignment: selection})
    end
    {:noreply, socket}
  end

  def handle_event("assignments_name_change", %{"target" => _assignment}, socket) do
    {:noreply, socket}
  end

  def handle_event("show_job", %{"job" => job}, socket) do
    Process.send(self(), {:load_attachments, job}, [:noconnect]) #loads attachement and saves them now for faster UX
    {job_ops, job_info} = Shop.list_job(job)
    socket =
      socket
      |> assign(id: job)
      |> assign(page_title: "Job #{job}")
      |> assign(:live_action, :show_job)
      |> assign(:job_ops, job_ops) #Load job data here and send as a list of ops in order
      |> assign(:job_info, job_info)

    {:noreply, socket}
  end

  def handle_event("test", _, socket) do
    #Shophawk.Jobboss_db.convert_binary_to_string(<<75, 214, 82, 66, 69, 82, 32, 84, 69, 67>>) |> IO.inspect
    #Shophawk.Jobboss_db.update_workcenters

    [{:refresh_time, previous_check}] = :ets.lookup(:runlist, :refresh_time)
    :ets.insert(:runlist, {:refresh_time, NaiveDateTime.utc_now()})
    jobs = Shophawk.Jobboss_db.recently_updated_jobs(previous_check)

    #IO.inspect(Enum.count(jobs))

    {:noreply, socket}
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

  def handle_event("refresh_workcenter", _, socket) do
    process = self()
    Task.start(fn -> #runs asyncronously so loading animation gets sent to socket first
      :timer.sleep(300)
      Process.send(process, {:send_runlist, load_workcenter(socket, Shop.get_workcenter_by_name(socket.assigns.name))}, [])
    end)
    update_number = socket.assigns.updated + 1
    {:noreply, assign(socket, :updated, update_number) |> assign(department_loads: nil)}
  end

  def handle_event("attachments", _, socket) do
    IO.inspect(socket.assigns.id)
    job = socket.assigns.id
    [{:data, attachments}] = :ets.lookup(:job_attachments, :data)
    socket =
      socket
      |> assign(id: job)
      |> assign(attachments: attachments)
      |> assign(page_title: "Job #{job} attachments")
      |> assign(:live_action, :job_attachments)

    {:noreply, socket}
  end

  def handle_event("download", %{"file-path" => file_path}, socket) do
    {:noreply, push_event(socket, "trigger_file_download", %{"url" => "/download/#{URI.encode(file_path)}"})}
  end

  def handle_event("download", _params, socket) do
    {:noreply, socket |> assign(:not_found, "File not found")}
  end

  def handle_event("close_job_attachments", _params, socket) do
    {:noreply, assign(socket, live_action: :show_job)}
  end

  defp load_runlist(socket, department_id) do
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

  defp load_workcenter(socket, workcenter) do
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

end
