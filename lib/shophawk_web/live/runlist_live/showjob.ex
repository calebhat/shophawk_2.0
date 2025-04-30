defmodule ShophawkWeb.RunlistLive.ShowJob do
  use ShophawkWeb, :live_component

  def render(assigns) do
    ~H"""
      <div>
        <div class="text-center text-black p-6" >
          <div class="grid grid-cols-3" >
            <div class="text-base"><%= assigns.job_info.job_manager %></div>
            <div class="text-2xl underline"><%= assigns.job %> </div>
            <div><.info_button phx-click="attachments">Attachments</.info_button> </div>
          </div>
        </div>
        <div class="text-lg text-center border-b-4 border-zinc-400 p-4">
          <div class="grid grid-cols-4 grid-rows-3">
            <div class="underline text-base">Part</div>
            <div class="underline text-base">Make</div>
            <div class="underline text-base">Ordered</div>
            <div class="underline text-base">Customer </div>
            <div class="text-lg row-span-2"><%= assigns.job_info.part_number %> </div>
            <div class="text-lg row-span-2"><%= assigns.job_info.make_quantity %> </div>
            <div class="text-lg row-span-2"><%= assigns.job_info.order_quantity %> </div>
            <div class="text-lg row-span-2"><%= assigns.job_info.customer %> </div>
          </div>
          <div class="grid grid-cols-4 grid-rows-2">
            <div class="underline text-base">Description</div>
            <div class="underline text-base">material</div>
            <div class="underline text-base">Customer PO </div>
            <div class="underline text-base">Dots</div>
            <div class="text-lg"><%= assigns.job_info.description %> </div>
            <div class="text-lg"><%= assigns.job_info.material %> </div>
            <div class="text-lg"><%= (assigns.job_info.customer_po || "") <> ", line: " <> (assigns.job_info.customer_po_line || "") %> </div>
            <div class="flex justify-center"><img src={ShophawkWeb.HotjobsComponent.display_dots(assigns.job_info.dots)} /></div>

          </div>
        </div>

        <div class="border-b-4 border-zinc-400 pb-4 pt-4">
          <div class="flex justify-center text-center text-xl underline">Deliveries</div>
          <div class="flex justify-center text-center">
            <table class="">
              <thead>
                <tr>
                  <td class="w-32">Qty</td>
                  <td class="w-32">Promised Date</td>
                  <td class="w-32">Shipped Date</td>
                </tr>
              </thead>
              <tbody>
                <%= for d <- @job_info.deliveries do %>
                  <tr>
                    <td class=""><%= d.promised_quantity %></td>
                    <td class=""><%= d.promised_date %></td>
                    <td class=""><%= d.shipped_date %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>

        <!-- operations table -->
        <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
          <table class="w-[40rem] mt-4 sm:w-full">
            <thead class="text-lg leading-6 text-black text-center">
              <tr>
                <th class="p-0 pr-6 pb-4 font-normal">Operation</th>
                <th class="p-0 pr-6 pb-4 font-normal">Start Date</th>
                <th class="p-0 pr-6 pb-4 font-normal">Total Hours</th>
                <th class="p-0 pr-6 pb-4 font-normal">Status</th>
                <th class="p-0 pr-6 pb-4 font-normal">Operator</th>
                <%= if @current_user do %>
                <th class="p-0 pr-6 pb-4 font-normal">Run Time (hrs)</th>
                <th class="p-0 pr-6 pb-4 font-normal">Est Run Time</th>
                <% end %>
                <th class="relative p-0 pb-4"><span class="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody id={@job} class="relative divide-y divide-zinc-100 border-t border-zinc-400 text-lg leading-6 text-zinc-800">
              <%= for op <- @job_ops do %>
                <tr id={"op-#{op.id}"} class="group hover:bg-zinc-300 text-center">
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl" />
                      <span class="relative font-semibold text-zinc-800">
                        <%= op.wc_vendor %><%= op.operation_service %>
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4" />
                      <span class="relative">
                        <%= op.sched_start %>
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4" />
                      <span class="relative">
                        <%= op.est_total_hrs %>
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4" />
                      <span class="relative">
                        <%= op.status %>
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4" />
                      <span class="relative">
                        <%= op.employee %>
                      </span>
                    </div>
                  </td>
                  <%= if @current_user do %>
                    <td class="relative p-0">
                      <div class="block py-4 pr-6">
                        <span class="absolute -inset-y-px right-0 -left-4" />
                        <span class="relative">
                          <%= op.act_run_labor_hrs %>
                        </span>
                      </div>
                    </td>
                    <td class="relative p-0">
                      <div class="block py-4 pr-6">
                        <span class="absolute -inset-y-px right-0 -left-4" />
                        <span class="relative">
                          <%= op.est_total_hrs %>
                        </span>
                      </div>
                    </td>
                  <% end %>
                  <td>
                    <%= if String.length(op.operation_note_text) != 0 do %>
                      <div class="bg-cyan-800 p-2 w-1 shadow-lg rounded-lg"></div>
                    <% end %>
                  </td>
                  <td class="relative">
                    <div class="hidden group-hover:grid fixed bottom-0 right-0 z-50 mb-4 mr-8 p-2 text-white text-md bg-cyan-800 shadow-lg rounded-lg">
                      <%= if op.full_employee_log != [] and @current_user do %>
                        <%= for row <- op.full_employee_log do %>
                          <%= row %>
                          <br>
                        <% end %>
                      <% end %>
                      <div style="white-space: pre-line;">
                        <%= if op.operation_note_text != nil, do: String.trim(op.operation_note_text) %>
                      </div>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>

      </div>
    """
  end

  def update(assigns, socket) do
    current_user =
      case assigns.current_user do
        nil -> nil
        _ -> assigns.current_user.email
    end

    {:ok,
    socket
    |> assign(job: assigns.id)
    |> assign(job_ops: assigns.job_ops)
    |> assign(job_info: assigns.job_info)
    |> assign(current_user: current_user)
    }
  end

end
