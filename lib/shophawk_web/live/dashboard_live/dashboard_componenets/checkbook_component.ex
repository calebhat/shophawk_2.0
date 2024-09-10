defmodule ShophawkWeb.CheckbookComponent do
    use ShophawkWeb, :live_component
    import Number.Currency

    #Needed Varables
    #current_balance
    #checkbook_entries
    def render(assigns) do
        ~H"""
        <div class={["text-center justify-center rounded p-4 bg-cyan-900 m-2", @height.border]}>
            <div class="text-2xl">
                Checkbook Current Balance: <%= @current_balance %>
            </div>
            <%= if Enum.empty?(@checkbook_entries) do  %>
                <div class="loader"></div>
            <% else %>
                <div class={["text-md bg-cyan-800 rounded m-2 p-2 overflow-y-auto", @height.frame]}>
                    <div class="flex justify-center p-2 ">
                        <table class="w-full">
                            <thead>
                                <tr>
                                    <th class="w-1/4">Reference</th>
                                    <th class="w-1/4">Customer/Supplier</th>
                                    <th class="w-1/4">Date</th>
                                    <th class="w-1/4">Amount</th>
                                </tr>
                            </thead>
                            <tbody id="checkbook">
                                <tr
                                :for={entry <- @checkbook_entries}
                                id="checkbook_entries"
                                class="border-b border-stone-500 hover:bg-cyan-700"
                                >
                                    <td><%= entry.reference %></td>
                                    <td><%= entry.source %></td>
                                    <td><%= entry.transaction_date %></td>
                                    <td><%= entry.amount %></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            <% end %>
        </div>
        """
    end
end
