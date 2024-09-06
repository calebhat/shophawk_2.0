defmodule ShophawkWeb.HotjobsComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
      ~H"""
        <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[43vh]">
        <div class="text-2xl">
            Hot Jobs
        </div>
        <%= if Enum.empty?(@hot_jobs) do  %>
            <div class="loader"></div>
        <% else %>
            <div class="bg-cyan-800 rounded m-2 p-2 h-[87%] overflow-y-auto">
              <div class="flex justify-center p-2-md">
                <table class="w-full text-center table-fixed">
                    <thead class="bg-stone-800 text-white" style="font-size: .75vw">
                      <tr class="">
                        <th class="px-2 py-2 w-20">Job</th>
                        <th class="px-2 py-2 w-10">Dots</th>
                        <th class="px-4 py-2 w-10">Qty</th>
                        <th class="px-2 py-2 w-20">Part Number</th>
                        <th class="px-2 py-2 hidden 2xl:table-cell">Description</th>
                        <th class="px-2 py-2 w-20">Ship Date</th>
                        <th class="px-4 py-2 w-24">Customer</th>
                        <th class="px-4 py-2 w-24">Location</th>
                      </tr>
                    </thead>
                  <tbody id="hot_jobs_component" class="bg-white">
                    <tr
                      :for={job <- @hot_jobs}
                      id="hot_jobs"
                      class={["text-stone-950 border border-stone-800", bg_class(job.dots)]}
                      style="font-size: .75vw"
                    >
                      <td class="py-1 truncate font-bold" style=""><%= job.job %></td>
                      <td class="py-1 truncate"><img class="grid justify-items-start" src={display_dots(job.dots)} /></td>
                      <td class="py-1 truncated font-bold" style=""><%= job.make_quantity %></td>
                      <td class="py-1 truncate font-bold" style=""><%= job.part_number %></td>
                      <td class="py-1 truncate font-bold hidden 2xl:table-cell" style=""><%= job.description %></td>
                      <td class="py-1 truncate font-bold" style=""><%= Calendar.strftime(job.job_sched_end, "%m-%d-%y") %></td>
                      <td class="py-1 truncate font-bold" style=""><%= job.customer %></td>
                      <td class="py-1 truncate font-bold" style=""><%= job.currentop %></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
        <% end %>
    </div>
      """
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

end