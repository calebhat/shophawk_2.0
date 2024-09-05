defmodule ShophawkWeb.MonthlySalesChartComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
      <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[86vh]">
        <div class="text-2xl underline pb-4">
            Monthly Sales
        </div>
        <%= if @this_months_sales != 0 do  %>
            <div class="grid grid-cols-3 text-xl">
                <div class="border-b border-stone-400 rounded-lg">This Years Sales</div>
                <div class="border-b border-stone-400 rounded-lg">This Months Sales</div>
                <div class="border-b border-stone-400 rounded-lg">Projected Yearly Sales</div>
                <div class=""><%= number_to_currency(@this_years_sales) %></div>
                <div class=""><%= number_to_currency(@this_months_sales) %></div>
                <div class=""><%= number_to_currency(@projected_yearly_sales) %></div>
            </div>
        <% end %>
        <%= if @this_months_sales != 0 do  %>
            <div class="text-md bg-cyan-800 rounded m-2 p-2 h-[78%] 2xl:h-[85%] text-black">
                <div id="mainChart" phx-hook="monthly_sales_chart" data-sales-chart={@sales_chart_data}></div>
            </div>
        <% else %>
            <div class="loader"></div>
        <% end %>
      </div>
    """
  end
end
