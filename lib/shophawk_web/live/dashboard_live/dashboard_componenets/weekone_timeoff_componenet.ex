defmodule ShophawkWeb.WeekoneTimeoffComponent do
  use ShophawkWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[43vh]">
        <div class="text-2xl">
        <%= if not Enum.empty?(@weekly_dates) do  %>
          Time Off This Week <%= Calendar.strftime(@weekly_dates.monday, "%m-%d") %> to <%= Calendar.strftime(@weekly_dates.friday, "%m-%d") %>
        <% else %>
          Time Off This Week
        <% end %>
        </div>
        <%= if Enum.empty?(@weekly_dates) do  %>
            <div class="loader"></div>
        <% else %>
        <div class="text-xl bg-cyan-800 rounded m-2 p-2 h-[87%] overflow-y-auto sm:text-lg md:text-xl lg:text-2xl">
          <div class="grid grid-cols-5 text-center">
            <%= for {key, values} <- @week1_timeoff do %>
              <div>
                <h2 class="pb-1 font-bold" style="font-size: 1vw"><%= timeoff_header_rename(key) %></h2>
                <ul class="border-stone-500 border">
                  <%= for value <- values do %>
                    <li class="border border-y border-stone-500" style="font-size: 1vw"><%= value %></li>
                  <% end %>
                </ul>
              </div>
            <% end %>
          </div>
        </div>
        <% end %>
    </div>
    """
  end

  def timeoff_header_rename(key) do
    case key do
      :m -> "Monday"
      :t -> "Tuesday"
      :w -> "Wednesday"
      :thur -> "Thursday"
      :f -> "Friday"
      :nm -> "Monday"
      :nt -> "Tuesday"
      :nw -> "Wednesday"
      :nthur -> "Thursday"
      :nf -> "Friday"
      _ -> ""
    end
  end

end
