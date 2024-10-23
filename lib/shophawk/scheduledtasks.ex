defmodule ScheduledTasks do
  use GenServer
  alias Shophawk.Shop

  # Client API
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server callbacks
  def init([]) do
    #Initial ETS Table settings
    :ets.insert(:runlist_loads, {:refresh_time, NaiveDateTime.utc_now()})
    :ets.insert(:runlist, {:refresh_time, NaiveDateTime.utc_now()})
    :ets.insert(:runlist_loads, {:data, [%{department: "ShopHawk Restarting, refresh in 1 minute", department_id: 0, weekone: 0, weektwo: 0, weekthree: 0, weekfour: 0}]})  # Store the data in ETS
    :ets.insert(:employees, {:data, Shophawk.Jobboss_db.employee_data})
    :ets.insert(:material_list, {:data, Shophawk.MaterialCache.load_all_material_and_sizes()})

    #inital Loading of Active jobs into cache
    Shophawk.Jobboss_db.load_all_active_jobs
    IO.puts("active jobs loaded into cache")

    # Initial scheduled tasks
    load_current_week_birthdays()
    save_weekly_dates()
    update_all_runlist_loads()
    ShophawkWeb.DashboardLive.Index.save_last_months_sales()
    ShophawkWeb.DashboardLive.Index.save_this_weeks_revenue()

    #tasks less than 1 minutes must be ran in the genserver.
    #All other functions here are ran with Quantum dep that is controlled from /config/config.ex file

    #Process.send_after(self(), :update_from_jobboss, 2000)
    {:ok, nil}
  end

  #runs every 7 seconds
  def handle_info(:update_from_jobboss, _state) do
    previous_check =
      case :ets.lookup(:runlist, :refresh_time) do
        [{:refresh_time, previous_check}] -> previous_check
        [] -> NaiveDateTime.add(NaiveDateTime.utc_now(), -20) #syncs previous 20 seconds if no previos time found.
      end
    :ets.insert(:runlist, {:refresh_time, NaiveDateTime.utc_now()})
    Shophawk.Jobboss_db.sync_recently_updated_jobs(previous_check)

    Process.send_after(self(), :update_from_jobboss, 7000) #runs again 7 seconds after finishing function.
    {:noreply, nil}
  end

  #runs every 5 minutes
  def update_all_runlist_loads do
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
    #Process.send_after(self(), :update_all_runlist_loads, 300000)
    IO.puts("Loads Updated")

    #{:noreply, nil}
  end

#runs once a day
  def load_current_week_birthdays do
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
    #Process.send_after(self(), :load_current_week_birthdays, 86400000)
    IO.puts("This Weeks Birthdays Updated")
    #{:noreply, nil}
  end

  def save_weekly_dates do
    today = Date.utc_today()
    day_of_week = Date.day_of_week(today)
    monday = Date.add(today, -(day_of_week - 1))
    friday = Date.add(monday, 4)
    next_monday = Date.add(monday, 7)
    next_friday = Date.add(next_monday, 4)
    :ets.insert(:slideshow, {:weekly_dates, %{monday: monday, friday: friday, next_monday: next_monday, next_friday: next_friday}})
    IO.puts("weekly dates updated")
    #Process.send_after(self(), :save_weekly_dates, 86500000)
    #{:noreply, nil}
  end

end
