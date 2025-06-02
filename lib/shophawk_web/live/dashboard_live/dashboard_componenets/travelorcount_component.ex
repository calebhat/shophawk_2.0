defmodule ShophawkWeb.TravelorcountComponent do
  use ShophawkWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class={["text-center justify-center rounded p-2 bg-cyan-900 m-2", @height.border]}>
        <div class="text-[1.5vw] truncate]">
            Travelors Released in the Last 5 Days
        </div>
        <%= if Enum.empty?(@travelor_count) do  %>
            <div class="loader"></div>
        <% else %>
        <div class={["text-xl bg-cyan-800 rounded m-2 px-2 overflow-y-auto sm:text-lg md:text-xl lg:text-2xl", @height.frame]}>
            <div class="flex justify-center px-2 overflow-x-auto">
                <table class="w-full table-auto">
                    <thead>
                        <tr class="text-sm md:text-base lg:text-lg">
                            <th class="px-2 py-1 hidden 2xl:block">Date</th>
                            <th class="px-2 py-1">Day</th>
                            <th class="px-2 py-1">Dave</th>
                            <th class="px-2 py-1">Jamie</th>
                            <th class="px-2 py-1">Brent</th>
                            <th class="px-2 py-1">Greg</th>
                            <th class="px-2 py-1">Caleb</th>
                            <th class="px-2 py-1">Nolan</th>
                            <th class="px-2 py-1">Mike</th>
                            <th class="px-2 py-1">Total</th>
                        </tr>
                    </thead>
                    <tbody id="travelors">
                        <tr :for={t <- @travelor_count} id="travelors_counts" class="hover:bg-cyan-700 text-sm md:text-base lg:text-lg">
                            <td class="text-base hidden 2xl:block 2xl:py-2 border border-stone-500 px-2"><%= t.date %></td>
                            <td class="border border-stone-500 px-2"><%= Enum.at(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], Date.day_of_week(t.date) - 1) %></td>
                            <td class="border border-stone-500 px-2"><%= t.dave %></td>
                            <td class="border border-stone-500 px-2"><%= t.jamie %></td>
                            <td class="border border-stone-500 px-2"><%= t.brent %></td>
                            <td class="border border-stone-500 px-2"><%= t.greg %></td>
                            <td class="border border-stone-500 px-2"><%= t.caleb %></td>
                            <td class="border border-stone-500 px-2"><%= t.nolan %></td>
                            <td class="border border-stone-500 px-2"><%= t.mike %></td>
                            <td class="border border-stone-500 px-2"><%= t.total %></td>
                        </tr>
                        <tr :for={t <- [@travelor_totals]} id="checkbook_entries" class="border-t-4 border-stone-500 hover:bg-cyan-700 text-sm md:text-base lg:text-lg">
                            <td></td>
                            <td class="py-2 border border-stone-500 px-2  hidden 2xl:block">Total</td>
                            <td class="border border-stone-500 px-2"><%= t.dave_total %></td>
                            <td class="border border-stone-500 px-2"><%= t.jamie_total %></td>
                            <td class="border border-stone-500 px-2"><%= t.brent_total %></td>
                            <td class="border border-stone-500 px-2"><%= t.greg_total %></td>
                            <td class="border border-stone-500 px-2"><%= t.caleb_total %></td>
                            <td class="border border-stone-500 px-2"><%= t.nolan_total %></td>
                            <td class="border border-stone-500 px-2"><%= t.mike_total %></td>
                            <td class="border border-stone-500 px-2"><%= t.total_total %></td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
        <% end %>
    </div>
    """
  end
end
