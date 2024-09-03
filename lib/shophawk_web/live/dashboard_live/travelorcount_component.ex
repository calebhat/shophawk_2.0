defmodule ShophawkWeb.TravelorcountComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
    <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[43vh]">
        <div class="text-2xl">
            Travelors Released in the past week
        </div>
        <%= if Enum.empty?(@travelor_count) do  %>
            <div class="loader"></div>
        <% else %>
            <div class="text-xl bg-cyan-800 rounded m-2 p-2 h-[87%] overflow-y-auto">
                <div class="flex justify-center p-2 ">
                    <table class="w-full">
                        <thead>
                            <tr>
                                <th class="">Date</th>
                                <th class="">Day</th>
                                <th class="">Dave</th>
                                <th class="">Jamie</th>
                                <th class="">Brent</th>
                                <th class="">Greg</th>
                                <th class="">Caleb</th>
                                <th class="">Mike</th>
                                <th class="">Total</th>
                            </tr>
                        </thead>
                        <tbody id="travelors">
                            <tr
                            :for={t <- @travelor_count}
                            id="travelors_counts"
                            class="hover:bg-cyan-700"
                            >
                                <td class="py-2 border border-stone-500"><%= t.date %></td>
                                <td class="border border-stone-500"><%= Enum.at(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], Date.day_of_week(t.date) - 1) %></td>
                                <td class="border border-stone-500"><%= t.dave %></td>
                                <td class="border border-stone-500"><%= t.jamie %></td>
                                <td class="border border-stone-500"><%= t.brent %></td>
                                <td class="border border-stone-500"><%= t.greg %></td>
                                <td class="border border-stone-500"><%= t.caleb %></td>
                                <td class="border border-stone-500"><%= t.mike %></td>
                                <td class="border border-stone-500"><%= t.total %></td>
                            </tr>
                            <tr
                            :for={t <- [@travelor_totals]}
                            id="checkbook_entries"
                            class="border-t-4 border-stone-500 hover:bg-cyan-700"
                            >
                                <td></td>
                                <td class="py-2 border border-stone-500">Total</td>
                                <td class="border border-stone-500"><%= t.dave_total %></td>
                                <td class="border border-stone-500"><%= t.jamie_total %></td>
                                <td class="border border-stone-500"><%= t.brent_total %></td>
                                <td class="border border-stone-500"><%= t.greg_total %></td>
                                <td class="border border-stone-500"><%= t.caleb_total %></td>
                                <td class="border border-stone-500"><%= t.mike_total %></td>
                                <td class="border border-stone-500"><%= t.total_total %></td>
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
