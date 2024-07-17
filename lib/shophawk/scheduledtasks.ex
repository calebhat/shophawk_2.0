defmodule ScheduledTasks do
  use GenServer
  alias Shophawk.RunlistExports
  alias Shophawk.RunlistImports
  alias Shophawk.GeneralExports
  alias Shophawk.Shop

  # Client API
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server callbacks
  def init([]) do
    #create all ets caches needed
    :ets.new(:runlist, [:set, :named_table, :public, read_concurrency: true])
    :ets.new(:job_attachments, [:set, :named_table, :public, read_concurrency: true])
    :ets.new(:runlist_loads, [:set, :named_table, :public, read_concurrency: true])
    :ets.new(:slideshow, [:set, :named_table, :public, read_concurrency: true])
    :ets.new(:employees, [:set, :named_table, :public, read_concurrency: true])

    #Initial ETS Table settings
    :ets.insert(:runlist_loads, {:refresh_time, NaiveDateTime.utc_now()})
    :ets.insert(:runlist, {:refresh_time, NaiveDateTime.utc_now()})
    :ets.insert(:runlist_loads, {:data, [%{department: "ShopHawk Restarting, refresh in 1 minute", department_id: 0, weekone: 0, weektwo: 0, weekthree: 0, weekfour: 0}]})  # Store the data in ETS
    :ets.insert(:employees, {:data, Shophawk.Jobboss_db.employee_data})

    #inital Loading of Active jobs into cache
    Shophawk.Jobboss_db.load_all_active_jobs
    IO.puts("active jobs loaded into cache")

    #repeating scheduled functions
    Process.send_after(self(), :update_all_runlist_loads, 100)
    Process.send_after(self(), :load_current_week_birthdays,100)
    Process.send_after(self(), :save_weekly_dates, 100)
    Process.send_after(self(), :update_from_jobboss, 100)

    {:ok, nil}
  end

  #runs every 7 seconds
  def handle_info(:update_from_jobboss, _state) do
    [{:refresh_time, previous_check}] = :ets.lookup(:runlist, :refresh_time)
    :ets.insert(:runlist, {:refresh_time, NaiveDateTime.utc_now()})
    Shophawk.Jobboss_db.sync_recently_updated_jobs(previous_check)
    Process.send_after(self(), :update_from_jobboss, 7000)
    {:noreply, nil}
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
        {_runlist, weekly_load, _jobs_that_ship_today} = Shop.list_runlists(workcenters, Shop.get_department_by_name(department_name))
        acc ++ [weekly_load]
      end)
    :ets.insert(:runlist_loads, {:data, department_loads})  # Store the data in ETS
    Process.send_after(self(), :update_all_runlist_loads, 300000)
    IO.puts("Loads Updated")

    {:noreply, nil}
  end

#runs once a day
  def handle_info(:load_current_week_birthdays, _state) do
    employees = Shophawk.Jobboss_db.employee_data
    :ets.insert(:employees, {:data, employees})
    today = Date.utc_today()
    day_of_week = Date.day_of_week(today)
    sunday = Date.add(today, -day_of_week)
    next_monday = Date.add(sunday, 8)
    this_weeks_birthdays =
      Enum.reject(employees, fn e -> e.birthday == nil end)
      |> Enum.map( fn emp ->
        normalized_birthday = %{emp.birthday | year: today.year} #changes the year to be this year for comparison
        if Date.before?(normalized_birthday, next_monday) and Date.after?(normalized_birthday, sunday) do
          Map.put(emp, :birthday, normalized_birthday)
        end
      end)
      |> Enum.filter(fn item -> is_map(item) end)
    birthday_lines =
      Enum.reduce(this_weeks_birthdays, [], fn bday, acc ->
        acc ++ ["#{bday.first_name} #{bday.last_name} on #{Calendar.strftime(bday.birthday, "%A")} (#{bday.birthday.month}-#{bday.birthday.day})"]
      end)

    :ets.insert(:slideshow, {:this_weeks_birthdays, birthday_lines})  # Store the data in ETS
    Process.send_after(self(), :load_current_week_birthdays, 86400000)
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
    :ets.insert(:slideshow, {:weekly_dates, %{monday: monday, friday: friday, next_monday: next_monday, next_friday: next_friday}})
    IO.puts("weekly dates updated")
    Process.send_after(self(), :save_weekly_dates, 86400000)
    {:noreply, nil}
  end

end
