defmodule ShophawkWeb.RunlistLive.ShowJob do
  use ShophawkWeb, :live_component

  alias Shophawk.Shop

  #JS.navigate(~p"/runlists/#{runlist}")  Show one runlist item.

  def render(assigns) do
    ~H"""
      <div>
      ello <%= assigns.job %>
      </div>


    """
  end


  def update(assigns, socket) do
    #IO.inspect(assigns)

    {:ok,
    socket
    |> assign(job: assigns.id)}
  end

end
