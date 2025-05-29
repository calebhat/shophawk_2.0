# Functions used by show job modals
defmodule ShophawkWeb.ShowJob do

  defmacro __using__(_opts) do
    quote do

      @impl true
      def handle_event("show_job", %{"job" => job}, socket) do
        {:noreply,
        socket
        |> assign(:search_value, "")
        |> push_event("reset_form", %{})
        |> showjob(job)}
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

      def showjob(socket, job) do
        case Shophawk.Shop.list_job(job) do
          {:error, :error} ->
            Process.send_after(self(), :clear_flash, 1000)
            socket |> put_flash(:error, "Job Not Found")
          {job_ops, job_info} ->
            deliveries =
              Shophawk.Jobboss_db.load_all_deliveries([job])
              |> Enum.sort_by(&(&1.promised_date), {:asc, Date})
            updated_job_info =
              Map.put(job_info, :deliveries, deliveries)
              |> Map.put(:dots, List.first(job_ops).dots)
            socket
            |> assign(id: job)
            |> assign(page_title: "Job #{job}")
            |> assign(:live_action, :show_job)
            |> assign(:job_ops, job_ops) #Load job data here and send as a list of ops in order
            |> assign(:job_info, updated_job_info)
        end
      end

    end
  end
  # Default implementations (can be overridden) Normal functions called from the handle_event/handle_info functions

end
