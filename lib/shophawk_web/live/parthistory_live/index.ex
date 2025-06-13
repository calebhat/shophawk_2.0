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
          <div class="my-4 mx-2 col-span-1">
            <.form for={%{}} phx-submit="submit_form">
              <div class="my-2">
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

          <div class="">

          </div>


        </div>
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
  end

  def handle_event("submit_form", params, socket) do
    {:noreply, push_patch(socket, to: ~p"/parthistory?#{params}")}
  end

  def handle_params(params, _uri, socket) do
    IO.inspect(params)
    socket =
      case params do
        %{} when map_size(params) == 0 ->
          socket #empty map
        _ -> #
          job_maps = Shophawk.Jobboss_db.jobs_search(params)

          #NEED TO SPIN THIS OFF INTO OWN PROCESS (TASK.ASYNC) AND CACHE EACH JOB WITH AN EXPIRATION FOR QUICK LOOKUP LATER
          Enum.each(job_maps, fn job -> showjob(job.job) end)

          socket
      end



    {:noreply, socket}
  end

end
