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
                  navigate={~p"/parthistory?#{[part: assigns.job_info.part_number]}"}
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
              <%= for mat <- assigns.job_info.material do %>
                <div class="truncate">
                <%= case mat.size do %>
                <% "" -> %> <%= mat.material_name %>
                <% _ -> %>
                <.link
                    navigate={~p"/stockedmaterials?#{[material: mat.material, size: mat.size]}"}
                    class="text-blue-900 font-bold underline"
                  >
                  <%= mat.material_name %>
                </.link>
                <% end %>
                </div>
              <% end %>
            </div>
            <div class="text-lg">
              <.link
                  navigate={~p"/parthistory?#{[customer_po: assigns.job_info.customer_po]}"}
                  class="text-blue-900 font-bold underline mx-4"
                >
                <%= (assigns.job_info.customer_po || "") <> ", line: " <> (assigns.job_info.customer_po_line || "") %>
              </.link>
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
      assigns.job_info.material
      |> String.split(" | ")
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn mat ->
        [size_str, material_name] =
          case String.split(mat, "X") do
            [size_str, material_name] -> [size_str, material_name]
            [size1, size2, material_name] -> [(size1 <> "X" <> size2), material_name]
            _ -> ["", ""]
          end
          |> Enum.map(&String.trim/1)


          found_material = Enum.find(material_list, fn mat -> mat.material == material_name end)
          [size_str, material_name] =
            case found_material do
              nil -> ["", %{material: ""}]
              _ -> [size_str, Shophawk.MaterialCache.merge_materials([%{material: material_name}]) |> List.first()]
            end


          %{material_name: mat, material: material_name.material, size: size_str}
      end)
      #ending list: [%{size: "3", material: "3X4140HT", material_name: "4140HT"}]

      updated_job_info = Map.put(assigns.job_info, :material, job_material_list)


    {:ok,
    socket
    |> assign(job: assigns.id)
    |> assign(job_ops: assigns.job_ops)
    |> assign(job_info: updated_job_info)
    |> assign(current_user: current_user)
    }
  end

  def merge_part_number_and_rev(part, rev) do
    case rev do
      "" -> part
      _ -> part <> ", Rev:" <> rev
    end
  end

end
