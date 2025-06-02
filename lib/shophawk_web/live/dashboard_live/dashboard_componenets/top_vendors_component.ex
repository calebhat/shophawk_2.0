defmodule ShophawkWeb.TopVendorsComponent do
  use ShophawkWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="text-center justify-center rounded p-4 bg-cyan-900 m-2 h-[50vh]">
        <div class="text-2xl grid grid-cols-3">
            <div></div>
            <div>Top Paid Vendors</div>
            <div>
            <%= if @top_vendors != [] or @empty_vendor_list == true do %>
                <.form for={%{}} as={:dates} phx-submit="reload_top_vendor_dates">
                    <div class="flex justify-center text-white">
                    <div class="text-xl self-center mx-4">Start:</div>
                    <.input type="date" name="start_date" value={@top_vendors_startdate} />
                    <div class="text-xl self-center mx-4">End:</div>
                    <.input type="date" name="end_date" value={@top_vendors_enddate} />
                    <.button class="mx-4 mt-2" type="submit">Reload</.button>
                    </div>
                </.form>
                <% end %>
            </div>

        </div>

        <%= if @top_vendors == [] do %>
            <%= if @empty_vendor_list == false do %>
                <div class="loader"></div>
            <% end %>
        <% else %>
        <div class="text-xl bg-cyan-800 rounded m-2 p-2 h-[87%] overflow-y-auto sm:text-lg md:text-xl lg:text-2xl">
            <div class="flex justify-center p-2 overflow-x-auto">
                <div class="text-[.5vw]]">
                    <div class="grid grid-cols-3">
                        <div class="pr-2">
                        <table class="table-auto">
                            <thead>
                            <tr>
                                <th class="">#</th>
                                <th class="">Vendor</th>
                                <th class="">Total Payments</th>
                            </tr>
                            </thead>
                            <tbody>
                            <%= for {vendor, index} <- Enum.with_index(@top_vendors, 1) do %>
                                <%= if index <= 10 do %>
                                <tr>
                                    <td class="border border-gray-300 px-2"><%= index %></td>
                                    <td class="border border-gray-300 px-2"><%= vendor.vendor %></td>
                                    <td class="border border-gray-300 px-2"><%= Number.Currency.number_to_currency(vendor.payments) %></td>
                                </tr>
                                <% end %>
                            <% end %>
                            </tbody>
                        </table>
                        </div>
                        <div class="pl-6">
                        <table class="table-auto">
                            <thead>
                            <tr>
                                <th>#</th>
                                <th>Vendor</th>
                                <th>Total Payments</th>
                            </tr>
                            </thead>
                            <tbody>
                            <%= for {vendor, index} <- Enum.with_index(@top_vendors, 1) do %>
                                <%= if index > 10 and index <= 20 do %>
                                <tr>
                                    <td class="border border-gray-300 px-2"><%= index %></td>
                                    <td class="border border-gray-300 px-2"><%= vendor.vendor %></td>
                                    <td class="border border-gray-300 px-2"><%= Number.Currency.number_to_currency(vendor.payments) %></td>
                                </tr>
                                <% end %>
                            <% end %>
                            </tbody>
                        </table>
                        </div>
                        <div class="pl-6">
                        <table class="table-auto">
                            <thead>
                            <tr>
                                <th>#</th>
                                <th>Vendor</th>
                                <th>Total Payments</th>
                            </tr>
                            </thead>
                            <tbody>
                            <%= for {vendor, index} <- Enum.with_index(@top_vendors, 1) do %>
                                <%= if index > 20 do %>
                                <tr>
                                    <td class="border border-gray-300 px-2"><%= index %></td>
                                    <td class="border border-gray-300 px-2"><%= vendor.vendor %></td>
                                    <td class="border border-gray-300 px-2"><%= Number.Currency.number_to_currency(vendor.payments) %></td>
                                </tr>
                                <% end %>
                            <% end %>
                            </tbody>
                        </table>
                        </div>
                    </div>

                </div>
            </div>
        </div>
        <% end %>
    </div>
    """
  end

end
