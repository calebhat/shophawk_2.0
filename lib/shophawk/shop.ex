defmodule Shophawk.Shop do
  @moduledoc """
  The Shop context.
  """

  import Ecto.Query, warn: false
  alias Shophawk.Repo

 alias Shophawk.Shop.Runlist
 alias Shophawk.Shop.Department
 alias Shophawk.Shop.Workcenter

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

  @doc """
  Returns the list of runlists.

  ## Examples

      iex> list_runlists()
      [%Runlist{}, ...]

  """
  def list_runlists(department) do
    #Repo.all(Runlist)
    runlists =
      Repo.all(
        from r in Runlist,
        where: r.wc_vendor in ^department,
        where: r.status == "O",
        order_by: [asc: r.sched_start, asc: r.job],
        select: %Runlist{id: r.id, job: r.job, description: r.description, wc_vendor: r.wc_vendor, operation_service: r.operation_service, sched_start: r.sched_start, job_sched_end: r.job_sched_end, customer: r.customer, part_number: r.part_number, order_quantity: r.order_quantity, material: r.material, dots: r.dots, currentop: r.currentop, material_waiting: r.material_waiting, est_total_hrs: r.est_total_hrs}
      )
    #|> IO.inspect()
    if Enum.empty?(runlists) do
      []
    else
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
          else
            date_row = [%Runlist{sched_start: sched_start, id: 0}]
            {:cont, {acc ++ date_row ++ [row], sched_start}}
          end

        end)
      rows
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

  @doc """
  Creates a runlist.

  ## Examples

      iex> create_runlist(%{field: value})
      {:ok, %Runlist{}}

      iex> create_runlist(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_runlist(attrs \\ %{}) do

    #IO.inspect(attrs)
    #Repo.insert(attrs)
    changeset = Runlist.changeset(%Runlist{}, attrs)
    |> IO.inspect
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

  def toggle_mat_waiting(id) do
    op = Repo.get!(Runlist, id)
    new_matertial_waiting = !op.material_waiting
    Repo.update_all(
      from(r in Runlist, where: r.job == ^op.job),
      set: [material_waiting: new_matertial_waiting]
    )
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



  @doc """
  Returns the list of departments.

  ## Examples

      iex> list_departments()
      [%Department{}, ...]

  """
  def list_departments do
   Repo.all(Department)
  end

  def list_workcenters do
    Repo.all(Workcenter)
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
    Repo.get!(Department, id) |> Repo.preload([workcenters: from(c in Workcenter, order_by: c.workcenter)])
    #Repo.get!(Department, id) |> Repo.preload(:workcenters)
  end

  defp subquery(query), do: from wc in query, order_by: [wc.name]

  def get_department_by_name(department) do
    Repo.get_by!(Department, department: department)  |> Repo.preload(:workcenters)
  end

  def get_workcenter!(id), do: Repo.get!(Workcenter, id)

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

  def create_workcenter(attrs \\ %{}) do
    changeset = Workcenter.changeset(%Workcenter{}, attrs)
    Repo.insert(changeset)
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

  defp extract_workcenters(attrs) do
    workcenter_names = attrs["workcenters"] |> Enum.map(&Map.get(&1, "workcenter"))
    Workcenter
    |> where([w], w.workcenter in ^workcenter_names)
    |> Repo.all()
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
