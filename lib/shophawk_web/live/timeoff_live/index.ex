defmodule ShophawkWeb.TimeoffLive.Index do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJob #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  alias Shophawk.Shopinfo
  alias Shophawk.Shopinfo.Timeoff

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    today = DateTime.utc_now() |> DateTime.to_date()
    weekday = Date.day_of_week(today)
    # Calculate the date of this weeks Monday
    monday_date = Date.add(today, -(weekday - 1))
    {:ok,
      socket
      |> assign(:search_term, "")
      |> assign(:start_date, Calendar.strftime(monday_date, "%Y-%m-%d"))
      |> assign(:end_date, "")
      |> assign_timeoff_collection()
    }
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
  def handle_info({ShophawkWeb.TimeoffLive.FormComponent, {:saved, _timeoff}}, socket) do
    {:noreply, assign_timeoff_collection(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    timeoff = Shopinfo.get_timeoff!(id)
    {:ok, _} = Shopinfo.delete_timeoff(timeoff)

    {:noreply, assign_timeoff_collection(socket)}
  end

  @impl true
  def handle_event("search", %{"search_term" => search_term, "start_date" => start_date, "end_date" => end_date}, socket) do
    socket =
      socket
      |> assign(:search_term, search_term)
      |> assign(:start_date, start_date)
      |> assign(:end_date, end_date)
      |> assign_timeoff_collection()

    {:noreply, socket}
  end

  def handle_event("clear_search", _params, socket) do
    today = DateTime.utc_now() |> DateTime.to_date()
    weekday = Date.day_of_week(today)
    # Calculate the date of this weeks Monday
    monday_date = Date.add(today, -(weekday - 1))
    {:noreply,
    socket
    |> assign(:search_term, "")
    |> assign(:start_date, Calendar.strftime(monday_date, "%Y-%m-%d"))
    |> assign(:end_date, "")
    |> assign_timeoff_collection()
  }
  end

  defp assign_timeoff_collection(socket) do
    timeoff_collection = Shopinfo.search_timeoff(socket.assigns.search_term, socket.assigns.start_date, socket.assigns.end_date)
    stream(socket, :timeoff_collection, timeoff_collection, reset: true)
  end

end
