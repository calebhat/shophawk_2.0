defmodule ShophawkWeb.PartHistoryLive.Index do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJob #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  #alias Shophawk.Shop
  #alias Shophawk.Shop.Department
  #alias Shophawk.Shop.Assignment

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  def render(assigns) do
    ~H"""
      <div class="relative min-h-screen">
        <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user} />

        <div class="absolute left-4 right-4 m-2 rounded-lg bg-cyan-900 grid grid-cols-12" style="top: 5rem; bottom: 1rem;">
          <!-- Search Form -->
          <div class="my-4 ml-4 col-span-1 overflow-y-auto">
            <.form for={%{}} phx-submit="submit_form">
              <div class="">
                <.input name="job" value="" placeholder="Job"/>
              </div>
              <div class="my-2">
                <.input name="part" value="" placeholder="Part"/>
              </div>
              <div class="my-2">
                <.input name="customer" value="" placeholder="Customer"/>
              </div>
              <div class="my-2">
                <.input name="description" value="" placeholder="Description"/>
              </div>
              <div class="my-2">
                <.input name="customer" value="" placeholder="Customer"/>
              </div>
              <div class="my-2">
                <.input name="customer_po" value="" placeholder="Customer PO"/>
              </div>
              <div class="my-2">
                <div class="text-white"> Status</div>
                <.input class="" name="status" value="" type="select" options={["", "Active", "Complete", "Closed", "Hold", "Pending", "Template", "Canceled"]}/>
              </div>
              <div class="my-2">
                <div class="text-white"> Search Start</div>
                <.input name="start-date" value={~D[2000-01-01]} type="date" />
              </div>
              <div class="my-2">
                <div class="text-white"> Search End</div>
                <.input name="end-date" value={Date.utc_today()} type="date" />
              </div>

              <.button type="submit">Search</.button>
            </.form>
            <.link
                navigate={~p"/parthistory?#{[part: "hello", job: "131232"]}"}
                class="text-blue-900 font-bold underline"
              >
              link
            </.link>
          </div>

          <div class="m-4 bg-cyan-800 rounded-md overflow-y-auto h-auto w-auto col-span-11">
            <div phx-update="stream" id="jobs">


              <table id="parthistory" class="text-center w-auto mx-4">
                <thead class="text-white text-base">
                  <tr>
                    <th class="px-2">Job</th>
                    <th>Qty</th>
                    <th>Order Date</th>
                    <th>Status</th>
                    <th>Current Operation</th>
                    <th>Description</th>
                    <th>Profit %</th><!-- calc by parts for order, not total to account for extra pcs % being off -->
                    <th>Price/each</th>
                    <th>Cost/each</th>
                  </tr>
                </thead>
                <tbody phx-update="stream" id="jobs">
                  <tr :for={{id, row} <- @streams.jobs}
                      id={id}
                      phx-click={JS.push("show_job", value: %{job: row.job})}
                      class={["hover:bg-sky-100 bg-sky-200 hover:cursor-pointer border-b-2 border-stone-700"]}
                  >
                    <td><%= row.job %></td>
                    <td><%= row.job_info.order_quantity%></td>
                    <td><%= %></td>
                    <td><%= row.job_status %></td>
                    <td><%= %></td>
                    <td><%= row.job_info.description %></td>
                    <td><%= %></td>
                    <td><%= %></td>
                    <td><%= %></td>
                  </tr>
                </tbody>
              </table>



            </div>
          </div>


        </div>

        <.modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.push("close_modal")}>
          <.live_component
            module={ShophawkWeb.RunlistLive.ShowJob}
            id={@id || :show_job}
            job_ops={@job_ops}
            job_info={@job_info}
            title={@page_title}
            action={@live_action}
            current_user={@current_user}
          />
        </.modal>

        <.modal :if={@live_action in [:job_attachments]} id="job-attachments-modal" show on_cancel={JS.push("close_modal")}>
          <div class="w-[1600px]">
          <.live_component
            module={ShophawkWeb.RunlistLive.JobAttachments}
            id={@id || :job_attachments}
            attachments={@attachments}
            title={@page_title}
            action={@live_action}
          />
          </div>
        </.modal>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, set_default_assigns(socket)}
    else
     {:ok, set_default_assigns(socket)}
    end
  end

  def set_default_assigns(socket) do
    socket
    |> stream(:jobs, [])
  end

  def handle_event("submit_form", params, socket) do
    {:noreply, push_patch(socket, to: ~p"/parthistory?#{params}")}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :live_action, nil)}
  end

  def handle_params(params, _uri, socket) do
    if map_size(params) > 0 do
      job_maps = Shophawk.Jobboss_db.jobs_search(params)
      case job_maps do
        [] ->
          Process.send_after(self(), :clear_flash, 1000)
          socket = put_flash(socket, :error, "Job Not Found")
          {:noreply, socket |> stream(:jobs, [], reset: true)}

        job_maps ->
          self = self()
          batch_size = 5
          # Group job numbers into batches
          job_numbers = Enum.map(job_maps, & &1.job)
          batches = Enum.chunk_every(job_numbers, batch_size)

          # Start async task to process batches
          Task.async(fn ->
            batches
            |> Enum.map(fn batch ->
              # Process each batch and maintain job order within batch
              batch_results = showjob(batch)

              # Immediately send job data for this batch
              batch_results
              |> Enum.each(fn
                {:error} -> :skip
                job_data -> send(self, {:loaded_job, job_data})
              end)
            end)
          end)

          {:noreply, socket |> stream(:jobs, [], reset: true)}
      end
    else
      {:noreply, socket |> stream(:jobs, [], reset: true)}
    end
  end

  def handle_info({:loaded_job, job_data}, socket) do
    case job_data do
      {:error} ->
        Process.send_after(self(), :clear_flash, 1000)
        {:noreply, socket |> put_flash(:error, "Job Not Found")}
      _ -> {:noreply, stream_insert(socket, :jobs, job_data, at: -1)}
    end
  end

  def handle_info({_ref, _result}, state) do
    {:noreply, state}
  end

  # Required to prevent Task.async/1 from crashing on exit
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

end
