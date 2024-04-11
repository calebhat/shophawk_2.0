defmodule ScheduledTasks do
  use GenServer
  alias Shophawk.Shop.Csvimport

  # Client API
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server callbacks
  def init([]) do
    Process.send_after(self(), :run_task, 0) # Start the task after initialization
    {:ok, nil}
  end

  def handle_info(:run_task, _state) do
    # 1. Execute your function here
    Csvimport.update_operations(self())
    #IO.puts("import Started")
    {:noreply, nil}
  end

  def handle_info(:import_done, state) do
    Process.send_after(self(), :run_task, 5000)
    {:noreply, state}
  end

end
