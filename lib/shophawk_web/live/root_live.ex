#Root homepage with liveview navbar component
defmodule ShophawkWeb.RootLive do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJobLive.ShowJobMacroFunctions #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    # Assign any initial state for the navbar or page
    socket =
      socket
      |> assign(:page_title, "ShopHawk")

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user} />
      <div class="px-4 py-4 sm:px-6 lg:px-8">
      </div>

      <.showjob_modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.patch(~p"/")}>
        <.live_component
            module={ShophawkWeb.ShowJobLive.ShowJob}
            id={@id || :show_job}
            job_ops={@job_ops}
            job_info={@job_info}
            title={@page_title}
            action={@live_action}
            current_user={@current_user}
            expanded={@expanded || []}
          />
      </.showjob_modal>
    </div>
    """
  end
end
