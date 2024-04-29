defmodule ScheduledTasks do
  use GenServer
  alias Shophawk.Shop.Csvimport
  alias Shophawk.Shop

  # Client API
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server callbacks
  def init([]) do
    ###  Can't run this while trying to update large chunks of data because the csv files over write each other at wrong times ###
    Process.send_after(self(), :update_from_jobboss, 0) # Start the task after initialization

    :ets.new(:runlist_loads, [:set, :named_table, :public, read_concurrency: true])
    Process.send_after(self(), :update_all_runlist_loads, 0)
    {:ok, nil}
  end

  #runs every 5 seconds
  def handle_info(:update_from_jobboss, _state) do
    # 1. Execute your function here
    Csvimport.scheduled_runlist_update(self())
    {:noreply, nil}
  end

  def handle_info(:update_from_jobboss_complete, state) do
    Process.send_after(self(), :update_from_jobboss, 5000)
    {:noreply, state}
  end

  #runs every 30 seconds
  def handle_info(:update_all_runlist_loads, _state) do
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
    :ets.insert(:runlist_loads, {:data, department_loads})  # Store the data in ETS
    Process.send_after(self(), :update_all_runlist_loads, 6000000)
    IO.puts("Loads Updated")

    {:noreply, nil}
  end

end
