# Functions used by show job modals
defmodule ShophawkWeb.ShowJob do

  defmacro __using__(_opts) do
    quote do

      @impl true
      def handle_event("show_job", %{"job" => job_number}, socket) do

        socket =
          case showjob(job_number) do
            {:error} ->
              Process.send_after(self(), :clear_flash, 1000)
              socket |> put_flash(:error, "Job Not Found")
            job ->
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

      def showjob(job) do
        case Shophawk.RunlistCache.job(job) do
          [] ->
            #IO.inspect(Shophawk.RunlistCache.non_active_job(job))
            case Shophawk.RunlistCache.non_active_job(job) do #check non-active job cache
              [] ->
                #Function to load job history directly from JB (not active job in caches)
                case Shophawk.Jobboss_db.load_job_history([job]) |> List.first() do
                  nil -> {:error}
                  {_job, job_data} ->
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
