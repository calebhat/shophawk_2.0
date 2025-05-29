#Root homepage with liveview navbar component
defmodule ShophawkWeb.RootLive do
  use ShophawkWeb, :live_view

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
  def render(assigns) do
    ~H"""
    <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user} />
    <div class="px-4 py-4 sm:px-6 lg:px-8">
    </div>
    """
  end
end
