defmodule ShophawkWeb.ShowJobLive.ShowJob do
  use ShophawkWeb, :live_component

  def render(assigns) do
    ~H"""
      <div>
        <div class="text-center text-black p-6" >
          <div class="grid grid-cols-3" >
            <div>
              <!-- <.info_button phx-click="attachments">Attachments</.info_button> -->
            </div>
            <div class="text-2xl underline"><%= assigns.job %> </div>
            <div class="text-base"><%= assigns.job_info.job_manager %></div>
          </div>
        </div>
        <div class="text-lg text-center border-b-4 border-zinc-400 p-4">
          <div class="grid grid-cols-4 grid-rows-3">
            <div class="underline text-base">Part</div>
            <div class="underline text-base">Make</div>
            <div class="underline text-base">Ordered</div>
            <div class="underline text-base">Customer </div>
            <div class="text-lg row-span-2">
              <.link
                  navigate={~p"/parthistory?#{[part_number: assigns.job_info.part_number]}"}
                  class="text-blue-900 font-bold underline mx-4"
                >
                <%= merge_part_number_and_rev(assigns.job_info.part_number, assigns.job_info.rev)  %>
              </.link>
            </div>
            <div class="text-lg row-span-2"><%= assigns.job_info.make_quantity %> </div>
            <div class="text-lg row-span-2"><%= assigns.job_info.order_quantity %> </div>
            <div class="text-lg row-span-2">
              <.link
                  navigate={~p"/parthistory?#{[customer: assigns.job_info.customer]}"}
                  class="text-blue-900 font-bold underline mx-4"
                >
                <%= assigns.job_info.customer %>
              </.link>
             </div>
          </div>
          <div class="grid grid-cols-4">
            <div class="underline text-base">Description</div>
            <div class="underline text-base">Material</div>
            <div class="underline text-base">Customer PO </div>
            <div class="underline text-base">Dots</div>
          </div>
          <div class="grid grid-cols-4">
            <div class="text-lg"><%= assigns.job_info.description %> </div>
            <div class="text-lg">
              <%= for mat <- assigns.job_info.material_reqs do %>
                <div class="truncate">
                <%= case mat.size do %>
                <% "" -> %> <%= mat.material_name %> - <%= mat.est_qty %> pcs
                <% _ -> %>
                <.link
                    navigate={~p"/stockedmaterials?#{[material: mat.material, size: mat.size]}"}
                    class="text-blue-900 font-bold underline"
                  >
                  <%= mat.material_name %>
                </.link> - <%= mat.part_length %>" Part Length
                <% end %>
                </div>
              <% end %>
            </div>
            <div class="text-lg">
            <%= case assigns.job_info.customer_po do %>
                <% "" -> %>
                <% nil -> %>
                <% _ -> %>
                  <%= case assigns.job_info.customer_po_line do %>
                    <% "" -> %>
                      <.link
                        navigate={~p"/parthistory?#{[customer_po: assigns.job_info.customer_po, customer: assigns.job_info.customer]}"}
                        class="text-blue-900 font-bold underline mx-4"
                      >
                        <%= assigns.job_info.customer_po %>
                      </.link>
                    <% _ -> %>
                      <.link
                          navigate={~p"/parthistory?#{[customer_po: assigns.job_info.customer_po, customer: assigns.job_info.customer]}"}
                          class="text-blue-900 font-bold underline"
                        >
                        <%= (assigns.job_info.customer_po || "") %>
                      </.link>, line: <%= assigns.job_info.customer_po_line %>
                  <% end %>
              <% end %>
            </div>
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
        <div class="px-4 sm:overflow-visible sm:px-0">
          <table class="w-[40rem] mt-4 sm:w-full">
            <thead class="text-lg leading-6 text-black text-center">
              <tr>
                <th class="p-0 pr-6 pb-4 font-normal" style="width: 20%">Operation</th>
                <th class="p-0 pr-6 pb-4 font-normal" style="width: 10%">Start Date</th>
                <th class="p-0 pr-6 pb-4 font-normal" style="width: 5%">Status</th>
                <th class="p-0 pr-6 pb-4 font-normal" style="width: 10%">Parts Completed</th>
                <th class="p-0 pr-6 pb-4 font-normal" style="width: 5%">Est Run Time</th>
                <%= if @current_user do %>
                <th class="p-0 pr-6 pb-4 font-normal" style="width: 5%">Act Run Time</th>
                <% end %>
                <th class="p-0 pr-6 pb-4 font-normal" style="">Operator</th>
                <th class="p-0 pr-6 pb-4 font-normal" style="width: 5%">Info</th>
              </tr>
            </thead>
            <tbody id={@job} class="relative divide-y divide-zinc-100 border-t border-zinc-400 text-lg leading-6 text-zinc-800">
              <%= for op <- @job_ops do %>
                <tr id={"#{op.id}"} class="group hover:bg-zinc-300 text-center">
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="relative font-semibold text-zinc-800">
                        <%= op.wc_vendor %><%= op.operation_service %>
                      </span>
                    </div>
                  </td>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="relative">
                        <%= op.sched_start %>
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
                        <%= trunc(op.act_run_qty) %>
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
                  <%= if @current_user do %>
                    <td class="relative p-0">
                      <div class="block py-4 pr-6">
                        <span class="absolute -inset-y-px right-0 -left-4" />
                        <span class="relative">
                          <%= op.act_run_labor_hrs %>
                        </span>
                      </div>
                    </td>
                  <% end %>
                  <td class="relative p-0">
                    <div class="block py-4 pr-6">
                      <span class="absolute -inset-y-px right-0 -left-4" />
                      <span class="relative">
                        <%= op.employee %>
                      </span>
                    </div>
                  </td>
                  <td >
                    <%= if op.full_employee_log != [] and @current_user do %>
                      <%= if String.length(op.operation_note_text) != 0 or op.full_employee_log != [] do %>
                        <div class="flex justify-center hover:cursor-pointer" phx-click="toggle_expand" phx-value-op-id={op.id}><img src={arrow_change(op.id, assigns.expanded)}></div>
                      <% end %>
                    <% else %>
                        <%= if String.length(op.operation_note_text) != 0 do %>
                        <div class="flex justify-center hover:cursor-pointer" phx-click="toggle_expand" phx-value-op-id={op.id}><img src={arrow_change(op.id, assigns.expanded)} /></div>
                        <% end %>
                    <% end %>
                  </td>
                </tr>
                <!-- expandable info row -->
                <%= if op.full_employee_log != [] or op.operation_note_text != "" do %>
                <tr id={"expand-#{op.id}"} class={[toggle_content(op.id, assigns.expanded)]} style="height: auto;">
                  <td colspan="6" class="px-2 pb-2 bg-zinc-300 rounded-bl-xl" style="border-top: 1px solid; vertical-align: top; height: 100%;">
                    <div class="bg-zinc-100 px-2 pb-2 rounded-b-xl flex flex-col min-h-auto">
                      <%= if op.operation_note_text != "" do %>
                        <div class="whitespace-pre-line flex-grow overflow-auto">
                          <%= String.trim(op.operation_note_text) %>
                        </div>
                      <% end %>
                    </div>
                  </td>
                  <td colspan="3" class="px-2 pb-2 bg-zinc-300 rounded-br-xl" style="border-top: 1px solid; vertical-align: top; height: 100%;">
                    <div class="bg-zinc-100 px-2 pb-2 rounded-b-xl flex flex-col min-h-auto">
                      <div class="flex-grow overflow-auto">
                        <%= if op.full_employee_log != [] and @current_user do %>
                          <%= for row <- op.full_employee_log do %>
                            <div class="">
                              <%= String.trim(row) %>
                            </div>
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                  </td>
                </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>
        </div>

        <!-- Display attatchments -->
        <div class="text-center text-black p-6" >
          <div class="text-2xl underline">Attachments </div>
        </div>
        <%= if Map.has_key?(assigns, :not_found) do %>
          <div class="text-red"> File Not Found </div>
        <% end %>
        <%= if @job_info.attachments == [] do %>
          <div class="text-2xl flex justify-center"> No Attachments </div>
        <% end %>

        <%= unless Enum.all?(@job_info.attachments, &(&1.path =~ ~r/\.pdf$/i)) do %>
          <div class=" px-4 sm:overflow-visible sm:px-0">
            <table class="w-[40rem] mt-4 sm:w-full">
              <thead class="text-lg text-left leading-6 text-black text-center">
                <tr>
                  <th class="p-0 pr-6 pb-4 font-normal">Description/Part #</th>
                  <th class="p-0 pr-6 pb-4 font-normal">Server Location</th>
                </tr>
              </thead>
              <tbody
                id={@job}
                class="relative divide-y divide-zinc-100 border-t border-zinc-400 text-lg leading-6 text-zinc-800"
              >
                <%= for attachment <- @job_info.attachments do %>
                  <%= if !String.contains?(attachment.path, "pdf") do %>
                    <tr class="group hover:bg-zinc-400 text-center">
                      <td class={["relative p-0"]}>
                        <div class="block py-4 pr-6">
                          <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-300 sm:rounded-l-xl" />
                          <span class={["relative font-semibold text-zinc-800"]}>
                            <%= attachment.description %>
                          </span>
                        </div>
                      </td>
                      <td class={["relative p-0"]}>
                        <div class="block py-4 pr-6">
                          <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-300 sm:rounded-l-xl" />
                          <span class={["relative"]}>
                            <%= attachment.path %>
                          </span>
                        </div>
                      </td>
                      <td class={["relative p-0"]}>
                        <div class="block py-4 pr-6">
                          <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-300 sm:rounded-l-xl" />
                          <span class={["relative"]}>
                          <.button phx-click="download" phx-value-file-path={attachment.path} class="ml-2">Download</.button>
                          </span>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>

        <div>
          <!-- display PDFs, uses  -->
          <div id="pdf-container" phx-update="ignore">
            <%= for {attachment, index} <- Enum.with_index(@job_info.attachments) do %>
              <%= if String.contains?(String.downcase(attachment.path), ["pdf"]) do %>
                <div style="width: 100%; display: block; margin-bottom: 20px;">
                  <!-- Controls: Fixed or sticky -->
                  <div class="pdf-controls sticky top-0 z-10 bg-white p-2 shadow-md" style="text-align: center;">
                    <button type="button" class="zoom-in rounded-lg p-2 bg-cyan-700 text-white" style="margin-right: 10px;">Zoom In</button>
                    <button type="button" class="zoom-out rounded-lg p-2 bg-cyan-700 text-white" style="margin-right: 10px;">Zoom Out</button>
                    <button type="button" class="rotate rounded-lg p-2 bg-cyan-700 text-white" style="margin-right: 10px;">Rotate</button>
                    <button type="button" class="fit-to-container rounded-lg p-2 bg-cyan-700 text-white" style="margin-right: 10px;">Fit to Container</button>
                    <span class="page-display" style="margin-right: 10px;">Page 1 of ?</span>
                    <button type="button" class="prev-page rounded-lg p-2 bg-cyan-700 text-white" style="margin-right: 10px;">Previous Page</button>
                    <button type="button" class="next-page rounded-lg p-2 bg-cyan-700 text-white" style="margin-right: 10px;">Next Page</button>
                    <a class="download-pdf rounded-lg p-2 bg-cyan-700 text-white" href={"/serve_pdf/" <> attachment.path} download style="margin-right: 10px;">Download PDF</a>
                  </div>
                  <!-- Scrollable canvas container -->
                  <div style="overflow: auto;">
                    <canvas
                      id={"pdf-canvas-#{index}"}
                      data-pdf-path={"/serve_pdf/" <> attachment.path}
                      style="border: 1px solid #ccc;"
                    ></canvas>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>

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

    {:ok, material_list} = Cachex.get(:material_list, :data)

    job_material_list =
      Enum.map(assigns.job_info.material_reqs, fn mat ->

        [size_str, material_name] =
          case String.split(mat.material, "X") do
            [size_str, material_name] -> [size_str, material_name]
            [size1, size2, material_name] -> [(size1 <> "X" <> size2), material_name]
            [size1, size2, size3, material_name] -> [(size1 <> "X" <> size2 <> "X" <> size3), material_name]
            _ -> ["", ""]
          end
          |> Enum.map(&String.trim/1)

        #put found name through material transformation function that merges names from jobboss if needed
        found_material = Enum.find(material_list, fn mat_list -> mat_list.material == material_name end)
        [size_str, material_name] =
          case found_material do
            nil -> ["", %{material: ""}]
            _ -> [size_str, Shophawk.MaterialCache.merge_materials([%{material: material_name}]) |> List.first()]
          end

        %{material_name: mat.material, material: material_name.material, size: size_str, part_length: mat.part_length, est_qty: mat.est_qty}
      end)

    updated_job_info = Map.put(assigns.job_info, :material_reqs, job_material_list)


    {:ok,
    socket
    |> assign(job: assigns.id)
    |> assign(job_ops: assigns.job_ops)
    |> assign(job_info: updated_job_info)
    |> assign(current_user: current_user)
    |> assign(:expanded, assigns.expanded)
    }
  end

  def merge_part_number_and_rev(part, rev) do
    case rev do
      "" -> part
      "-" -> part
      nil -> part
      _ -> part <> ", Rev:" <> rev
    end
  end

  def toggle_content(id, content_toggle_list) do
    case id in content_toggle_list do
      true -> ""
      false -> "hidden"
    end
  end

  def arrow_change(id, content_toggle_list) do
    case id in content_toggle_list do
      true -> ~p"/images/up_arrow.svg"
      false -> ~p"/images/right_arrow.svg"
    end
  end

end
