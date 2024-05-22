defmodule ShophawkWeb.TimeoffLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shopinfo
  alias Shophawk.Shopinfo.Timeoff

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :timeoff_collection, Shopinfo.list_timeoff())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Timeoff")
    |> assign(:timeoff, Shopinfo.get_timeoff!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Timeoff")
    |> assign(:timeoff, %Timeoff{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Timeoff")
    |> assign(:timeoff, nil)
  end

  @impl true
  def handle_info({ShophawkWeb.TimeoffLive.FormComponent, {:saved, timeoff}}, socket) do
    {:noreply, stream_insert(socket, :timeoff_collection, timeoff)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    timeoff = Shopinfo.get_timeoff!(id)
    {:ok, _} = Shopinfo.delete_timeoff(timeoff)

    {:noreply, stream_delete(socket, :timeoff_collection, timeoff)}
  end
end
