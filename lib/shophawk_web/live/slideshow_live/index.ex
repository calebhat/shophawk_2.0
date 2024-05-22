defmodule ShophawkWeb.SlideshowLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shopinfo
  alias Shophawk.Shopinfo.Slideshow

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :slideshow_collection, Shopinfo.list_slideshow())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :run_slideshow, %{"id" => id}) do
    socket
    |> assign(:page_title, "Running Slideshow")
    |> assign(:slideshow, Shopinfo.get_slideshow!(id))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Slideshow")
    |> assign(:slideshow, Shopinfo.get_slideshow!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Slideshow")
    |> assign(:slideshow, %Slideshow{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Slideshow")
    |> assign(:slideshow, nil)
  end

  @impl true
  def handle_info({ShophawkWeb.SlideshowLive.FormComponent, {:saved, slideshow}}, socket) do
    {:noreply, stream_insert(socket, :slideshow_collection, slideshow)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    slideshow = Shopinfo.get_slideshow!(id)
    {:ok, _} = Shopinfo.delete_slideshow(slideshow)

    {:noreply, stream_delete(socket, :slideshow_collection, slideshow)}
  end

  def handle_info({:next_slide, slideshow, current_slide, index}, socket) do
    [this_weeks_birthdays: birthdays] = :ets.lookup(:birthdays_cache, :this_weeks_birthdays)
    hot_jobs = Shophawk.Shop.get_hot_jobs()
    slideshow = if birthdays != [], do: Map.put(slideshow, :birthdays, birthdays), else: slideshow

    slides = [:hours]
    #slides = []
    {slideshow, slides} = if hot_jobs != [], do: {Map.put(slideshow, :hot_jobs, hot_jobs), slides ++ [:hot_jobs]}, else: {slideshow, slides}
    slides = if birthdays != [], do: slides ++ [:birthdays], else: slides
    slides = if String.trim(slideshow.announcement1) != "", do: slides ++ [:announcement1], else: slides
    slides = if String.trim(slideshow.announcement2) != "", do: slides ++ [:announcement2], else: slides
    slides = if String.trim(slideshow.announcement3) != "", do: slides ++ [:announcement3], else: slides
    slides = if String.trim(slideshow.quote) != "", do: slides ++ [:quote], else: slides
    slides = if String.trim(slideshow.photo) != "", do: slides ++ [:photo], else: slides

    {next_slide, _value} =
    Enum.reduce_while(slides, {nil, false}, fn slide, {_last_slide, found} = acc ->
      case {slide == current_slide, found} do
        {true, false} ->
          {:cont, {slide, true}}  # Found the current slide
        {_, true} ->
          {:halt, {slide, true}} # Found the next slide after the current
        _ ->
          {:cont, {slide, false}} # Keep iterating
      end
    end)
    next_slide = if current_slide == next_slide, do: List.first(slides), else: next_slide
    send_update(self(), ShophawkWeb.SlideshowLive.SlideshowComponent, id: 1, slideshow: slideshow, slide: next_slide, slide_index: index)
    {:noreply, socket}
  end

  def handle_info({:next_slide_animation, slideshow, current_slide, index}, socket) do

    #next_slide = if current_slide == next_slide, do: List.first(slides), else: next_slide
    send_update(self(), ShophawkWeb.SlideshowLive.SlideshowComponent, id: 1, slideshow: slideshow, slide: current_slide, slide_index: index)
    {:noreply, socket}
  end
end
