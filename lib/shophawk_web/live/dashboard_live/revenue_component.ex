defmodule ShophawkWeb.RevenueComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
      <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[86vh]">
        <div class="text-2xl underline pb-4">
            Anticipated Revenue
        </div>
        <%= if @total_revenue != 0 do  %>
            <div class="grid grid-cols-3 text-xl">
                <div class="border-b border-stone-400 rounded-lg">Total Revenue</div>
                <div class="border-b border-stone-400 rounded-lg">Six Weeks Revenue Amount</div>
                <div class="border-b border-stone-400 rounded-lg">Active Jobs Right Now</div>
                <div class=""><%= number_to_currency(@total_revenue) %></div>
                <div class=""><%= number_to_currency(@six_weeks_revenue_amount) %></div>
                <div class=""><%= @active_jobs %></div>
            </div>
        <% end %>
        <%= if @total_revenue != 0 do  %>
            <div class="text-md bg-cyan-800 rounded m-2 p-2 h-[85%] text-black">
                <div id="mainChart" phx-hook="ApexChart" data-chart-data={@chart_data}></div>
            </div>
        <% else %>
            <div class="loader"></div>
        <% end %>
      </div>
    """
  end
end
