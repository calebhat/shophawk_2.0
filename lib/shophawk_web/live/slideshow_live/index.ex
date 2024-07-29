defmodule ShophawkWeb.SlideshowLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Shopinfo
  alias Shophawk.Shopinfo.Slideshow

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :next_slide, nil)
    {slideshow, slides, next_slide, index} = prepare_slides(Shopinfo.get_slideshow!(1), nil, 0, [])
    slides = Enum.map(slides, fn x -> Atom.to_string(x) end) |> Jason.encode!()
    socket =
      socket
      |> assign(slideshow: slideshow)
      |> assign(slide: :week1_timeoff)
      |> assign(slide_index: 1)
      |> assign(next_slide: next_slide)
      |> assign(index: index)
      |> assign(slides: slides)
      |> assign(:page_title, "Listing Slideshow")
    {:ok, stream(socket, :slideshow_collection, Shopinfo.list_slideshow())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :run_slideshow, _params) do
    socket |> assign(:page_title, "Running Slideshow")
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
    {slideshow, slides, next_slide, index} = prepare_slides(Shopinfo.get_slideshow!(1), nil, 0, [])
    slides = Enum.map(slides, fn x -> Atom.to_string(x) end) |> Jason.encode!()
    socket
    |> assign(slideshow: slideshow)
    |> assign(slide: :week1_timeoff)
    |> assign(slide_index: 1)
    |> assign(next_slide: next_slide)
    |> assign(index: index)
    |> assign(slides: slides)
    |> assign(:page_title, "Listing Slideshow")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    slideshow = Shopinfo.get_slideshow!(id)
    {:ok, _} = Shopinfo.delete_slideshow(slideshow)
    {:noreply, stream_delete(socket, :slideshow_collection, slideshow)}
  end

  def handle_event("next_slide", %{"next-slide" => slide_to_load, "slides" => slides}, socket) do
    slide_to_load = String.to_atom(slide_to_load)
    slides = Jason.decode!(slides) |> Enum.map( fn x -> String.to_atom(x) end)
    {slideshow, slides, _next_slide, _index} = prepare_slides(Shopinfo.get_slideshow!(1), nil, 0, [])
    {_slideshow, _slides, next_slide, index} = prepare_slides(slideshow, slide_to_load, 0, slides)


    slides = Enum.map(slides, fn x -> Atom.to_string(x) end) |> Jason.encode!()

    socket = if slide_to_load == :hot_jobs, do: stream(socket, :hot_jobs, slideshow.hot_jobs, reset: true), else: socket
    {:noreply, socket |> assign(slide: slide_to_load) |> assign(next_slide: next_slide) |> assign(index: (index + 2)) |> assign(slides: slides)}
  end

  @impl true
  def handle_info({ShophawkWeb.SlideshowLive.FormComponent, {:saved, slideshow}}, socket) do
    {:noreply, stream_insert(socket, :slideshow_collection, slideshow)}
  end

  def handle_info({:next_slide, slideshow, current_slide, index, slides}, socket) do
    {slideshow, slides, next_slide, index} = prepare_slides(slideshow, current_slide, index, slides)
    send_update(self(), ShophawkWeb.SlideshowLive.SlideshowComponent, id: 1, slideshow: slideshow, slide: next_slide, slide_index: index, slides: slides)
    {:noreply, socket}
  end

  def handle_info({:next_slide_animation, slideshow, current_slide, index, slides}, socket) do
    index = index + 1 #used to trigger css animations
    index = if index == 20, do: 0, else: index #keeps number low after running for weeks/months nonstop.
    send_update(self(), ShophawkWeb.SlideshowLive.SlideshowComponent, id: 1, slideshow: slideshow, slide: current_slide, slide_index: index, slides: slides)
    {:noreply, socket}
  end

  def prepare_slides(slideshow, current_slide, index, slides) do
    {next_slide, _value} =
      Enum.reduce_while(slides, {nil, false}, fn slide, {_last_slide, found} = _acc ->
        case {slide == current_slide, found} do
          {true, false} ->
            {:cont, {slide, true}}  # Found the current slide
          {_, true} ->
            {:halt, {slide, true}} # Found the next slide after the current
          _ ->
            {:cont, {slide, false}} # Keep iterating, or if last on list it outputs the last item.
        end
      end)
    {slideshow, slides, next_slide} =
      if current_slide == next_slide do
        slideshow = Shopinfo.get_slideshow!(1)
        slides = []

        [weekly_dates: weekly_dates] = :ets.lookup(:slideshow, :weekly_dates)
        slideshow = Map.put(slideshow, :weekly_dates, weekly_dates)
        {week1_timeoff, week2_timeoff} = load_timeoff(weekly_dates)
        {slideshow, slides} = if Enum.all?(week2_timeoff, fn {_k, v} -> v == [] end) == false, do: {Map.put(slideshow, :week2_timeoff, week2_timeoff), slides ++ [:week2_timeoff]}, else: {slideshow, slides}

        {slideshow, slides} = {parse_hours(slideshow), slides ++ [:hours]}

        hot_jobs = Shophawk.Shop.get_hot_jobs()
        {slideshow, slides} = if hot_jobs != [], do: {Map.put(slideshow, :hot_jobs, hot_jobs), slides ++ [:hot_jobs]}, else: {slideshow, slides}
        {slideshow, slides} = if String.trim(slideshow.announcement1) != "", do: {Map.put(slideshow, :announcement1, slideshow.announcement1 |> String.replace("\n", "<br>")), slides ++ [:announcement1]}, else: {slideshow, slides}
        {slideshow, slides} = if String.trim(slideshow.announcement2) != "", do: {Map.put(slideshow, :announcement2, slideshow.announcement2 |> String.replace("\n", "<br>")), slides ++ [:announcement2]}, else: {slideshow, slides}
        {slideshow, slides} = if String.trim(slideshow.announcement3) != "", do: {Map.put(slideshow, :announcement3, slideshow.announcement3 |> String.replace("\n", "<br>")), slides ++ [:announcement3]}, else: {slideshow, slides}
        personal_time = personal_time?()
        {slideshow, slides} = if personal_time != "", do: {Map.put(slideshow, :personal_time, personal_time), slides ++ [:personal_time]}, else: {slideshow, slides}


        [this_weeks_birthdays: birthdays] = :ets.lookup(:slideshow, :this_weeks_birthdays)
        {slideshow, slides} = if birthdays != [], do: {Map.put(slideshow, :birthdays, birthdays), slides ++ [:birthdays]}, else: {slideshow, slides}
        slides = if String.trim(slideshow.quote) != "", do: slides ++ [:quote], else: slides
        slides = if String.trim(slideshow.photo) != "", do: slides ++ [:photo], else: slides
        {slideshow, slides} = if Enum.all?(week1_timeoff, fn {_k, v} -> v == [] end) == false, do: {Map.put(slideshow, :week1_timeoff, week1_timeoff), slides ++ [:week1_timeoff]}, else: {Map.put(slideshow, :week1_timeoff, [m: [], t: [], w: [], thur: [], f: []]), slides}

        {slideshow, slides, List.first(slides)}
      else
        {slideshow, slides, next_slide}
      end
    {slideshow, slides, next_slide, (index + 1)}
  end

  defp personal_time?() do #determines if personal time usage slide should be displayed
    today = Date.utc_today()
    current_year = today.year
    {:ok, january} = Date.from_iso8601("#{current_year}-01-01")
    {:ok, may} = Date.from_iso8601("#{current_year}-05-01")
    {:ok, september} = Date.from_iso8601("#{current_year}-09-01")
    cond do
      Date.after?(Date.add(today, -20), january) and Date.before?(today, january) -> "01/01/#{current_year}"
      Date.after?(Date.add(today, -20), may) and Date.before?(today, may) -> "05/01/#{current_year}"
      Date.after?(Date.add(today, -20), september) and Date.before?(today, september) -> "09/01/#{current_year}"
      true -> ""
    end
  end

  defp parse_hours(slideshow) do
    map_keys = [:mondayo1, :mondayc1, :tuesdayo1, :tuesdayc1, :wednesdayo1, :wednesdayc1, :thursdayo1, :thursdayc1, :fridayo1, :fridayc1, :saturdayo1, :saturdayc1, :mondayo2, :mondayc2, :tuesdayo2, :tuesdayc2, :wednesdayo2, :wednesdayc2, :thursdayo2, :thursdayc2, :fridayo2, :fridayc2, :saturdayo2, :saturdayc2, :showsaturday1, :showsaturday2]
        slideshow =
          String.split(slideshow.workhours, ",")
          |> Enum.map(fn x ->
            if String.contains?(x, ":") do
              [hours, minutes] = String.split(x, ":")
              hours = String.to_integer(hours)
              hours = if hours > 12, do: hours - 12, else: hours
              "#{hours}:#{minutes}"
            else
              x
            end
          end)
          |> Enum.map(fn x ->
            case x do
              "true" -> true
              "false" -> false
              _ -> x
            end
          end)
          |> Enum.zip(map_keys)
          |> Enum.reduce(slideshow, fn {value, key}, acc ->
            Map.put(acc, key, value)
          end)

        [weekly_dates: weekly_dates] = :ets.lookup(:slideshow, :weekly_dates)
        monday_formatted = Date.to_string(weekly_dates.monday) |> String.split("-") |> Enum.take(-2) |> Enum.join("/")
        friday_formatted = Date.to_string(weekly_dates.friday) |> String.split("-") |> Enum.take(-2) |> Enum.join("/")
        next_monday_formatted = Date.to_string(weekly_dates.next_monday) |> String.split("-") |> Enum.take(-2) |> Enum.join("/")
        next_friday_formatted = Date.to_string(weekly_dates.next_friday) |> String.split("-") |> Enum.take(-2) |> Enum.join("/")
        slideshow = Map.put(slideshow, :this_week, "#{monday_formatted} - #{friday_formatted}")
        Map.put(slideshow, :next_week, "#{next_monday_formatted} - #{next_friday_formatted}")
  end

  def load_timeoff(weekly_dates) do
    final_timeoff_map = %{m: [], t: [], w: [], thur: [], f: [], s: [], sun: [], nm: [], nt: [], nw: [], nthur: [], nf: []}
    all_time_off =
      Shophawk.Shopinfo.search_timeoff("", weekly_dates.monday, Date.add(weekly_dates.next_friday, 1))
      |> sort_time_off(weekly_dates, final_timeoff_map)


    order = [:m, :t, :w, :thur, :f, :s, :sun, :nm, :nt, :nw, :nthur, :nf]
    sorted_all_time_off = Enum.map(order, fn key -> {key, Map.get(all_time_off, key, [])} end)
    {week1_timeoff, tail} = Enum.split_while(sorted_all_time_off, fn {k, _v} -> k != :s end)
    {_head, week2_timeoff} = Enum.split_while(tail, fn {k, _v} -> k != :nm end)
    {week1_timeoff, week2_timeoff}
  end

  defp sort_time_off(list, dates, final_timeoff_map) do
    dates_map = Enum.map(0..11, &Date.add(dates.monday, &1))

    sorted_list =
    Enum.reduce(list, final_timeoff_map, fn timeoff, acc ->
      sdate = NaiveDateTime.to_date(timeoff.startdate)
      edate = NaiveDateTime.to_date(timeoff.enddate)
      stime = NaiveDateTime.to_time(timeoff.startdate)
      etime = NaiveDateTime.to_time(timeoff.enddate)
      if sdate == edate do
        key = day_key(Date.diff(sdate, List.first(dates_map)))
        if key != false do
          timeoff_string = set_timeoff_string(timeoff, stime, etime)
          Map.update!(acc, key, fn day -> [timeoff_string | day] end)
        else
          acc
        end
      else
        spread_across_days(timeoff, acc, dates_map, sdate, edate)
      end
    end)
    sorted_list
  end

  defp set_timeoff_string(timeoff, stime, etime) do
    if stime == ~T[07:00:00] and etime == ~T[15:00:00] do
      "#{timeoff.employee} - All Day"
    else
      %Time{hour: shour, minute: sminute} = stime
      %Time{hour: ehour, minute: eminute} = etime
      shour = if shour > 12, do: shour - 12, else: shour
      ehour = if ehour > 12, do: ehour - 12, else: ehour
      "#{timeoff.employee} #{shour}:#{ensure_two_digits(sminute)}-#{ehour}:#{ensure_two_digits(eminute)}"
    end
  end

  defp ensure_two_digits(int) do
    string = Integer.to_string(int)
    if String.length(string) == 1, do: String.pad_leading(string, 2, "0"), else: string
  end

  defp spread_across_days(timeoff, final_timeoff_map, dates_map, sdate, edate) do
    dates = Enum.map(0..Date.diff(edate, sdate), &Date.add(sdate, &1))
    Enum.reduce(dates, final_timeoff_map, fn date, acc ->
      key = day_key(Date.diff(date, List.first(dates_map)))
      if key != false do
        stime = if date == sdate, do: NaiveDateTime.to_time(timeoff.startdate), else: ~T[07:00:00]
        etime = if date == edate, do: NaiveDateTime.to_time(timeoff.enddate), else: ~T[15:00:00]
        timeoff_string = set_timeoff_string(timeoff, stime, etime)
        Map.update!(acc, key, fn list -> [timeoff_string | list] end)
      else
        acc
      end
    end)
  end

  defp day_key(0), do: :m
  defp day_key(1), do: :t
  defp day_key(2), do: :w
  defp day_key(3), do: :thur
  defp day_key(4), do: :f
  defp day_key(7), do: :nm
  defp day_key(8), do: :nt
  defp day_key(9), do: :nw
  defp day_key(10), do: :nthur
  defp day_key(11), do: :nf
  defp day_key(_), do: false

  def transition(index) do
    if rem(index, 2) == 0, do: "fade-out", else: "fade-in"
  end

  def calculate_cell_color(time, am) do
    cond do
    time == "6:00" and am == true -> ""
    time == "4:00" and am == false -> ""
    true -> "bg-stone-100 text-orange-700 border border-black"
    end
  end

  def display_dots(dots) do
    case dots do
      1 -> ~p"/images/one_dot.svg"
      2 -> ~p"/images/two_dots.svg"
      3 -> ~p"/images/three_dots.svg"
      _ -> ""
    end
  end

  def bg_class(dots) do
    case dots do
      1 -> "bg-cyan-500/30"
      2 -> "bg-amber-500/30"
      3 -> "bg-red-600/30"
      _ -> ""
    end
  end

  def timeoff_header_rename(key) do
    case key do
      :m -> "Monday"
      :t -> "Tuesday"
      :w -> "Wednesday"
      :thur -> "Thursday"
      :f -> "Friday"
      :nm -> "Monday"
      :nt -> "Tuesday"
      :nw -> "Wednesday"
      :nthur -> "Thursday"
      :nf -> "Friday"
      _ -> ""
    end
  end

end
