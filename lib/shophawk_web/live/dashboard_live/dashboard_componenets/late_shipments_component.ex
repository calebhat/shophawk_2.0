defmodule ShophawkWeb.LateShipmentsComponent do
  use ShophawkWeb, :live_component

  def render(assigns) do
      ~H"""
        <div class={["text-center justify-center rounded p-4 bg-cyan-900 m-2", @height.border]}>
          <%= if @late_delivery_count > 0 do %>
            <div class={@header_font_size}>
              Late Shipments in the past two weeks: <%= @late_delivery_count %>
            </div>
          <% else %>
            <div class={@header_font_size}>
                Late Shipments
          </div>
          <% end %>
          <%= if @late_deliveries_loaded == false do  %>
              <div class="loader"></div>
          <% else %>
            <%= if @late_deliveries == [] do %>
              <div class="text-4xl pt-24">Zero Late Shipments</div>
            <% else %>
              <div class={["bg-cyan-800 rounded m-2 p-2 overflow-y-auto", @height.frame]}>
                <div class="flex justify-center p-2-md">
                  <table class="w-full text-center table-fixed">
                      <thead class="bg-stone-800 text-white" style={@height.style}>
                        <tr class="">
                          <th class="px-2 py-2 w-40">Job</th>
                          <th class="px-4 py-2 w-16">Qty</th>
                          <th class="px-2 py-2 w-50">Part Number</th>
                          <th class="px-2 py-2 hidden 2xl:table-cell">Description</th>
                          <th class="px-2 py-2 w-28">Ship Date</th>
                          <th class="px-4 py-2 w-44">Customer</th>
                          <th class="px-4 py-2 w-44">Location</th>
                        </tr>
                      </thead>
                    <tbody id="late_shipments_component" class="bg-white">
                      <tr
                        :for={job <- @late_deliveries}
                        id="late_ships"
                        class={["text-stone-950 border border-stone-800 hover:cursor-pointer hover:bg-stone-400"]}
                        style={@height.style}
                        phx-click="show_job" phx-value-job={job.job}
                      >
                        <td class="py-1 truncate font-bold" style=""><%= job.job %></td>
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
          <% end %>
        </div>
      """
  end

end
