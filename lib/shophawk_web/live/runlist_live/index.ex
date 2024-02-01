defmodule ShophawkWeb.RunlistLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shop
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop.Department
  alias Shophawk.Shop.Csvimport
  alias Shophawk.Shop.Assignment

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(department_id: nil) |> stream(:runlists, []) |> assign(:department, %{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:departments,  ["Select Department" | Shop.list_departments() |> Enum.map(&(&1.department)) |> Enum.sort] )

      IO.inspect(socket.assigns.live_action)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do

        socket =
          socket
          |> assign(:page_title, "Listing Runlists")
          |> assign(:runlist, nil)

          socket =
          if Map.has_key?(socket.assigns.department, :department) do
            IO.inspect( socket.assigns.department.department)
            IO.inspect(load_runlist(socket, socket.assigns.department.department))
            load_runlist(socket, socket.assigns.department.department)
          else
            socket
          end

          socket
          #

          #load_runlist(socket, department)

     #   if socket.assigns.department != "" do
     #     IO.inspect(socket.assigns.department.department)
     #     handle_event("select_department", %{"selection" => socket.assigns.department.department}, socket)
     #   end


        #if socket.assigns do
        #IO.inspect(socket.assigns.department.department)
        #end

        #need to get department value passed through to here.
        #if department == nil, set it to "select department"
        #def handle_event("select_department", %{"selection" => department}, socket)

        #socket
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Runlist")
    |> assign(:runlist, Shop.get_runlist!(id))
  end

#  defp apply_action(socket, :new, _params) do
#    socket
#    |> assign(:page_title, "New Runlist")
#    |> assign(:runlist, %Runlist{})
#  end

  defp apply_action(socket, :edit_department, %{"id" => id}) do
    Csvimport.update_workcenters()
    socket
    |> assign(:page_title, "Edit Department")
    |> assign(:department, Shop.get_department!(id))
  end

  defp apply_action(socket, :new_department, _params) do
    Csvimport.update_workcenters()

    socket
    |> assign(:page_title, "New Department")
    |> assign(:department, %Department{})
    |> assign(:workcenters, Shop.list_workcenters())
  end

  defp apply_action(socket, :new_assignment, %{"id" => id}) do
    IO.inspect(socket.assigns.streams.runlists)
    socket =
      socket
      |> assign(:page_title, "New Assignment")
      |> assign(:department_id, id)
      |> assign(:assignment, %Assignment{})
      |> stream(:runlists, [], reset: true)
    socket
  end

  #@impl true
  #def handle_info({ShophawkWeb.RunlistLive.FormComponent, {:saved, runlist}}, socket) do
  #  {:noreply, stream_insert(socket, :runlists, runlist)}
  #end

  @impl true
  def handle_info({ShophawkWeb.DepartmentLive.FormComponent, {:saved, department}}, socket) do
    department_list =
      Shop.list_departments()
      |> Enum.map(&(&1.department))

    {:noreply, socket}
  end

  def handle_info({ShophawkWeb.RunlistLive.AssignmentForm, {:saved, assignment}}, socket) do
    {:noreply, socket}
  end

#  @impl true
#  def handle_event("delete", %{"id" => id}, socket) do
#    runlist = Shop.get_runlist!(id)
#    {:ok, _} = Shop.delete_runlist(runlist)
#
#    {:noreply, stream_delete(socket, :runlists, runlist)}
#  end

  def handle_event("select_department", %{"selection" => department}, socket) do
    {:noreply, load_runlist(socket, department)}
  end

  defp load_runlist(socket, department) do
    socket =
      case department do
        "Select Department" ->
          socket =
            socket
            |> assign(department_id: nil)
            |> stream(:runlists, [], reset: true)

        _ -> department = Shop.get_department_by_name(department)
        workcenter_list = for %Shophawk.Shop.Workcenter{workcenter: wc} <- department.workcenters, do: wc
        runlists =
          Shop.list_runlists(workcenter_list)
        socket =
          socket
          |> assign(department: department)
          |> assign(department_id: department.id)
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

  def handle_event("importall", _, socket) do
    tempjobs = Csvimport.import_operations()
    count = Enum.count(tempjobs)
    IO.puts(count)
    socket

    {:noreply, stream(socket, :runlists, [])}
    #{:noreply, stream(socket, :runlists, Shop.list_runlists())}
  end



  def handle_event("5_minute_import", _, socket) do
    Csvimport.update_operations()
    #IO.puts(Enum.count(tempjobs))
    socket

    {:noreply, stream(socket, :runlists, [])}
    #{:noreply, stream(socket, :runlists, Shop.list_runlists())}
  end

end
