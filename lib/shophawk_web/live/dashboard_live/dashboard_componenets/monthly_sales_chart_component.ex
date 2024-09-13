defmodule ShophawkWeb.MonthlySalesChartComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
      <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[86vh]">
        <div class="grid grid-cols-3">
          <div></div>
          <div class="text-4xl underline pb-4 justify-items-center">
              Monthly Sales
          </div>
          <%= if @this_months_sales != 0 do  %>
          <div class="justify-items-end"><.button phx-click="monthly_sales_toggle">Toggle Graph/Table</.button></div>
          <% else %>
          <div></div>
          <% end %>
        </div>
        <%= if @this_months_sales != 0 do  %>
            <div class={["grid grid-cols-3", @header_font_size]}>
                <div class="border-b border-stone-400 rounded-lg">This Years Sales</div>
                <div class="border-b border-stone-400 rounded-lg"><%= if @show_monthly_sales_table == false, do: "This Months Sales", else: "Monthly Average (12 Month)" %></div>
                <div class="border-b border-stone-400 rounded-lg">Projected Yearly Sales</div>
                <div class=""><%= number_to_currency(@this_years_sales) %></div>
                <div class=""><%= if @show_monthly_sales_table == false, do: number_to_currency(@this_months_sales), else: number_to_currency(@monthly_average) %></div>
                <div class=""><%= number_to_currency(@projected_yearly_sales) %></div>
            </div>
        <% end %>
        <%= if @this_months_sales != 0 do  %>
          <%= if @show_monthly_sales_table == false do %>
            <div class={["text-md bg-cyan-800 rounded m-2 p-2 text-black", @height.frame]}>
                <div id="sales_chart" phx-hook="monthly_sales_chart" data-sales-chart={@sales_chart_data}></div>
            </div>
          <% else %>
            <div class={["text-md bg-cyan-800 rounded m-2 p-2 text-white text-2xl", @height.frame]}>

              <div class="flex justify-center p-2 overflow-x-auto">
                  <table class="w-full table-auto">
                      <thead>
                          <tr class="text-sm md:text-base lg:text-lg">
                            <th class="px-2 py-1">Year</th>
                            <th class="px-2 py-1">January</th>
                            <th class="px-2 py-1">February</th>
                            <th class="px-2 py-1">March</th>
                            <th class="px-2 py-1">April</th>
                            <th class="px-2 py-1">May</th>
                            <th class="px-2 py-1">June</th>
                            <th class="px-2 py-1">July</th>
                            <th class="px-2 py-1">August</th>
                            <th class="px-2 py-1">September</th>
                            <th class="px-2 py-1">October</th>
                            <th class="px-2 py-1">November</th>
                            <th class="px-2 py-1">December</th>
                            <th class="px-2 py-1">Total</th>
                          </tr>
                      </thead>
                      <tbody id="sales">
                          <tr :for={s <- @sales_table_data} id="sales_rows" class="hover:bg-cyan-700 text-sm md:text-base lg:text-lg">
                            <td class="px-2"><%= s.year %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.jan) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.feb) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.mar) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.apr) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.may) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.jun) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.jul) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.aug) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.sep) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.oct) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.nov) %></td>
                            <td class="border border-stone-500 p-2"><%= number_to_currency(s.dec) %></td>
                            <td class="border border-stone-500 p-2 bg-cyan-900"><%= number_to_currency(s.total) %></td>
                          </tr>
                      </tbody>
                  </table>
              </div>

            </div>
          <% end %>
        <% else %>
            <div class="loader"></div>
        <% end %>
      </div>
    """
  end
end
