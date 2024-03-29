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
 alias Shophawk.Shop.Csvimport

  def list_job(job) do
    query =
      from r in Runlist,
      where: r.job == ^job,
      order_by: [asc: r.sequence]

    jobs =
    Repo.all(query)
    |> Enum.map(fn map ->
      map = case map do
        %{operation_service: nil} -> Map.put(map, :operation_service, nil)
        %{operation_service: value} -> Map.put(map, :operation_service, " -" <> value)
        _other_map -> _other_map
      end
      |> Map.put(:status, status_change(map.status))
    end)

    {jobs, sort_job_info(jobs)}
  end

  def sort_job_info([job | _rest]) do
    %{}
    |> Map.put(:part_number, job.part_number <> " Rev: " <> job.rev)
    |> Map.put(:order_quantity, job.order_quantity)
    |> Map.put(:customer, job.customer)
    |> Map.put(:customer_po, job.customer_po)
    |> Map.put(:customer_po_line, Integer.to_string(job.customer_po_line))
    |> Map.put(:description, job.description)
    |> Map.put(:material, job.material)
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

  def find_matching_operations(operations) do #used in csvimport
    query =
      from r in Runlist,
      where: r.job_operation in ^operations
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
    query =
      from r in Runlist,
        where: r.wc_vendor in ^workcenter_list,
        where: not is_nil(r.job_sched_end),
        order_by: [asc: r.sched_start, asc: r.job],
        select: %Runlist{id: r.id, job: r.job, description: r.description, wc_vendor: r.wc_vendor, operation_service: r.operation_service, sched_start: r.sched_start, job_sched_end: r.job_sched_end, customer: r.customer, part_number: r.part_number, order_quantity: r.order_quantity, material: r.material, dots: r.dots, currentop: r.currentop, material_waiting: r.material_waiting, est_total_hrs: r.est_total_hrs, assignment: r.assignment, status: r.status, act_run_hrs: r.act_run_hrs}

    query = #checks if "show jobs started is checked and load them.
      if department.show_jobs_started do
      query |> where([r], r.status == "O" or r.status == "S")
      else
        query |> where([r], r.status == "O")
    end

    runlists = Repo.all(query)
    |> Enum.map(fn row ->
      case row.operation_service do
        nil -> row
        _ -> Map.put(row, :wc_vendor, "#{row.wc_vendor} -#{row.operation_service}")
      end
    end)

    if Enum.empty?(runlists) do
      {[], []}
    else
      [first_row | tail] = runlists
      [second_row | _tail] = tail
      last_row = List.last(runlists)
      first_row_id = first_row.id
      last_row_id = last_row.id
      blackout_dates = Csvimport.load_blackout_dates

      #generate list of maps with just days with extra hours %{date: date, hours: hours, id: id}
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

          if prev_sched_start == sched_start do #for 2nd row and beyond
            new_daily_hours =
              case row.est_total_hrs do
                hours when hours < department.capacity -> Float.round(hours + daily_hours, 2)
                _ -> Float.round(daily_hours + department.capacity, 2)
              end

              if row.id == last_row_id do #checks for last row
              date_row = acc ++ [%{est_total_hrs: Float.round(new_daily_hours, 2), sched_start: sched_start, id: 0}] #last day
                new_acc = date_row ++ add_missing_date_rows(carryover_list, sched_start, nil)
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
                date_row = acc ++ [%{est_total_hrs: daily_hours, sched_start: prev_sched_start, id: 0}] #2nd to last day
                new_acc = date_row ++ add_missing_date_rows(carryover_list, prev_sched_start, sched_start)
                date_row = new_acc ++ [%{est_total_hrs: (new_daily_hours), sched_start: sched_start, id: 0}] #last day
                new_acc = date_row ++ add_missing_date_rows(carryover_list, sched_start, nil)
                {:halt, {new_acc, sched_start, new_daily_hours}}

              _ ->
                date_row = acc ++ [%{est_total_hrs: daily_hours, sched_start: prev_sched_start, id: 0}]
                new_acc = date_row ++ add_missing_date_rows(carryover_list, prev_sched_start, sched_start)
                {:cont, {new_acc, sched_start, new_daily_hours}}
            end
          end
        end)

      {complete_runlist, _} =
        Enum.reduce_while(date_rows_list, {[], nil}, fn date_row, {acc, prev_sched_start} ->
          runners_list =
            Enum.filter(carryover_list, fn %{date: date, index: index} -> date == date_row.sched_start and index > 0 end)
            |> Enum.map(fn row -> row.id end)
            |> Enum.uniq
            |> Enum.sort

          dot_sorter = fn map ->
            case Map.get(map, :dots) do
              4 -> 0
              3 -> 1
              2 -> 2
              1 -> 3
              _ -> 4
            end
          end

          main_ops =
            Enum.filter(runlists, fn %{sched_start: sched_start, status: status} -> sched_start == date_row.sched_start and status == "O"  end)
            |> Enum.sort_by(dot_sorter)

          started_ops =
            Enum.filter(runlists, fn %{sched_start: sched_start, status: status} -> sched_start == date_row.sched_start and status == "S"  end)

          runner_ops =
            Enum.filter(runlists, fn %{id: id} -> id in runners_list end)
            |> Enum.map(fn row -> Map.put(row, :runner, true) end)

          {:cont, {acc ++ [date_row] ++ main_ops ++ runner_ops ++ started_ops, date_row.sched_start}} #add runner rows after [row] here

        end)
      {complete_runlist, calc_weekly_load(date_rows_list, department)}
    end
  end

  defp calc_weekly_load(date_rows, department) do
    today = Date.utc_today()
    weekly_hours =
      Enum.reduce(date_rows, %{weekone: 0, weektwo: 0, weekthree: 0, weekfour: 0}, fn row, acc ->
        start = row.sched_start
        acc =
          cond do
            Date.before?(start, Date.add(today, 7)) -> Map.update(acc, :weekone, 0, fn hours -> Float.round(hours + row.est_total_hrs, 2) end)
            Date.after?(start, Date.add(today, 6)) and Date.before?(start, Date.add(today, 14)) -> Map.update(acc, :weektwo, 0, fn hours -> Float.round(hours + row.est_total_hrs, 2) end)
            Date.after?(start, Date.add(today, 13)) and Date.before?(start, Date.add(today, 21)) -> Map.update(acc, :weekthree, 0, fn hours -> Float.round(hours + row.est_total_hrs, 2) end)
            Date.after?(start, Date.add(today, 20)) and Date.before?(start, Date.add(today, 28)) -> Map.update(acc, :weekfour, 0, fn hours -> Float.round(hours + row.est_total_hrs, 2) end)
            true -> acc
          end
      end)
    weekly_hours =
      weekly_hours
      |> Map.update!(:weekone, &(Kernel.round((&1 / (department.capacity * department.machine_count * 5)) * 100)))
      |> Map.update!(:weektwo, &(Kernel.round((&1 / (department.capacity * department.machine_count * 5)) * 100)))
      |> Map.update!(:weekthree, &(Kernel.round((&1 / (department.capacity * department.machine_count * 5)) * 100)))
      |> Map.update!(:weekfour, &(Kernel.round((&1 / (department.capacity * department.machine_count * 5)) * 100)))
      |> Map.put_new(:department, department.department)
      |> Map.put_new(:department_id, department.id)

  end

  defp add_missing_date_rows(carryover_list, start, stop) do #adds date rows for carryover hours if non exist
    inbetween_dates =
    case {start, stop} do
      {nil, stop} -> []
      {start, nil} ->
        filtered_rows = Enum.filter(carryover_list, fn map -> if Date.compare(map.date, start) == :gt, do: true end)
        Enum.map(Enum.uniq_by(filtered_rows, &(&1.date)), fn %{date: date, hours: hours} ->
          %{sched_start: date, est_total_hrs: get_date_sum(filtered_rows, date), id: 0} end)
      {start, stop} ->
        filtered_rows = Enum.filter(carryover_list, fn map -> Date.compare(map.date, start) == :gt and Date.compare(map.date, stop) == :lt end)
          Enum.map(Enum.uniq_by(filtered_rows, &(&1.date)), fn %{date: date, hours: hours} ->
          %{sched_start: date, est_total_hrs: get_date_sum(filtered_rows, date), id: 0} end)
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

  #generating a list of only carryover days to render AFTER the initial op that has excess hours
  defp calculate_daily_carryover(carry_over_list, capacity, row) do

    {carry_over_list, carryover_hours, runner_ids} = #expected output from function
      Enum.reduce(carry_over_list, {carry_over_list, 0, []}, fn item, {carry_over_list, carryover_hours, runner_ids} ->
        new_hours = item.hours - capacity
        new_hours = if new_hours < 0, do: 0
        if row.est_total_hrs < capacity do
          {carry_over_list, item.hours, runner_ids}
        else #if more hours than the capacity
          {carry_over_list ++ [%{date: row.sched_start, id: item.id, hours: item.hours - capacity}], capacity, runner_ids ++ [row.id]}
        end
      end )
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
