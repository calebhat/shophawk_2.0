defmodule ShophawkWeb.RevenueComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
      <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[43vh]">
        <div class="text-2xl">
            Anticipated Revenue
        </div>
        <%= if Enum.empty?(@revenue_history) == false do  %>
            <div class="grid grid-cols-3">
                <div class="border-b border-stone-400  rounded-lg cursor-pointer">Total Revenue</div>
                <div class="border-b border-stone-400 rounded-lg cursor-pointer">six_weeks_revenue_amount</div>
                <div class="border-b border-stone-400 rounded-lg cursor-pointer">active_jobs</div>
                <div class=""><%= number_to_currency(@total_revenue) %></div>
                <div class=""><%= number_to_currency(@six_weeks_revenue_amount) %></div>
                <div class=""><%= @active_jobs %></div>
            </div>
        <% end %>
        <%= if Enum.empty?(@revenue_history) do  %>
            <div class="loader"></div>
        <% else %>
            <div class="text-md bg-cyan-800 rounded m-2 p-2 h-[30vh] overflow-y-auto">
                <div class="flex justify-center p-2 ">
                    <table class="w-full">
                        <thead>
                            <tr>
                                <th class="w-1/4">total_revenue</th>
                                <th class="w-1/4">six_week_revenue</th>
                                <th class="w-1/4">total_jobs</th>
                                <th class="w-1/4">week</th>

                            </tr>
                        </thead>
                        <tbody id="checkbook">
                            <tr
                            :for={d <- @revenue_history}
                            id="checkbook_entries"
                            class="border-b border-stone-500 hover:bg-cyan-700"
                            >
                                <td><%= d.total_revenue %></td>
                                <td><%= d.six_week_revenue %></td>
                                <td><%= d.total_jobs %></td>
                                <td><%= d.week %></td>
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
