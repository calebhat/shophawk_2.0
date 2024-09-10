defmodule ShophawkWeb.InvoicesComponent do
  use ShophawkWeb, :live_component
  import Number.Currency

  #Needed Varables
  #open_invoices
  #selected_range
  #open_invoice_values
  def render(assigns) do
    ~H"""
        <div class={["text-center justify-center rounded p-4 bg-cyan-900 m-2", @height.border]}>

            <div class="text-2xl justify-items-center">
                <div class="underline">Invoices: <%= if Enum.empty?(@open_invoices), do: "loading...", else: Enum.count(@open_invoices) %></div>
            </div>

            <%= if Enum.empty?(@open_invoices) == false do  %>
            <div class="grid grid-cols-6">
                <div class={["border-b border-stone-400  rounded-lg cursor-pointer", (if @selected_range == "0-30", do: "bg-cyan-700", else: "hover:bg-cyan-700")]} phx-click="load_invoice_late_range" phx-value-range="0-30">0-30</div>
                <div class={["border-b border-stone-400 rounded-lg cursor-pointer", (if @selected_range == "31-60", do: "bg-cyan-700", else: "hover:bg-cyan-700")]} phx-click="load_invoice_late_range" phx-value-range="31-60">31-60</div>
                <div class={["border-b border-stone-400 rounded-lg cursor-pointer", (if @selected_range == "61-90", do: "bg-cyan-700", else: "hover:bg-cyan-700")]} phx-click="load_invoice_late_range" phx-value-range="61-90">61-90</div>
                <div class={["border-b border-stone-400 rounded-lg cursor-pointer", (if @selected_range == "90+", do: "bg-cyan-700", else: "hover:bg-cyan-700")]} phx-click="load_invoice_late_range" phx-value-range="90+">90+</div>
                <div class={["border-b border-stone-400 rounded-lg cursor-pointer", (if @selected_range == "late", do: "bg-cyan-700", else: "hover:bg-cyan-700")]} phx-click="load_invoice_late_range" phx-value-range="late">Late</div>
                <div class={["border-b border-stone-400 rounded-lg cursor-pointer", (if @selected_range == "all", do: "bg-cyan-700", else: "hover:bg-cyan-700")]} phx-click="load_invoice_late_range" phx-value-range="all">All</div>
                <div class=""><%= number_to_currency(@open_invoice_values.zero_to_thirty) %></div>
                <div class=""><%= number_to_currency(@open_invoice_values.thirty_to_sixty) %></div>
                <div class=""><%= number_to_currency(@open_invoice_values.sixty_to_ninety) %></div>
                <div class=""><%= number_to_currency(@open_invoice_values.ninety_plus) %></div>
                <div class=""><%= number_to_currency(@open_invoice_values.late) %></div>
                <div class=""><%= number_to_currency(@open_invoice_values.all) %></div>
            </div>
            <% end %>
            <%= if Enum.empty?(@open_invoices) do  %>
                <div class="loader"></div>
            <% else %>
                <div class={["text-md bg-cyan-800 rounded m-2 p-2", @height.frame]}>
                    <div class="flex justify-center">
                        <div class="w-full">
                            <table class="w-full table-fixed">
                                <thead class="bg-cyan-800">
                                <tr class="border-b border-stone-400 text-center text-xs 2xl:text-sm">
                                    <th>Document</th>
                                    <th class="w-24">Customer</th>
                                    <th class="w-20 2xl:w-24">Invoice Date</th>
                                    <th class="w-20 2xl:w-24">Due Date</th>
                                    <th class="w-10">Terms</th>
                                    <th class="w-12 text-sm">Days Open</th>
                                    <th>0-30</th>
                                    <th>31-60</th>
                                    <th>61-90</th>
                                    <th>90+</th>
                                </tr>
                                </thead>
                            </table>
                            <div class={["overflow-y-auto text-xs 2xl:text-base", @height.content]}> <!-- Adjust height as needed -->
                                <table class="w-full table-fixed">
                                    <tbody id="checkbook">
                                        <tr
                                        :for={inv <- @open_invoices}
                                        id={"checkbook_entry_#{inv.id}"}
                                        class="border-b border-stone-500 hover:bg-cyan-700"
                                        >
                                        <td class="border-x border-stone-500"><%= inv.document %></td>
                                        <td class="w-24 border-r border-stone-500 pl-1 overflow-hidden truncate whitespace-nowrap"><%= inv.customer %></td>
                                        <td class="w-20 2xl:w-24 border-r border-stone-500"><%= inv.document_date %></td>
                                        <td class="w-20 2xl:w-24 border-r border-stone-500"><%= inv.due_date %></td>
                                        <td class="w-10 border-r border-stone-500"><%= inv.terms %></td>
                                        <td class="w-12 border-r border-stone-500"><%= inv.days_open %></td>
                                        <td class={[change_bg_color_if_late(inv.late, inv.column, 1), "border-r border-stone-500 overflow-hidden"]}><%= if inv.days_open <= 30, do: number_to_currency(inv.open_invoice_amt) %></td>
                                        <td class={[change_bg_color_if_late(inv.late, inv.column, 2), "border-r border-stone-500 overflow-hidden"]}><%= if inv.days_open > 30 and inv.days_open <= 60, do: number_to_currency(inv.open_invoice_amt) %></td>
                                        <td class={[change_bg_color_if_late(inv.late, inv.column, 3), "border-r border-stone-500 overflow-hidden"]}><%= if inv.days_open > 60 and inv.days_open <= 90, do: number_to_currency(inv.open_invoice_amt) %></td>
                                        <td class={[change_bg_color_if_late(inv.late, inv.column, 4), "border-r border-stone-500 overflow-hidden"]}><%= if inv.days_open > 90, do: number_to_currency(inv.open_invoice_amt) %></td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            <% end %>
        </div>
    """
  end

  def change_bg_color_if_late(is_late, column, actual_column) do
    if is_late == true and column == actual_column do
      "bg-pink-900 text-stone-100"
    else
      ""
    end
  end

end
