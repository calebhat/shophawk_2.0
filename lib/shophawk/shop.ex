defmodule Shophawk.Shop do
  @moduledoc """
  The Shop context.
  """

  import Ecto.Query, warn: false
  alias Shophawk.Repo

 alias Shophawk.Shop.Runlist
 alias Shophawk.Shop.Department
 alias Shophawk.Shop.Workcenter
 alias Shophawk.Shop.Assignment
 alias Shophawk.RunlistImports

  def list_job(job) do #loads all operations for a job
    job_ops =
    Shophawk.RunlistCache.job(job)
    |> Enum.map(fn map ->
      map = case map do
        %{operation_service: nil} -> Map.put(map, :operation_service, nil)
        %{operation_service: ""} -> Map.put(map, :operation_service, nil)
        %{operation_service: value} -> Map.put(map, :operation_service, " -" <> value)
        _ -> map
      end
      |> Map.put(:status, status_change(map.status))
      map = if map.rev == nil, do: Map.put(map, :rev, ""), else: Map.put(map, :rev, ", Rev: " <> map.rev)
      if map.customer_po_line == nil, do: Map.put(map, :customer_po_line, ""), else: map
    end)
    [job | _tail] = job_ops
    {job_ops, sort_job_info(job)}
  end

  def sort_job_info(job) do
    job_manager = case job.note_text do
      nil -> ""
      _ ->
        job.note_text
        |> String.replace("\r", " ")
        |> String.replace("\n", " ")
        |> String.split(" ")
        |> Enum.slice(-2, 2)
        |> Enum.map(&(String.capitalize(&1, :ascii)))
        |> Enum.join(" ")
        |> String.trim()
    end
    %{}
    |> Map.put(:part_number, job.part_number <> job.rev)
    |> Map.put(:order_quantity, job.order_quantity)
    |> Map.put(:make_quantity, job.make_quantity)
    |> Map.put(:customer, job.customer)
    |> Map.put(:customer_po, job.customer_po)
    |> Map.put(:customer_po_line, job.customer_po_line)
    |> Map.put(:description, job.description)
    |> Map.put(:material, job.material)
    |> Map.put(:job_manager, job_manager)
  end

  defp status_change(status) do
    case status do
      "C" -> "Closed"
      "S" -> "Started"
      "O" -> "Open"
      _ -> status
    end
  end

  def import_all(operations) do #WARNING, THIS TAKES A MINUTE AND WILL OVERLOAD CHROME IF ALL DATA IS LOADED.
    operations
    |> Enum.chunk_every(1500)
    |> Enum.each(fn chunk -> Repo.insert_all(Runlist, chunk) end)
  end

  def find_matching_operations(operations_list) do
    query =
      from r in Runlist,
      where: r.job_operation in ^operations_list
      Repo.all(query)
    end


  def find_matching_job_ops(job_list) do #used in csvimport
    query =
      from r in Runlist,
      where: r.job in ^job_list
      Repo.all(query)
  end

  def toggle_mat_waiting(id) do
    op = Repo.get!(Runlist, id)
    new_matertial_waiting = !op.material_waiting
    Repo.update_all(
      from(r in Runlist, where: r.job == ^op.job),
      set: [material_waiting: new_matertial_waiting]
    )
  end

  @doc """
  Returns the list of runlists.

  ## Examples

      iex> list_runlists()
      [%Runlist{}, ...]

  """
  def list_runlists(workcenter_list, department) do #takes in a list of workcenters to load runlist items for
    #Shophawk.Jobboss_db.load_all_active_jobs()
    runlists = Shophawk.RunlistCache.get_runlist_ops(workcenter_list, department)
    IO.inspect(Enum.count(runlists))

    if Enum.empty?(runlists) do
      {[], [], []}
    else
      [first_row | _tail] = runlists
      last_row = List.last(runlists)
      first_row_id = first_row.id
      last_row_id = last_row.id
      blackout_dates = Shophawk.Jobboss_db.load_blackout_dates

      carryover_list =
        runlists
        |> Enum.reduce([], fn row, acc ->
          if row.est_total_hrs > department.capacity do
            [%{date: row.sched_start, hours: row.est_total_hrs, id: row.id} | acc]
          else
            acc
          end
        end)
        |> Enum.reduce([], fn %{date: date, hours: remaining_hours, id: id}, acc ->
          generate_daily_carryover_days(id, date, remaining_hours, department.capacity, acc, blackout_dates, 0)
        end)

      {date_rows_list, _, _} = #Make list of date & hours map for matching to date rows
        Enum.reduce_while(runlists, {[], nil, 0}, fn row, {acc, prev_sched_start, daily_hours} ->
          sched_start = row.sched_start
          daily_capacity = department.capacity * department.machine_count

          if prev_sched_start == sched_start do #for 2nd row and beyond
            new_daily_hours =
              case row.est_total_hrs do
                hours when hours < department.capacity -> Float.round(hours + daily_hours, 2)
                _ -> Float.round(daily_hours + department.capacity, 2)
              end

              if row.id == last_row_id do #checks for last row
                date_row = acc ++ [%{est_total_hrs: Float.round(new_daily_hours, 2), sched_start: sched_start, id: Date.to_string(sched_start), date_row_identifer: 0, hour_percentage: String.slice(Float.to_string(Float.ceil((daily_hours/daily_capacity)*100)), 0..-3)}] #last day
                new_acc = date_row ++ add_missing_date_rows(carryover_list, sched_start, nil, daily_capacity)
                {:halt, {new_acc, sched_start, Float.round(new_daily_hours, 2)}}
              else
                {:cont, {acc, sched_start, new_daily_hours}}
              end
          else #if a new day
            new_daily_hours = #only to pass on for next day accumulator
              case row.est_total_hrs do
                hours when hours < department.capacity ->
                  filtered_rows = Enum.filter(carryover_list, fn map ->
                    if sched_start == map.date && map.index > 0, do: true end)
                  Float.round(hours + get_date_sum(filtered_rows, sched_start), 2) #only add carryover hours at beginning of new day
                _ ->
                  filtered_rows = Enum.filter(carryover_list, fn map ->
                    if sched_start == map.date && map.index > 0, do: true end)
                  Float.round(department.capacity + get_date_sum(filtered_rows, sched_start), 2)
              end

            case row.id do #adds in date rows between operations
              ^first_row_id ->
                {:cont, {acc, sched_start, new_daily_hours}}

              ^last_row_id ->
                date_row = acc ++ [%{est_total_hrs: daily_hours, sched_start: prev_sched_start, id: Date.to_string(sched_start), date_row_identifer: 0, hour_percentage: String.slice(Float.to_string(Float.ceil((daily_hours/daily_capacity)*100)), 0..-3)}] #2nd to last day
                new_acc = date_row ++ add_missing_date_rows(carryover_list, prev_sched_start, sched_start, daily_capacity)
                date_row = new_acc ++ [%{est_total_hrs: (new_daily_hours), sched_start: sched_start, id: Date.to_string(sched_start), date_row_identifer: 0, hour_percentage: String.slice(Float.to_string(Float.ceil((new_daily_hours/daily_capacity)*100)), 0..-3)}] #last day
                new_acc = date_row ++ add_missing_date_rows(carryover_list, sched_start, nil, daily_capacity)
                {:halt, {new_acc, sched_start, new_daily_hours}}

              _ ->
                date_row = acc ++ [%{est_total_hrs: daily_hours, sched_start: prev_sched_start, id: Date.to_string(sched_start), date_row_identifer: 0, hour_percentage: String.slice(Float.to_string(Float.ceil((daily_hours/daily_capacity)*100)), 0..-3)}]
                new_acc = date_row ++ add_missing_date_rows(carryover_list, prev_sched_start, sched_start, daily_capacity)
                {:cont, {new_acc, sched_start, new_daily_hours}}
            end
          end
        end)

      complete_runlist =
        Enum.reduce(date_rows_list, [], fn date_row, acc ->
            dot_sorter = fn map ->
            case Map.get(map, :dots) do
              4 -> 0
              3 -> 1
              2 -> 2
              1 -> 3
              _ -> 4
            end
          end
          at_location_sorter = fn map ->
            exact_wc_vendor = String.replace(Map.get(map, :wc_vendor), " -#{map.operation_service}", "")
            currentop = Map.get(map, :currentop)
            case exact_wc_vendor do
              ^currentop -> 0
              _ -> 2
            end
          end

          main_ops =
            Enum.filter(runlists, fn %{sched_start: sched_start, status: status} -> sched_start == date_row.sched_start and status == "O"  end)
            |> Enum.sort_by(dot_sorter)
            |> Enum.sort_by(at_location_sorter)

          started_ops =
            Enum.filter(runlists, fn %{sched_start: sched_start, status: status} -> sched_start == date_row.sched_start and status == "S"  end)

          runners_list =
            Enum.filter(carryover_list, fn %{date: date, index: index} -> date == date_row.sched_start and index > 0 end)
            |> Enum.map(&(&1.id))
            |> Enum.uniq()

          runner_ops =
            Enum.filter(runlists, fn %{id: id} -> id in runners_list end)
            |> Enum.map(fn row -> Map.put(row, :runner, true) end)

          acc ++ [date_row] ++ main_ops ++ runner_ops ++ started_ops #add runner rows after [row] here
        end)

      jobs_that_ship_today =
        Enum.filter(runlists, fn op ->
          case Date.compare(Date.utc_today, op.job_sched_end) do
            :lt -> false
            :eq -> true
            :gt -> true
          end
        end)
        |> Enum.filter(fn op ->
          has_ship_op = Enum.reduce_while(load_job_operations(op.job), false, fn op, _acc -> if op.wc_vendor == "A-SHIP", do: {:halt, true}, else: {:cont, false} end)
          if has_ship_op == true, do: true, else: false
        end)
        |> Enum.uniq()
        |> Enum.map(fn op ->
          op
          |> Map.put(:ships_today, true)
          |> Map.put(:dots, 3)
          |> Map.reject(fn {key, _value} -> key == :__meta__ end)
        end)

      jobs_that_ship_today=
        if Enum.empty?(jobs_that_ship_today) do
          jobs_that_ship_today
        else
          [%{ships_today_header: true, date_row_identifer: -1, id: -1}] ++ jobs_that_ship_today ++ [%{ships_today_footer: true, date_row_identifer: -1, id: -1}]
        end

      complete_runlist = #adds shipping today if needed and removes ops furthur down list if found
        if Enum.empty?(jobs_that_ship_today) do
          complete_runlist
        else
          complete_runlist =
            Enum.map(complete_runlist, fn op ->
              case Enum.find(jobs_that_ship_today, fn ships_today -> op.id == ships_today.id end) do
                nil -> op
                _found_ships_today -> %{id: op.id, date_row_identifer: nil, job: op.job, dots: 3, sched_start: op.sched_start, order_quantity: op.order_quantity, est_total_hrs: op.est_total_hrs, runner: op.runner, status: op.status, shipping_today: true}
              end
            end)
          jobs_that_ship_today ++ complete_runlist
        end
        |> Enum.map(fn op -> #add extra keys to each map if needed
          Map.put_new(op, :runner, false)
        end)

      {complete_runlist, calc_weekly_load(date_rows_list, department, runlists), jobs_that_ship_today}
    end
  end

  def list_workcenter(workcenter_name) do #takes in a list of workcenters to load runlist items for
    workcenter_name = [workcenter_name]

    runlists = Shophawk.RunlistCache.get_runlist_ops(workcenter_name, %{show_jobs_started: true})

    if Enum.empty?(runlists) do
      []
    else
      [first_row | _tail] = runlists
      last_row = List.last(runlists)
      first_row_id = first_row.id
      last_row_id = last_row.id

      {date_rows_list, _, _} = #Make list of date & hours map for matching to date rows
        Enum.reduce_while(runlists, {[], nil, 0}, fn row, {acc, prev_sched_start, daily_hours} ->
          sched_start = row.sched_start

          if prev_sched_start == sched_start do #for 2nd row and beyond
            new_daily_hours = Float.round(daily_hours + row.est_total_hrs, 2)
              if row.id == last_row_id do #checks for last row
              date_row = acc ++ [%{est_total_hrs: Float.round(new_daily_hours, 2), sched_start: sched_start, id: Date.to_string(sched_start), date_row_identifer: 0}] #last day
                {:halt, {date_row, sched_start, daily_hours}}
              else
                {:cont, {acc, sched_start, new_daily_hours}}
              end
          else #if a new day
            new_daily_hours = row.est_total_hrs#only to pass on for next day accumulator

            case row.id do #adds in date rows between operations
              ^first_row_id ->
                {:cont, {acc, sched_start, new_daily_hours}}

              ^last_row_id ->
                date_row = acc ++ [%{est_total_hrs: daily_hours, sched_start: prev_sched_start, id: Date.to_string(sched_start), date_row_identifer: 0}] #2nd to last day
                date_row = date_row ++ [%{est_total_hrs: (new_daily_hours), sched_start: sched_start, id: Date.to_string(sched_start), date_row_identifer: 0}] #last day
                {:halt, {date_row, sched_start, daily_hours}}

              _ ->
                date_row = acc ++ [%{est_total_hrs: daily_hours, sched_start: prev_sched_start, id: Date.to_string(sched_start), date_row_identifer: 0}]
                {:cont, {date_row, sched_start, new_daily_hours}}
            end
          end
        end)

      complete_runlist =
        Enum.reduce(date_rows_list, [], fn date_row, acc ->
          dot_sorter = fn map ->
            case Map.get(map, :dots) do
              4 -> 0
              3 -> 1
              2 -> 2
              1 -> 3
              _ -> 4
            end
          end
          at_location_sorter = fn map ->
            exact_wc_vendor = String.replace(Map.get(map, :wc_vendor), " -#{map.operation_service}", "")
            currentop = Map.get(map, :currentop)
            case exact_wc_vendor do
              ^currentop -> 0
              _ -> 2
            end
          end
          main_ops =
            Enum.filter(runlists, fn %{sched_start: sched_start, status: status} -> sched_start == date_row.sched_start and status == "O"  end)
            |> Enum.sort_by(dot_sorter)
            |> Enum.sort_by(at_location_sorter)
          started_ops =
            Enum.filter(runlists, fn %{sched_start: sched_start, status: status} -> sched_start == date_row.sched_start and status == "S"  end)
          acc ++ [date_row] ++ main_ops ++ started_ops
        end)

      jobs_that_ship_today =
        Enum.filter(runlists, fn op ->
          case Date.compare(Date.utc_today, op.job_sched_end) do
            :lt -> false
            :eq -> true
            :gt -> true
          end
        end)
        |> Enum.filter(fn op -> #filter for only jobs with "A-SHIP"
          has_ship_op = Enum.reduce_while(load_job_operations(op.job), false, fn op, _acc -> if op.wc_vendor == "A-SHIP", do: {:halt, true}, else: {:cont, false} end)
          if has_ship_op == true, do: true, else: false
        end)
        |> Enum.uniq()
        |> Enum.map(fn op ->
          Map.from_struct(op)
          |> Map.put(:ships_today, true)
          |> Map.put(:dots, 3)
          |> Map.reject(fn {key, _value} -> key == :__meta__ end)
        end)

      jobs_that_ship_today=
        if Enum.empty?(jobs_that_ship_today) do
          jobs_that_ship_today
        else
          [%{ships_today_header: true, date_row_identifer: -1, id: -1}] ++ jobs_that_ship_today ++ [%{ships_today_footer: true, date_row_identifer: -1, id: -1}]
        end

      #adds shipping today if needed and removes ops furthur down list if found
      if Enum.empty?(jobs_that_ship_today) do
        complete_runlist
      else
        complete_runlist =
          Enum.map(complete_runlist, fn op ->
            case Enum.find(jobs_that_ship_today, fn ships_today -> op.id == ships_today.id end) do
              nil -> op
              _found_ships_today -> %{id: op.id, job: op.job, dots: 3, sched_start: op.sched_start, order_quantity: op.order_quantity, est_total_hrs: op.est_total_hrs, runner: op.runner, status: op.status, shipping_today: true}
            end
          end)
        jobs_that_ship_today ++ complete_runlist
      end
    end
  end

  def load_job_operations(job) do #loads all operations for a job
    Shophawk.RunlistCache.job(job)
  end

  def get_all_active_jobs_from_db() do #loads all operations for a job
    query =
    from r in Runlist,
    where: r.job_status == "Active"
    Repo.all(query)
    |> Enum.map(fn map -> Map.get(map, :job) end)
  end

  defp calc_weekly_load(date_rows, department, runlists) do
    today = Date.utc_today()
    weekly_hours_list =
      Enum.reduce(date_rows, %{weekone: 0, weektwo: 0, weekthree: 0, weekfour: 0}, fn row, acc ->
        start = row.sched_start
        cond do
          Date.before?(start, Date.add(today, 7)) -> Map.update(acc, :weekone, 0, fn hours -> Float.round(hours + row.est_total_hrs, 2) end)
          Date.after?(start, Date.add(today, 6)) and Date.before?(start, Date.add(today, 14)) -> Map.update(acc, :weektwo, 0, fn hours -> Float.round(hours + row.est_total_hrs, 2) end)
          Date.after?(start, Date.add(today, 13)) and Date.before?(start, Date.add(today, 21)) -> Map.update(acc, :weekthree, 0, fn hours -> Float.round(hours + row.est_total_hrs, 2) end)
          Date.after?(start, Date.add(today, 20)) and Date.before?(start, Date.add(today, 28)) -> Map.update(acc, :weekfour, 0, fn hours -> Float.round(hours + row.est_total_hrs, 2) end)
          true -> acc
        end
      end)

    weekly_hours_with_act_run_hrs_subtracted =
      Enum.reduce(runlists, weekly_hours_list, fn row, acc ->
        start = row.sched_start
        cond do
          Date.before?(start, Date.add(today, 7)) -> Map.update(acc, :weekone, 0, fn hours -> Float.round(hours - row.act_run_hrs, 2) end)
          Date.after?(start, Date.add(today, 6)) and Date.before?(start, Date.add(today, 14)) -> Map.update(acc, :weektwo, 0, fn hours -> Float.round(hours - row.act_run_hrs, 2) end)
          Date.after?(start, Date.add(today, 13)) and Date.before?(start, Date.add(today, 21)) -> Map.update(acc, :weekthree, 0, fn hours -> Float.round(hours - row.act_run_hrs, 2) end)
          Date.after?(start, Date.add(today, 20)) and Date.before?(start, Date.add(today, 28)) -> Map.update(acc, :weekfour, 0, fn hours -> Float.round(hours - row.act_run_hrs, 2) end)
          true -> acc
        end
      end)
    weekly_hours_with_act_run_hrs_subtracted
    |> Map.update!(:weekone, &(Kernel.round((&1 / (department.capacity * department.machine_count * 5)) * 100)))
    |> Map.update!(:weektwo, &(Kernel.round((&1 / (department.capacity * department.machine_count * 5)) * 100)))
    |> Map.update!(:weekthree, &(Kernel.round((&1 / (department.capacity * department.machine_count * 5)) * 100)))
    |> Map.update!(:weekfour, &(Kernel.round((&1 / (department.capacity * department.machine_count * 5)) * 100)))
    |> Map.put_new(:department, department.department)
    |> Map.put_new(:department_id, department.id)
  end

  defp add_missing_date_rows(carryover_list, start, stop, capacity) do #adds date rows for carryover hours if non exist
    case {start, stop} do
      {nil, _stop} -> []
      {start, nil} ->
        filtered_rows = Enum.filter(carryover_list, fn map -> if Date.compare(map.date, start) == :gt, do: true end)
        Enum.map(Enum.uniq_by(filtered_rows, &(&1.date)), fn %{date: date, hours: hours} ->
        %{sched_start: date, est_total_hrs: get_date_sum(filtered_rows, date), id: 0, hour_percentage: String.slice(Float.to_string(Float.ceil(hours/capacity*100)), 0..-3)} end)
      {start, stop} ->
        filtered_rows = Enum.filter(carryover_list, fn map -> Date.compare(map.date, start) == :gt and Date.compare(map.date, stop) == :lt end)
        Enum.map(Enum.uniq_by(filtered_rows, &(&1.date)), fn %{date: date, hours: hours} ->
        %{sched_start: date, est_total_hrs: get_date_sum(filtered_rows, date), id: 0, hour_percentage: String.slice(Float.to_string(Float.ceil(hours/capacity*100)), 0..-3)} end)
    end
  end

  defp get_date_sum(list, target_date) do
    if list != [] do
      list
      |> Enum.filter(fn %{date: date} -> date == target_date end)
      |> Enum.reduce(0, fn %{hours: hours}, acc -> acc + hours end)
      |> Float.round(2)
    else
      0
    end
  end

  defp generate_daily_carryover_days(id, date, remaining_hours, daily_capacity, acc, blackout_dates, index) do
    if remaining_hours > 0 do
      hours_today = min(remaining_hours, daily_capacity)
      new_remaining_hours = remaining_hours - hours_today
      new_date = advance_to_next_workday(date, blackout_dates)

      [%{id: id, date: date, hours: hours_today, index: index} | generate_daily_carryover_days(id, new_date, new_remaining_hours, daily_capacity, acc, blackout_dates, index + 1)]
    else
      acc
    end
  end

  defp advance_to_next_workday(date, blackout_dates) do
    new_date = Date.add(date, 1)
    if Date.day_of_week(new_date) in [6, 7] or Enum.member?(blackout_dates, new_date) do
      advance_to_next_workday(new_date, blackout_dates)
    else
      new_date
    end
  end

  @doc """
  Gets a single runlist.

  Raises `Ecto.NoResultsError` if the Runlist does not exist.

  ## Examples

      iex> get_runlist!(123)
      %Runlist{}

      iex> get_runlist!(456)
      ** (Ecto.NoResultsError)

  """
  def get_runlist!(id), do: Repo.get!(Runlist, id)

  def get_runlist_by_job_operation(job_operation) do
    Repo.get_by(Runlist, job_operation: job_operation)
  end

  def get_hot_jobs() do
    query =
      from r in Runlist,
      where: r.dots > 0 and r.status == "O",
      order_by: [desc: r.id],
      select: %Runlist{id: r.id, job: r.job, description: r.description, customer: r.customer, part_number: r.part_number, make_quantity: r.make_quantity, dots: r.dots, currentop: r.currentop, job_sched_end: r.job_sched_end}
    hot_jobs = Repo.all(query)
    grouped_ops = Enum.group_by(hot_jobs, &(&1.job))
    keys_to_keep = [:id, :job,:description, :customer, :part_number, :make_quantity, :dots, :currentop, :job_sched_end]
    Enum.map(grouped_ops, fn {_job, operations} ->
      Enum.max_by(operations, &(&1.id))
    end)
    |> Enum.map(&Map.take(&1, keys_to_keep))
    |> Enum.sort_by(&(&1.job_sched_end), Date)
    |> Enum.slice(0..9)
  end

  @doc """
  Creates a runlist.

  ## Examples

      iex> create_runlist(%{field: value})
      {:ok, %Runlist{}}

      iex> create_runlist(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_runlist(attrs \\ %{}) do
    changeset = Runlist.changeset(%Runlist{}, attrs)
    Repo.insert(changeset)
  end

  @doc """
  Updates a runlist.

  ## Examples

      iex> update_runlist(runlist, %{field: new_value})
      {:ok, %Runlist{}}

      iex> update_runlist(runlist, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_runlist(%Runlist{} = runlist, attrs) do
    changeset = Runlist.changeset(runlist, attrs)
    Repo.update(changeset)
  end

  @doc """
  Deletes a runlist.

  ## Examples

      iex> delete_runlist(runlist)
      {:ok, %Runlist{}}

      iex> delete_runlist(runlist)
      {:error, %Ecto.Changeset{}}

  """
  def delete_runlist(%Runlist{} = runlist) do
    Repo.delete(runlist)
  end

  def delete_listed_runlist(runlists) do
    jobs_to_delete = Enum.map(runlists, fn op -> op.job end)
    from(r in Runlist, where: r.job in ^jobs_to_delete) |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking runlist changes.

  ## Examples

      iex> change_runlist(runlist)
      %Ecto.Changeset{data: %Runlist{}}

  """
  def change_runlist(%Runlist{} = runlist, attrs \\ %{}) do
    Runlist.changeset(runlist, attrs)
  end

  def create_assignment(department_id, attrs \\ %{}) do
    get_department!(department_id)
    |> Ecto.build_assoc(:assignments)
    |> Ecto.Changeset.cast(attrs, [:assignment])
    |> Repo.insert()
  end

  def get_assignment(assignment_name, department_id) do
    Repo.get_by!(Assignment, [assignment: assignment_name, department_id: department_id])
  end

  def update_assignment(id, new_assignment, old_assignment) do
    Repo.get_by!(Assignment, id: id)
    |> Assignment.changeset(%{assignment: new_assignment})
    |> Repo.update()
    Repo.update_all(
      from(r in Runlist, where: r.assignment == ^old_assignment),
      set: [assignment: new_assignment]
    )
  end

  def change_assignment(%Assignment{} = assignment, attrs \\ %{}) do
    Assignment.changeset(assignment, attrs)
  end

  def list_workcenters do
    Repo.all(Workcenter)
  end

  def get_workcenter!(id), do: Repo.get!(Workcenter, id)

  def get_workcenter_by_name(workcenter) do
    Repo.get_by!(Workcenter, workcenter: workcenter)
  end

  def create_workcenter(attrs \\ %{}) do
    changeset = Workcenter.changeset(%Workcenter{}, attrs)
    Repo.insert(changeset)
  end

  defp extract_workcenters(attrs) do
    workcenter_names = attrs["workcenters"] |> Enum.map(&Map.get(&1, "workcenter"))
    Workcenter
    |> where([w], w.workcenter in ^workcenter_names)
    |> Repo.all()
  end

    @doc """
  Creates a department.

  ## Examples

      iex> create_department(%{field: value})
      {:ok, %Department{}}

      iex> create_department(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_department(attrs \\ %{}) do
    %Department{}
    |> Department.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:workcenters, extract_workcenters(attrs))
    |> Repo.insert()
  end

    @doc """
  Returns the list of departments.

  ## Examples

      iex> list_departments()
      [%Department{}, ...]

  """
  def list_departments do
    Repo.all(Department) |> Repo.preload(:workcenters)
   end

  def get_department_by_name(department) do
    Repo.get_by!(Department, department: department)  |> Repo.preload(:workcenters)
  end

    @doc """
  Gets a single department.

  Raises `Ecto.NoResultsError` if the Department does not exist.

  ## Examples

      iex> get_department!(123)
      %Department{}

      iex> get_department!(456)
      ** (Ecto.NoResultsError)

  """
  def get_department!(id) do
    Repo.get!(Department, id)
    |> Repo.preload([workcenters: from(c in Workcenter, order_by: c.workcenter)])
    |> Repo.preload([assignments: from(c in Assignment, order_by: c.assignment)])
  end

  @doc """
  Updates a department.

  ## Examples

      iex> update_department(department, %{field: new_value})
      {:ok, %Department{}}

      iex> update_department(department, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_department(%Department{} = department, attrs) do
    department
    |> Department.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:workcenters, extract_workcenters(attrs))
    |> Repo.update()
  end

  @doc """
  Deletes a department.

  ## Examples

      iex> delete_department(department)
      {:ok, %Department{}}

      iex> delete_department(department)
      {:error, %Ecto.Changeset{}}

  """
  def delete_department(%Department{} = department) do
    Repo.delete(department)
  end

  def delete_assignment(id) do
    Repo.get_by!(Assignment, id: id)
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking department changes.

  ## Examples

      iex> change_department(department)
      %Ecto.Changeset{data: %Department{}}

  """
  def change_department(%Department{} = department, attrs \\ %{}) do
    Department.changeset(department, attrs)
  end
end
