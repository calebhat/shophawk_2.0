defmodule ShophawkWeb.SlideshowLive.Show do
  use ShophawkWeb, :live_view

  alias Shophawk.Shopinfo

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:slideshow, Shopinfo.get_slideshow!(id))}
  end

  defp page_title(:show), do: "Show Slideshow"
  defp page_title(:edit), do: "Edit Slideshow"
end
