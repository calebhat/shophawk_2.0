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
    runlists_with_started =
      if department.show_jobs_started do
        runlists_with_started = runlists
      else
        runlists_with_started = Repo.all(query |> where([r], r.status == "O" or r.status == "S"))
      end

    if Enum.empty?(runlists) do
      []
    else
      [first_row | tail] = runlists
      [second_row | _tail] = tail
      last_row = List.last(runlists)
      first_row_id = first_row.id
      last_row_id = last_row.id
      blackout_dates = Csvimport.load_blackout_dates

      #generate list of maps with just days with extra hours %{date: date, hours: hours, id: id}
      carryover_list =
        runlists_with_started
        |> Enum.reduce([], fn row, acc ->
          if row.est_total_hrs > department.capacity do
            [%{date: row.sched_start, hours: row.est_total_hrs, id: row.id} | acc]
          else
            acc
          end
        end)
        |> IO.inspect
        |> Enum.reduce([], fn %{date: date, hours: remaining_hours, id: id}, acc ->
          generate_daily_carryover_days(id, date, remaining_hours, department.capacity, acc, blackout_dates, 0)
        end)
        |> IO.inspect
#WORKING! see note directly below
        #change rest of function to: if the date matches a date in this list, load the id, and set the est_total_hrs to the value in this list


      #Make list of date & hours map for matching to date rows
      {hours_list, _, _, _, carry_over_list} =
        Enum.reduce_while(runlists, {[], nil, 0, 0, []}, fn row, {acc, prev_sched_start, daily_hours, _carryover_hours, carry_over_list} ->
          sched_start = row.sched_start

          #carryover_hours will never be more than daily capacity, so erare that logic.
          #always just add to daily hours
          #runner_ids is list of ops to add to each day after date row, see note at that section of code
          {carry_over_list, carryover_hours, runner_ids} = calculate_daily_carryover(carry_over_list, department.capacity, row) #|> IO.inspect
          #IO.inspect(carryover_hours)
          #add function to accumlate carry_over hours into float from list of maps

          if prev_sched_start == sched_start do #for 2nd row and beyond
            {new_daily_hours, new_carryover_hours, carry_over_map} =
              if row.est_total_hrs < department.capacity do
                {daily_hours + row.est_total_hrs, carryover_hours, nil}
              else #if the hours > capacity
              #IO.inspect("same day")
                {daily_hours + department.capacity, carryover_hours + (row.est_total_hrs - department.capacity), %{date: sched_start, id: row.id, hours: (row.est_total_hrs - department.capacity)}}
              end

              if row.id == last_row_id do #checks for last row
                carry_over_list = if carry_over_map != nil, do: carry_over_list ++ [carry_over_map], else: carry_over_list
                new_acc = acc ++ [%{daily_hours: Float.round(new_daily_hours, 2), sched_start: sched_start}] #last day
                {:halt, {new_acc, sched_start, Float.round(new_daily_hours, 2), new_carryover_hours, carry_over_list}}
              else
                {:cont, {acc, sched_start, new_daily_hours, new_carryover_hours, carry_over_list}}
              end
          else #if a new day
            #Calculate next days values with carryover_hours
            {new_daily_hours, new_carryover_hours, carry_over_map} =
              if row.est_total_hrs < department.capacity do
                if carryover_hours < department.capacity do
                  {row.est_total_hrs + carryover_hours, 0, nil}
                else
                  #IO.inspect("yo dog")
                  {row.est_total_hrs + department.capacity, carryover_hours - department.capacity, nil}
                end
              else #hours is more than capacity
                if carryover_hours < department.capacity do
                  #IO.inspect("yo")
                  {department.capacity + carryover_hours, row.est_total_hrs - department.capacity, %{date: sched_start, id: row.id, hours: (row.est_total_hrs - department.capacity)}} #good
                else #carryover is more than capacity
                  #IO.inspect("new day")
                  {department.capacity + department.capacity, (row.est_total_hrs - department.capacity) + (carryover_hours - department.capacity), %{date: sched_start, id: row.id, hours: (row.est_total_hrs - department.capacity)}}
                end
              end

            case row.id do
              ^first_row_id ->
                carry_over_list = if carry_over_map != nil, do: carry_over_list ++ [carry_over_map], else: carry_over_list
                {:cont, {acc, sched_start, Float.round(new_daily_hours, 2), new_carryover_hours, carry_over_list}}

              ^last_row_id ->
                carry_over_list = if carry_over_map != nil, do: carry_over_list ++ [carry_over_map], else: carry_over_list
                new_acc = acc ++ [
                  %{daily_hours: Float.round(daily_hours, 2), sched_start: prev_sched_start}, #2nd to last day
                  %{daily_hours: Float.round(new_daily_hours, 2), sched_start: sched_start}] #last day
                {:halt, {new_acc, sched_start, Float.round(new_daily_hours, 2), new_carryover_hours, carry_over_list}}

              _ ->
                carry_over_list = if carry_over_map != nil, do: carry_over_list ++ [carry_over_map], else: carry_over_list
                new_acc = acc ++ [%{daily_hours: Float.round(daily_hours, 2), sched_start: prev_sched_start}]
                {:cont, {new_acc, sched_start, new_daily_hours, new_carryover_hours, carry_over_list}}
            end
          end
          #last row check?  whether it's a new day or not?
        end)

        #IO.inspect(carry_over_list)

      {rows, _} =
        Enum.reduce_while(runlists, {[], nil}, fn row, {acc, prev_sched_start} ->
          sched_start = row.sched_start
          row = #combines workcenter and service if a service exists
            if row.operation_service != "NULL" do
              combined = "#{row.wc_vendor} -#{row.operation_service}"
              Map.put(row, :wc_vendor, combined)
            else
              row
            end
          if prev_sched_start == sched_start do
            {:cont, {acc ++ [row], sched_start}}
          else #if a new day
            daily_hours = Map.get(Enum.find(hours_list, fn map -> map[:sched_start] == sched_start end), :daily_hours, 0.0)
            date_row = [%Runlist{sched_start: sched_start, est_total_hrs: daily_hours, id: 0}]
            {:cont, {acc ++ date_row ++ [row], sched_start}} #add runner rows after [row] here
          end
        end)
      rows
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
    get_next_day(row.job_sched_start)# |> IO.inspect

    {carry_over_list, carryover_hours, runner_ids} = #expected output from function
      Enum.reduce(carry_over_list, {carry_over_list, 0, []}, fn item, {carry_over_list, carryover_hours, runner_ids} ->
        #  %{date: sched_start, id: row.id, hours: }
#need to subtract hours from each day, only adding right now?
      #if row.id do
        new_hours = item.hours - capacity
        new_hours = if new_hours < 0, do: 0
        #IO.inspect(new_hours)
        if row.est_total_hrs < capacity do #not going to re-add to list
        #IO.inspect("here")

          {carry_over_list, item.hours, runner_ids}
        else #if more hours than the capacity
        #IO.inspect("there")
          {carry_over_list ++ [%{date: row.sched_start, id: item.id, hours: item.hours - capacity}], capacity, runner_ids ++ [row.id]}
        end
     # end

      end )
      #{carry_over_list, carryover_hours, runner_ids} #need these at end
  end

  defp get_next_day(date) do
    Csvimport.load_blackout_dates
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
    Repo.all(Department)
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
