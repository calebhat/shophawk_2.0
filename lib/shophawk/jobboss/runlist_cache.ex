defmodule Shophawk.RunlistCache do
  #Used for all loading of ETS Caches related to the runlist

  def load_runlist(workcenter_list, department) do
    IO.inspect(department.show_jobs_started)
    [{:active_jobs, runlists}] = :ets.lookup(:runlist, :active_jobs)
    runlists = List.flatten(runlists)
    runlists = if department.show_jobs_started == true do
      Enum.filter(runlists, fn op -> op.status == "O" or op.status == "S" end)
    else
      Enum.filter(runlists, fn op -> op.status == "O"end)
    end

    runlists =
      runlists
      |> Enum.filter(fn op -> op.wc_vendor in workcenter_list end)
      |> Enum.reject(fn op -> op.sched_start == nil end)
      |> Enum.uniq()
      |> Enum.map(fn row ->
        case row.operation_service do #combines wc_vendor and operation_service if needed
          nil -> row
          "" -> row
          _ -> Map.put(row, :wc_vendor, "#{row.wc_vendor} -#{row.operation_service}")
        end
      end)
      |> Enum.sort_by(&(&1.job))
      |> Enum.sort_by(&(&1.sched_start), Date)
    runlists
  end

  def status_check(list) do
    Enum.each(list, fn x -> if Map.has_key?(x, :status) == false, do: IO.inspect(x) end )
    list
  end

  def job(job) do
    [{:active_jobs, runlists}] = :ets.lookup(:runlist, :active_jobs)
    runlists
    |> List.flatten
    |> Enum.filter(fn op -> op.job == job end)
    |> Enum.uniq()
    |> Enum.sort_by(&(&1.sequence))
  end

  def operation(operation) do
    [{:active_jobs, runlists}] = :ets.lookup(:runlist, :active_jobs)
    runlists
    |> List.flatten
    |> Enum.find(fn op -> op.job_operation == operation end)
  end

end
