defmodule ShophawkWeb.InformationLive.Index do
  use ShophawkWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
    Hello
    </div>
    """
  end


  @impl true
  def mount(_params, _session, socket) do
      #IO.inspect(socket)
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    #IO.inspect(params)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Information")
  end

end
