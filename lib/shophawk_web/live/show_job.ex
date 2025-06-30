# Functions used by show job modals
defmodule ShophawkWeb.ShowJob do

  defmacro __using__(_opts) do
    quote do

      @impl true
      def handle_event("show_job", %{"job" => job_number}, socket) do

        socket =
          case showjob([job_number]) do
            {:error} ->
              Process.send_after(self(), :clear_flash, 1000)
              socket |> put_flash(:error, "Job Not Found")
            [job] ->
              socket
              |> assign(:live_action, :show_job)
              |> assign(page_title: "Job #{job.job}")
              |> assign(id: job.job)
              |> assign(:job_ops, job.job_ops) #routing operations for job
              |> assign(:job_info, job.job_info)
          end

        {:noreply,
        socket
        |> assign(:search_value, "")
        |> push_event("reset_form", %{})
        }
      end

      def handle_event("attachments", _, socket) do
        job = socket.assigns.id
        attachments = Shophawk.Jobboss_db.export_attachments(job)
        socket =
          socket
          |> assign(id: job)
          |> assign(attachments: attachments)
          |> assign(page_title: "Job #{job} attachments")
          |> assign(:live_action, :job_attachments)

        {:noreply, socket}
      end

      def handle_event("download", %{"file-path" => file_path}, socket) do
        {:noreply, push_event(socket, "trigger_file_download", %{"url" => "/download/#{URI.encode(file_path)}"})}
      end

      def handle_event("download", _params, socket) do
        {:noreply, socket |> assign(:not_found, "File not found")}
      end

      def handle_event("close_job_attachments", _params, socket) do
        {:noreply,
        socket
        |> assign(live_action: :show_job)}
      end

#      @impl true
#      def handle_info(:clear_flash, socket) do
#        {:noreply, clear_flash(socket)}
#      end

      def showjob(jobs) when is_list(jobs) do
        case Enum.count(jobs) do
          0 -> {:error}
          1 -> #single job to load
            job_number = List.first(jobs, "")
            case Shophawk.Jobboss_db.job_exists?(job_number) do
              true -> [showjob(job_number)]
              false -> {:error}
            end
          _ -> #multiple jobs to load
            jobs_with_any_cached_data =
              Enum.map(jobs, fn job ->
                case Shophawk.RunlistCache.job(job) do
                  [] ->
                    case Shophawk.RunlistCache.non_active_job(job) do #check non-active job cache
                      [] -> job
                      job_data -> job_data
                    end
                  job_data -> job_data
                end
              end)

            list_of_jobs_needed_to_load = Enum.reduce(jobs_with_any_cached_data, [], fn job, acc ->
              if is_map(job) == false, do: acc ++ [job], else: acc
            end)

            case list_of_jobs_needed_to_load do
              [] -> jobs_with_any_cached_data #all jobs already loaded
              _ ->
                loaded_jobs =
                  case Shophawk.Jobboss_db.load_job_history(list_of_jobs_needed_to_load) do #batch load jobs if passed a list of jobs
                    [] ->
                      {:error}
                    job_data_list ->
                      Enum.each(job_data_list, fn {job, job_data} ->
                        Cachex.put(:temporary_runlist_jobs_for_history, job, job_data)
                      end)
                      job_data_list
                  end

                Enum.map(jobs_with_any_cached_data, fn job_data ->
                  case is_map(job_data) do
                    false ->
                      {job, found_data} = Enum.find(loaded_jobs, fn {job, data} -> job == job_data end)
                      found_data
                    true -> job_data
                  end
                end)
            end
        end
      end

      def showjob(job) do
        case Shophawk.RunlistCache.job(job) do
          [] ->
            case Shophawk.RunlistCache.non_active_job(job) do #check non-active job cache
              [] ->
                case Shophawk.Jobboss_db.load_job_history([job]) do #load single job if no list is passed to function
                  [] ->
                    {:error}
                  [{_job, job_data}] ->
                    Cachex.put(:temporary_runlist_jobs_for_history, job, job_data)
                    job_data
                end
              non_active_job ->
                non_active_job
            end
          active_job -> active_job
        end
      end

    end
  end

end
