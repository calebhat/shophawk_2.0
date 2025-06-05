defmodule ShophawkWeb.SlideshowLive.SlideshowComponent do
  use ShophawkWeb, :live_component
  alias ShophawkWeb.SlideshowLive.Index, as: Parent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center w-sceen" style="height: 100vh">
      <div class="grid grid-cols-1">
      <div class={Parent.transition(@slide_index)} >
      <%= case @slide do %>
        <% :hours -> %>
          <div class="grid grid-cols-2 content-center rounded-b-lg">
            <div class="bg-stone-800 rounded-lg m-4 p-4 text-white"  style="font-size: 5vh">
              <div class="mt-4 text-6xl flex justify-center">Current Week</div>
              <div class="mt-1 pb-4 text-4xl flex justify-center border-b-4 border-black"><%= @slideshow.this_week%></div>

                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                <div class="grid justify-center">Monday</div>
                  <%= case @slideshow.mondayo1 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.mondayo1, true)]}><%= @slideshow.mondayo1 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.mondayc1, false)]}><%= @slideshow.mondayc1 %> </div>
                  <% end %>
                </div>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Tuesday</div>
                  <%= case @slideshow.tuesdayo1 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.tuesdayo1, true)]}><%= @slideshow.tuesdayo1 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.tuesdayc1, false)]}><%= @slideshow.tuesdayc1 %> </div>
                  <% end %>
                </div>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center" style="font-size: 4vh">Wednesday</div>
                  <%= case @slideshow.wednesdayo1 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.wednesdayo1, true)]}><%= @slideshow.wednesdayo1 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.wednesdayc1, false)]}><%= @slideshow.wednesdayc1 %> </div>
                  <% end %>
                </div>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Thursday</div>
                  <%= case @slideshow.thursdayo1 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.thursdayo1, true)]}><%= @slideshow.thursdayo1 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.thursdayc1, false)]}><%= @slideshow.thursdayc1 %> </div>
                  <% end %>
                </div>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Friday</div>
                  <%= case @slideshow.fridayo1 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.fridayo1, true)]}><%= @slideshow.fridayo1 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.fridayc1, false)]}><%= @slideshow.fridayc1 %> </div>
                  <% end %>
                </div>
                <%= if @slideshow.showsaturday1 == true do %>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Saturday</div>
                  <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.saturdayo1, false)]}><%= @slideshow.saturdayo1 %> </div>
                  <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.saturdayc1, true)]}><%= @slideshow.saturdayc1 %> </div>
                </div>
                <% end %>
            </div>
            <div class="bg-stone-800 text-white rounded-lg m-4 p-4"  style="font-size: 5vh">
              <div class="text-6xl flex justify-center">Next Week</div>
              <div class="mt-1 pb-4 text-4xl flex justify-center border-b-4 border-black"><%= @slideshow.next_week%></div>
              <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Monday</div>
                  <%= case @slideshow.mondayo2 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.mondayo2, true)]}><%= @slideshow.mondayo2 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.mondayc2, false)]}><%= @slideshow.mondayc2 %> </div>
                  <% end %>
                </div>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Tuesday</div>
                  <%= case @slideshow.tuesdayo2 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.tuesdayo2, true)]}><%= @slideshow.tuesdayo2 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.tuesdayc2, false)]}><%= @slideshow.tuesdayc2 %> </div>
                  <% end %>
                </div>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black" style="font-size: 4vh">
                  <div class="grid justify-center">Wednesday</div>
                  <%= case @slideshow.wednesdayo2 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.wednesdayo2, true)]}><%= @slideshow.wednesdayo2 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.wednesdayc2, false)]}><%= @slideshow.wednesdayc2 %> </div>
                  <% end %>
                </div>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Thursday</div>
                  <%= case @slideshow.thursdayo2 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.thursdayo2, true)]}><%= @slideshow.thursdayo2 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.thursdayc2, false)]}><%= @slideshow.thursdayc2 %> </div>
                  <% end %>
                </div>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Friday</div>
                  <%= case @slideshow.fridayo2 do %>
                  <% "" -> %>
                    <div class="col-span-2 grid justify-center mx-12 px-6 rounded-lg">Closed</div>
                    <div></div>
                  <% _ -> %>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.fridayo2, true)]}><%= @slideshow.fridayo2 %> </div>
                    <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.fridayc2, false)]}><%= @slideshow.fridayc2 %> </div>
                  <% end %>
                </div>
                <%= if @slideshow.showsaturday2 == true do %>
                <div class="grid grid-cols-3 py-4 border-b-4 border-black">
                  <div class="grid justify-center">Saturday</div>
                  <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.saturdayo2, false)]}><%= @slideshow.saturdayo2 %> </div>
                  <div class={["grid justify-center mx-12 px-6 rounded-lg", Parent.calculate_cell_color(@slideshow.saturdayc2, true)]}><%= @slideshow.saturdayc2 %> </div>
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
                    <th class="px-4 py-2 w-48">Job</th>
                    <th class="px-4 py-2 w-24">Dots</th>
                    <th class="px-4 py-2 w-20">Qty</th>
                    <th class="px-4 py-2 w-64">Part Number</th>
                    <th class="px-4 py-2 hidden 2xl:table-cell">Description</th>
                    <th class="px-4 py-2 w-48">Ship Date</th>
                    <th class="px-4 py-2">Customer</th>
                    <th class="px-4 py-2 w-56">Location</th>
                  </tr>
                </thead>
              </div>
              <tbody id="hot_jobs" phx-update="stream">
                <tr
                  :for={{dom_id, job} <- @streams.hot_jobs}
                  id={dom_id}
                  class={["text-stone-950 border border-stone-800", ShophawkWeb.HotjobsComponent.bg_class(job.dots, job.currentop)]}
                >
                  <td class="px-4 py-2 truncate font-bold" style="font-size: 2vw"><%= job.job %></td>
                  <td class="px-4 py-2 truncate"><img class="grid justify-items-start" src={ShophawkWeb.HotjobsComponent.display_dots(job.dots)} /></td>
                  <td class="px-4 py-2 truncated font-bold" style="font-size: 2vw"><%= job.make_quantity %></td>
                  <td class="px-4 py-2 truncate font-bold" style="font-size: 1.5vw"><%= job.part_number %></td>
                  <td class="px-4 py-2 truncate font-bold hidden 2xl:table-cell" style="font-size: 1.5vw"><%= job.description %></td>
                  <td class="px-4 py-2 truncate font-bold" style="font-size: 2vw"><%= Calendar.strftime(job.job_sched_end, "%m-%d-%y") %></td>
                  <td class="px-4 py-2 truncate font-bold" style="font-size: 1.5vw"><%= job.customer %></td>
                  <td class="px-4 py-2 truncate font-bold" style="font-size: 1.5vw"><%= ShophawkWeb.HotjobsComponent.currentop_complete(job.currentop) %></td>
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
        <% :personal_time -> %>
          <div class="relative w-[90vw] h-screen flex items-center justify-center">
            <div class="container mx-auto py-4">
              <div style="font-size: clamp(3vw, 5vw, 8vw)" class="text-center">
              Personal Time is earned <%= @slideshow.personal_time %>. If you're total accrument will be more than 24 hours, make sure to use it before then or it will get paid out as a bonus.
              </div>
              <div class="absolute bottom-0 left-0 m-8"><img src={~p"/images/island.svg"} width="200" /></div>
              <div class="absolute bottom-0 right-0 m-8"><img src={~p"/images/drink.svg"} width="200" /></div>
            </div>
          </div>
        <% :quote -> %><img style="object-fit: cover;  height: 90vh" src={@slideshow.quote}>
        <% :photo -> %><img style="object-fit: cover;  height: 90vh" src={@slideshow.photo}>
        <% :eg_photo -> %><img style="object-fit: cover; height: 90vh" src={"/slideshow_photos/" <> @slideshow.eg_photo}>
        <% :birthdays -> %>
          <div class="h-screen w-[90vw] flex flex-col justify-between">
            <div class="text-center grid grid-cols-3">
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
            <div class="text-center grid grid-cols-2 items-end mb-10">
              <div><img class="grid justify-items-start" src={~p"/images/party-blower.svg"} width="200" /></div>
              <div class="grid justify-items-end"><img src={~p"/images/party-confetti.svg"} width="200" class="rotate-90" /></div>
            </div>
          </div>
        <% :week1_timeoff -> %>
          <div class="justify-center h-screen w-sceen">
            <div class="text-center text-6xl font-bold">
              This weeks Time Off
            </div>
            <div class="text-center text-4xl border-b-4 border-stone-600 pb-2  font-bold">
              <%= Calendar.strftime(@slideshow.weekly_dates.monday, "%m-%d") %> to <%= Calendar.strftime(@slideshow.weekly_dates.friday, "%m-%d") %>
            </div>
            <div class="grid grid-cols-5 text-6xl text-center">
              <%= for {key, values} <- @slideshow.week1_timeoff do %>
                <div>
                  <h2 class="font-bold pb-4" style="font-size: 3vw"><%= Parent.timeoff_header_rename(key) %></h2>
                  <ul class="border-black border text-4xl font-bold">
                    <%= for value <- values do %>
                      <li class="border border-y border-black py-4" style="font-size: 2vw"><%= value %></li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
            </div>
          </div>
        <% :week2_timeoff -> %>
          <div class="justify-center h-screen w-sceen">
            <div class="text-center text-6xl font-bold">
              Next weeks Time Off
            </div>
            <div class="text-center text-4xl border-b-4 border-stone-600 pb-2 font-bold">
              <%= Calendar.strftime(@slideshow.weekly_dates.next_monday, "%m-%d") %> to <%= Calendar.strftime(@slideshow.weekly_dates.next_friday, "%m-%d") %>
            </div>
            <div class="grid grid-cols-5 text-6xl text-center">
              <%= for {key, values} <- @slideshow.week2_timeoff do %>
                <div>
                  <h2 class="font-bold pb-4" style="font-size: 3vw"><%= Parent.timeoff_header_rename(key) %></h2>
                  <ul class="border-black border text-4xl font-bold">
                    <%= for value <- values do %>
                      <li class="border border-y border-black py-4" style="font-size: 2vw"><%= value %></li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
            </div>
          </div>
        <% nil -> %> <div class="text-6xl">Initializing Slideshow</div>
        <% end %>
        </div>
      </div>
    </div>
  """
end

  @impl true
  def update(%{slideshow: slideshow, slide: slide, slide_index: index, slides: slides} = assigns, socket) do
    slide_time = if slide == nil, do: 800, else: 7000 #seconds to next slide
    socket = if Map.has_key?(socket, :next_slide) == false, do: assign(socket, :next_slide, :hours), else: socket

    process = self()
    if rem(index, 2) == 0 do
      Task.start(fn ->
        Process.send_after(process, {:next_slide, slideshow, assigns.slide, index, slides}, 300)
      end)
    else #fade animations
      Task.start(fn ->
        Process.send_after(process, {:next_slide_animation, slideshow, assigns.slide, index, slides}, slide_time)
      end)
    end
    socket = if slide == :hot_jobs, do: stream(socket, :hot_jobs, slideshow.hot_jobs, reset: true), else: socket
    {:ok, socket |> assign(slideshow: slideshow) |> assign(slide: slide) |> assign(assigns) |> assign(slide_index: index)}
  end

end
