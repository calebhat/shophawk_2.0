defmodule ShophawkWeb.YearlySalesChartComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
      <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[86vh]">
        <div class="text-2xl underline pb-4">
            Top 10 Customers & Yearly Sales
        </div>
        <%= if @yearly_sales_data == [] do  %>
            <div class="loader"></div>
        <% else %>
            <div class="grid grid-cols-3 text-4xl">
              <div class="border-b border-stone-400 rounded-lg">Total Sales</div>
              <div class="border-b border-stone-400 rounded-lg">Controls</div>
              <div class="border-b border-stone-400 rounded-lg">Date Range</div>
              <div class=""><%= number_to_currency(@total_sales) %></div>
              <div class="">
                <.button phx-click="add_yearly_sales_customer">+</.button>
                <.button phx-click="subtract_yearly_sales_customer">-</.button>
                <.button phx-click="clear_yearly_sales_customer">Clear Graph</.button>
              </div>
              <div class="">
                <.form for={%{}} as={:dates} phx-submit="reload_top_10_dates">
                  <div class="flex justify-center text-white">
                    <div class="text-xl self-center mx-4">Start:</div>
                    <.input type="date" name="start_date" value={@top_10_startdate} />
                    <div class="text-xl self-center mx-4">End:</div>
                    <.input type="date" name="end_date" value={@top_10_enddate} />
                    <.button class="mx-4 mt-2" type="submit">Reload</.button>
                  </div>
                </.form>
              </div>
            </div>
            <div class="text-md bg-cyan-800 rounded m-2 p-2 h-[78%] 2xl:h-[83%] text-black">
                <div id="YearlySales_Chart" phx-hook="yearly_sales_Chart" data-yearlysales-chart={@yearly_sales_data} data-total-sales={@total_sales}></div>
            </div>
        <% end %>
      </div>
    """
  end
end
