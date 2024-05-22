defmodule ShophawkWeb.SlideshowLive.SlideshowComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Shopinfo

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-screen w-sceen">
      <div class="grid grid-cols-1">
      <div class={transition(@slide_index)} >
      <%= case @slide do %>
        <% :hours -> %>
          <div class="text-8xl text-center rounded-t-lg p-4 underline">Shop Hours</div>
          <div class="grid grid-cols-2 content-center rounded-b-lg">
            <div class="bg-stone-800 rounded-lg m-4 p-4 text-white">
              <div class="mt-4 text-6xl flex justify-center">Current Week</div>
              <div class="mt-1 pb-4 text-4xl flex justify-center border-b-4 border-black"><%= @slideshow.this_week%></div>

                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Monday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.mondayo1)]}><%= @slideshow.mondayo1 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.mondayc1)]}><%= @slideshow.mondayc1 %> </div>
                </div>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Tuesday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.tuesdayo1)]}><%= @slideshow.tuesdayo1 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.tuesdayc1)]}><%= @slideshow.tuesdayc1 %> </div>
                </div>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Wednesday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.wednesdayo1)]}><%= @slideshow.wednesdayo1 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.wednesdayc1)]}><%= @slideshow.wednesdayc1 %> </div>
                </div>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Thursday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.thursdayo1)]}><%= @slideshow.thursdayo1 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.thursdayc1)]}><%= @slideshow.thursdayc1 %> </div>
                </div>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Friday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.fridayo1)]}><%= @slideshow.fridayo1 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.fridayc1)]}><%= @slideshow.fridayc1 %> </div>
                </div>
                <%= if @slideshow.showsaturday1 == true do %>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Saturday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.saturdayo1)]}><%= @slideshow.saturdayo1 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.saturdayc1)]}><%= @slideshow.saturdayc1 %> </div>
                </div>
                <% end %>
            </div>
            <div class="bg-stone-800 text-white rounded-lg m-4 p-4">
              <div class="mt-4 text-6xl flex justify-center">Next Week</div>
              <div class="mt-1 pb-4 text-4xl flex justify-center border-b-4 border-black"><%= @slideshow.next_week%></div>
              <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Monday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.mondayo2)]}><%= @slideshow.mondayo2 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.mondayc2)]}><%= @slideshow.mondayc2 %> </div>
                </div>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Tuesday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.tuesdayo2)]}><%= @slideshow.tuesdayo2 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.tuesdayc2)]}><%= @slideshow.tuesdayc2 %> </div>
                </div>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Wednesday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.wednesdayo2)]}><%= @slideshow.wednesdayo2 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.wednesdayc2)]}><%= @slideshow.wednesdayc2 %> </div>
                </div>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Thursday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.thursdayo2)]}><%= @slideshow.thursdayo2 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.thursdayc2)]}><%= @slideshow.thursdayc2 %> </div>
                </div>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Friday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.fridayo2)]}><%= @slideshow.fridayo2 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.fridayc2)]}><%= @slideshow.fridayc2 %> </div>
                </div>
                <%= if @slideshow.showsaturday1 == true do %>
                <div class="grid grid-cols-3 text-6xl py-4 border-b-4 border-black">
                  <div class="grid justify-center">Saturday</div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.saturdayo2)]}><%= @slideshow.saturdayo2 %> </div>
                  <div class={["grid justify-center mx-12 py-1 rounded-lg", calculate_cell_color(@slideshow.saturdayc2)]}><%= @slideshow.saturdayc2 %> </div>
                </div>
                <% end %>
            </div>
          </div>
        <% :hot_jobs -> %>
          <div class="m-4">
            <table class="w-full text-center table-fixed bg-white" >
              <div class="rounded-t-lg bg-stone-800 p-2 text-center text-white text-4xl underline">
              Hot Jobs
                <thead class="bg-stone-800 text-white" style="font-size: 1.5vw">
                  <tr class="">
                    <th class="px-4 py-2 w-40">Job</th>
                    <th class="px-4 py-2 w-24">Dots</th>
                    <th class="px-4 py-2 w-20">Qty</th>
                    <th class="px-4 py-2 w-64">Part Number</th>
                    <th class="px-4 py-2 ">Description</th>
                    <th class="px-4 py-2 w-48">Ship Date</th>
                    <th class="px-4 py-2 w-72">Customer</th>
                    <th class="px-4 py-2 w-56">Location</th>
                  </tr>
                </thead>
              </div>
              <tbody id="hot_jobs" phx-update="stream">
                <tr
                  :for={{dom_id, job} <- @streams.hot_jobs}
                  id={dom_id}
                  class={"text-stone-950  border border-stone-800 " <> bg_class(job.dots)}
                >
                  <td class="px-4 py-2 truncate" style="font-size: 2vw"><%= job.job %></td>
                  <td class="px-4 py-2 truncate"><img class="grid justify-items-start" src={display_dots(job.dots)} /></td>
                  <td class="px-4 py-2 truncate" style="font-size: 2vw"><%= job.make_quantity %></td>
                  <td class="px-4 py-2 truncate" style="font-size: 1.5vw"><%= job.part_number %></td>
                  <td class="px-4 py-2 truncate" style="font-size: 1.5vw"><%= job.description %></td>
                  <td class="px-4 py-2 truncate" style="font-size: 2vw"><%= Calendar.strftime(job.job_sched_end, "%m-%d-%y") %></td>
                  <td class="px-4 py-2 truncate" style="font-size: 1.5vw"><%= job.customer %></td>
                  <td class="px-4 py-2 truncate" style="font-size: 1.5vw"><%= job.currentop %></td>
                </tr>
              </tbody>
            </table>
          </div>
        <% :announcement1 -> %>
          <div class="relative w-[90vw] h-screen flex items-center justify-center">
            <div class="container mx-auto py-4">
              <div style="font-size: clamp(3vw, 5vw, 8vw)" class="text-center"> <%= raw @slideshow.announcement1 %> </div>
              <div class="absolute bottom-0 left-0 m-8"><img src={~p"/images/announcement1.svg"} width="200" /></div>
            </div>
          </div>
        <% :announcement2 -> %>
          <div class="relative w-[90vw] h-screen flex items-center justify-center">
            <div class="container mx-auto py-4">
              <div style="font-size: clamp(3vw, 5vw, 8vw)" class="text-center"> <%= raw @slideshow.announcement2 %> </div>
              <div class="absolute top-0 right-0 m-8"><img src={~p"/images/announcement2.svg"} width="200" /></div>
            </div>
          </div>
        <% :announcement3 -> %>
          <div class="relative w-[90vw] h-screen flex items-center justify-center">
            <div class="container mx-auto py-4">
              <div style="font-size: clamp(3vw, 5vw, 8vw)" class="text-center"> <%= raw @slideshow.announcement3 %> </div>
              <div class="absolute top-0 left-0 m-8"><img src={~p"/images/announcement3.svg"} width="200" /></div>
            </div>
          </div>
        <% :quote -> %><img style="object-fit: cover;  height: 90vh" src={@slideshow.quote}>
        <% :photo -> %><img style="object-fit: cover;  height: 90vh" src={@slideshow.photo}>
        <% :birthdays -> %>
          <div class="h-screen w-[90vw] flex flex-col justify-between">
            <div class="text-center grid grid-cols-3 flex">
              <div><img class="grid justify-items-start" src={~p"/images/party_flags.svg"} width="200" /></div>
              <div style="font-size: clamp(3vw, 5vw, 8vw)" class="border-black border-b-4 w-max content-end">Happy Birthday! </div>
              <div class="grid justify-items-end"><img src={~p"/images/party_flags.svg"} width="200" class="rotate90" /></div>
            </div>
            <div style="font-size: clamp(3vw, 5vw, 8vw)" class=" text-center">
              <div>
                <%= for bday <- @slideshow.birthdays do %>
                <%= bday %><br>
                <% end %>
              </div>
            </div>
            <div class="text-center grid grid-cols-2 flex items-end mb-10">
              <div><img class="grid justify-items-start" src={~p"/images/party-blower.svg"} width="200" /></div>
              <div class="grid justify-items-end"><img src={~p"/images/party-confetti.svg"} width="200" class="rotate-90" /></div>
            </div>
          </div>
        <% end %>
        </div>
      </div>
    </div>
  """
end

  @impl true
  def update(%{slideshow: slideshow, slide: slide, slide_index: index} = assigns, socket) do
    slide_time = 3000 #seconds to next slide
    IO.inspect(slide)
    slideshow =
    case slide do
      :hours ->
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
        #add current and next week dates to slideshow map
        today = Date.utc_today()
        day_of_week = Date.day_of_week(today)
        monday = Date.add(today, -(day_of_week - 1))
        friday = Date.add(monday, 4)
        next_monday = Date.add(monday, 7)
        next_friday = Date.add(next_monday, 4)
        monday_formatted = Date.to_string(monday) |> String.split("-") |> Enum.take(-2) |> Enum.join("/")
        friday_formatted = Date.to_string(friday) |> String.split("-") |> Enum.take(-2) |> Enum.join("/")
        next_monday_formatted = Date.to_string(next_monday) |> String.split("-") |> Enum.take(-2) |> Enum.join("/")
        next_friday_formatted = Date.to_string(next_friday) |> String.split("-") |> Enum.take(-2) |> Enum.join("/")
        slideshow = Map.put(slideshow, :this_week, "#{monday_formatted} - #{friday_formatted}")
        slideshow = Map.put(slideshow, :next_week, "#{next_monday_formatted} - #{next_friday_formatted}")
      :announcement1 -> slideshow = Map.put(slideshow, :announcement1, slideshow.announcement1 |> String.replace("\n", "<br>"))
      :announcement2 -> slideshow = Map.put(slideshow, :announcement2, slideshow.announcement2 |> String.replace("\n", "<br>"))
      :announcement3 -> slideshow = Map.put(slideshow, :announcement3, slideshow.announcement3 |> String.replace("\n", "<br>"))
      _ -> slideshow
      end
      socket =
        if slide == :hot_jobs do
          stream(socket, :hot_jobs, slideshow.hot_jobs, reset: true)
        else
          socket
        end

    index = index + 1 #used to trigger css animations
    index = if index == 10, do: 0, else: index
    process = self()
    if rem(index, 2) == 0 do
      Task.start(fn ->
        Process.send_after(process, {:next_slide, slideshow, assigns.slide, index}, 300)
      end)
    else #fade animations
      Task.start(fn ->
        Process.send_after(process, {:next_slide_animation, slideshow, assigns.slide, index}, slide_time)
      end)
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(slideshow: slideshow)
     |> assign(slide_index: index)}
  end

  defp transition(index) do
    if rem(index, 2) == 0, do: "fade-out", else: "fade-in"
  end

  def calculate_cell_color(time) do
    if time == "6:00" or time == "4:00" do
      ""
    else
      "bg-stone-100 text-orange-700 border border-black"
    end
  end

  def display_dots(dots) do
    case dots do
      1 -> ~p"/images/one_dot.svg"
      2 -> ~p"/images/two_dots.svg"
      3 -> ~p"/images/three_dots.svg"
      _ ->
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

end