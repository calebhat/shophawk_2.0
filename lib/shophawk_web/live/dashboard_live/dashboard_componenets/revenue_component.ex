defmodule ShophawkWeb.RevenueComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  def render(assigns) do
    ~H"""
      <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[86vh]">
        <%= if @total_revenue != 0 do  %>
          <div class={["grid grid-cols-3", @header_font_size]}>
            <div class="border-b border-stone-400 rounded-lg text-[1.5vw] truncate">Total Anticipated Revenue</div>
            <div class="border-b border-stone-400 rounded-lg text-[1.5vw] truncate">Six Weeks Revenue</div>
            <div class="border-b border-stone-400 rounded-lg text-[1.5vw] truncate">Active Jobs Right Now</div>
            <div class="text-[1.5vw] truncate"><%= number_to_currency(@total_revenue) %></div>
            <div class="flex justify-center">
              <div class="text-[1.5vw] truncate"><%= number_to_currency(@six_weeks_revenue_amount) %></div>
              <div class="dark-tooltip-container grid grid-cols-1">
                <div class={[text_color(@percentage_diff), "text-[1.5vw] truncate"]}><%= @percentage_diff %></div>
                <div class="tooltip ml-20 text-[1.5vw] truncate">Change from the previous monday</div>
              </div>
            </div>
            <div class="text-[1.5vw] truncate"><%= @active_jobs %></div>
          </div>
        <% end %>
        <%= if @total_revenue != 0 do  %>
            <div class={["text-md bg-cyan-800 rounded m-2 p-2  text-black", @height.frame]}>
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
