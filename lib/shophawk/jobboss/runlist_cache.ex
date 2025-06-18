defmodule Shophawk.RunlistCache do
  #Used for all loading of ETS Caches related to the runlist

  def get_runlist_ops(workcenter_list, department) do

    runlists =
      Cachex.stream!(:active_jobs, Cachex.Query.build(output: :value))
      |> Enum.to_list
      |> Enum.map(fn job_data -> job_data.job_ops end)
      |> List.flatten
      #|> IO.inspect

    runlists = if department.show_jobs_started == true do
      Enum.filter(runlists, fn op -> op.status == "Open" or op.status == "Started" end)
    else
      Enum.filter(runlists, fn op -> op.status == "Open"end)
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
    case Cachex.get(:active_jobs, job) do
      {:ok, nil} -> []
      {:ok, job_data} -> job_data
    end
  end

  def non_active_job(job) do
    case Cachex.get(:temporary_runlist_jobs_for_history, job) do
      {:ok, nil} -> []
      {:ok, job_data} -> job_data
    end
  end

  def operation(operation) do

    Cachex.stream!(:active_jobs, Cachex.Query.build(output: :value))
    |> Enum.to_list
    |> Enum.map(fn job_data -> job_data.job_ops end)
    |> List.flatten
    |> Enum.find(fn op -> op.job_operation == operation end)
  end

  def update_key_value(job, job_operation, key, value) do
    case Cachex.get(:active_jobs, job) do
      {:ok, nil} -> nil
      {:ok, job_data} ->
        updated_job_ops =
          Enum.map(job_data.job_ops, fn op -> if op.job_operation == job_operation, do: Map.replace(op, key, value), else: op end)

        Cachex.put(:active_jobs, job, Map.put(job_data, :job_ops, updated_job_ops))  # Store the data in ETS
      end
  end

end
