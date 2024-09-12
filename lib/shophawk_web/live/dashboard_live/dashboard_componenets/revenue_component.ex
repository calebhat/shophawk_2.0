defmodule ShophawkWeb.RevenueComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
      <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[86vh]">
        <%= if @total_revenue != 0 do  %>
            <div class="grid grid-cols-3 text-4xl">
                <div class="border-b border-stone-400 rounded-lg">Total Anticipated Revenue</div>
                <div class="border-b border-stone-400 rounded-lg">Six Weeks Revenue</div>
                <div class="border-b border-stone-400 rounded-lg">Active Jobs Right Now</div>
                <div class=""><%= number_to_currency(@total_revenue) %></div>
                <div class="flex justify-center">
                  <div><%= number_to_currency(@six_weeks_revenue_amount) %></div>
                  <div class="dark-tooltip-container grid grid-cols-1">
                    <div class={text_color(@percentage_diff)}><%= @percentage_diff %></div>
                    <div class="tooltip ml-6">Change from 2 weeks ago</div>
                  </div>
                </div>
                <div class=""><%= @active_jobs %></div>
            </div>
        <% end %>
        <%= if @total_revenue != 0 do  %>
            <div class="text-md bg-cyan-800 rounded m-2 p-2 h-[78%] 2xl:h-[85%] text-black">
                <div id="Revenue_Chart" phx-hook="Revenue_Chart" data-revenue-chart={@revenue_chart_data}></div>
            </div>
        <% else %>
          <div class="text-4xl">Anticipated Revenue </div>
          <div class="loader"></div>
        <% end %>
      </div>
    """
  end

  def text_color(string) do
    case String.contains?(string, "-") do
      true -> "font-bold mx-4 text-red-500"
      _ -> "font-bold text-green-400 mx-4"
    end
  end

end
