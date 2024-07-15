defmodule Shophawk.RunlistCache do
  #Used for all loading of ETS Caches related to the runlist

  def get_runlist_ops(workcenter_list, department) do
    #IO.inspect(department.show_jobs_started)
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

  def update_key_value(job_operation, key, value) do
    [{:active_jobs, runlists}] = :ets.lookup(:runlist, :active_jobs)
    updated_runlist =
      runlists
      |> List.flatten
      |> Enum.map(fn op ->
        if op.job_operation == job_operation, do: Map.replace(op, key, value), else: op
      end)
    :ets.insert(:runlist, {:active_jobs, updated_runlist})  # Store the data in ETS
  end

end
