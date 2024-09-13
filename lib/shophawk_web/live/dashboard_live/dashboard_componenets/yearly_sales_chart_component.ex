defmodule ShophawkWeb.YearlySalesChartComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
      <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[86vh]">
        <div class="text-2xl underline pb-4">
            Top 10 Customers & Yearly Sales
        </div>
          <%= if @yearly_sales_data == [] do %>
            <%= if @yearly_sales_loading == false do %>
            <div class="grid grid-cols-1 text-xl">
              <div class="border-b border-stone-400 rounded-lg">Load Chart</div>
              <div class=""><.button phx-click="load_yearly_sales_customer">(can take 1 minute)</.button></div>
            </div>
            <% else %>
              <div></div>
            <% end %>
          <% else %>
            <div class="grid grid-cols-2 text-4xl">
              <div class="border-b border-stone-400 rounded-lg">Total Sales</div>
              <div class="border-b border-stone-400 rounded-lg">Controls</div>
              <div class=""><%= number_to_currency(@total_sales) %></div>
              <div class="">
                <.button phx-click="add_yearly_sales_customer">+</.button>
                <.button phx-click="subtract_yearly_sales_customer">-</.button>
                <.button phx-click="clear_yearly_sales_customer">Clear Graph</.button>
              </div>
            </div>
          <% end %>
        <%= if @yearly_sales_loading == false do  %>
          <%= if @yearly_sales_data != [] do %>
            <div class="text-md bg-cyan-800 rounded m-2 p-2 h-[78%] 2xl:h-[83%] text-black">
                <div id="YearlySales_Chart" phx-hook="yearly_sales_Chart" data-yearlysales-chart={@yearly_sales_data}></div>
            </div>
            <% end %>
        <% else %>
            <div class="loader"></div>
        <% end %>
      </div>
    """
  end
end
