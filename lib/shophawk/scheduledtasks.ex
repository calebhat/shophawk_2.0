defmodule ScheduledTasks do
  use GenServer
  alias Shophawk.Shop.Csvimport
  alias Shophawk.JobbossExports
  alias Shophawk.Shop

  # Client API
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server callbacks
  def init([]) do
    ###  Can't run this while trying to update large chunks of data because the csv files over write each other at wrong times ###
    #Process.send_after(self(), :update_from_jobboss, 0) # Start the task after initialization

    :ets.new(:runlist_loads, [:set, :named_table, :public, read_concurrency: true])
    Process.send(self(), :update_all_runlist_loads, [])

    :ets.new(:birthdays_cache, [:set, :named_table, :public, read_concurrency: true])
    Process.send(self(), :load_current_week_birthdays, [])

    :ets.new(:weekly_dates, [:set, :named_table, :public, read_concurrency: true])
    Process.send(self(), :save_weekly_dates, [])

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

#runs every 5 minutes
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
    Process.send_after(self(), :update_all_runlist_loads, 300000)
    IO.puts("Loads Updated")

    {:noreply, nil}
  end

#runs 4 times a days
  def handle_info(:load_current_week_birthdays, _state) do
    employees = JobbossExports.export_employees
    today = Date.utc_today()
    day_of_week = Date.day_of_week(today)
    sunday = Date.add(today, -day_of_week)
    next_monday = Date.add(sunday, 8)
    this_weeks_birthdays =
      Enum.map(employees, fn emp ->
        normalized_birthday = %{emp.birthday | year: today.year} #changes the year to be this year for comparison
        if Date.before?(normalized_birthday, next_monday) and Date.after?(normalized_birthday, sunday) do
          emp
        end
      end)
      |> Enum.filter(fn item -> is_map(item) end)

    #TEST DATA
    #this_weeks_birthdays = [%{employee: "GV", user_value: "2774", first_name: "Greg", last_name: "Vike", hire_date: ~D[2010-06-28], birthday: ~D[2024-05-06]}]

    birthday_lines =
      Enum.reduce(this_weeks_birthdays, [], fn bday, acc ->
        acc ++ ["#{bday.first_name} #{bday.last_name} on #{Calendar.strftime(bday.birthday, "%A")} (#{bday.birthday.month}-#{bday.birthday.day})"]
      end)

    :ets.insert(:birthdays_cache, {:this_weeks_birthdays, birthday_lines})  # Store the data in ETS
    Process.send_after(self(), :load_current_week_birthdays, 1440000)
    IO.puts("This Weeks Birthdays Updated")
    {:noreply, nil}
  end

  def handle_info(:save_weekly_dates, _state) do
    today = Date.utc_today()
    day_of_week = Date.day_of_week(today)
    monday = Date.add(today, -(day_of_week - 1))
    friday = Date.add(monday, 4)
    next_monday = Date.add(monday, 7)
    next_friday = Date.add(next_monday, 4)
    :ets.insert(:weekly_dates, {:weekly_dates, %{monday: monday, friday: friday, next_monday: next_monday, next_friday: next_friday}})
    IO.puts("weekly dates updated")
    Process.send_after(self(), :load_current_week_birthdays, 1440000)
    {:noreply, nil}
  end

end
