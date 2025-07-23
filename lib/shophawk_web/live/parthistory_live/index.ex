defmodule ShophawkWeb.PartHistoryLive.Index do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJobLive.ShowJobMacroFunctions #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  #alias Shophawk.Shop
  #alias Shophawk.Shop.Department
  #alias Shophawk.Shop.Assignment

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  def render(assigns) do
    ~H"""
      <div class="relative min-h-screen">
        <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user} />

        <div class="absolute left-4 right-4 m-2 rounded-lg bg-cyan-900 grid grid-cols-12" style="top: 5rem; bottom: 1rem;">
          <!-- Search Form -->
          <div class="my-4 ml-4 col-span-1 overflow-y-auto">
            <.form for={%{}} phx-submit="submit_form">
              <div class="">
                <.input name="job" value={@job} placeholder="Job"/>
              </div>
              <div class="my-2">
                <div class="flex">
                  <div class="">
                    <!-- Part Number input with recommended matches -->
                    <div class="relative">
                      <.input
                        name="part_number"
                        value={@part_number}
                        placeholder="Part Number"
                        autocomplete="off"
                        phx-debounce="300"
                        phx-change="suggest_part_number"
                        phx-blur="clear_suggestions"
                        class="w-full p-2 border rounded"
                      />
                      <%= if @part_number_matches != [] do %>
                        <ul class="absolute z-10 w-full bg-white border rounded shadow-lg max-h-60 overflow-auto">
                          <%= if List.first(@part_number_matches) == "none_found" do %>
                            <div class="p-2 bg-stone-300">
                              No matches found
                            </div>

                          <% else %>
                            <%= for part_number <- @part_number_matches do %>
                              <li
                                phx-click="select_part_number"
                                phx-value-name={part_number}
                                class="p-2 hover:bg-gray-100 cursor-pointer"
                              >
                                <%= part_number %>
                              </li>
                            <% end %>
                          <% end %>
                        </ul>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
              <div class="my-2">
                <.input name="description" value={@description} placeholder="Description"/>
              </div>
              <div class="my-2">
                <!-- Customer input with recommended matches -->
                <div class="relative">
                  <.input
                    name="customer"
                    value={@customer}
                    placeholder="Customer"
                    autocomplete="off"
                    phx-change="suggest_customer"
                    phx-debounce="300"
                    phx-blur="clear_suggestions"


                    class="w-full p-2 border rounded"
                  />
                  <%= if @customer_matches != [] do %>
                    <ul class="absolute z-10 w-full bg-white border rounded shadow-lg max-h-60 overflow-auto">
                      <%= if List.first(@customer_matches) == "none_found" do %>
                        <div class="p-2 bg-stone-300">
                          No matches found
                        </div>

                      <% else %>
                        <%= for customer <- @customer_matches do %>
                          <li
                            phx-click="select_customer"
                            phx-value-name={customer}
                            class="p-2 hover:bg-gray-100 cursor-pointer"
                          >
                            <%= customer %>
                          </li>
                        <% end %>
                      <% end %>
                    </ul>
                  <% end %>
                </div>
              </div>
              <div class="my-2">
                <.input name="customer_po" value={@customer_po} placeholder="Customer PO"/>
              </div>
              <div class="my-2">
                <div class="text-white"> Status</div>
                <.input class="" name="status" type="select" options={selected_status(@status)}/>
              </div>
              <div class="my-2">
                <div class="text-white"> Search Start</div>
                <.input name="start-date" value={@start_date} type="date" />
              </div>
              <div class="my-2">
                <div class="text-white"> Search End</div>
                <.input name="end-date" value={@end_date} type="date" />
              </div>

              <.button class="my-1 w-full" type="submit">Search</.button>

              <.info_button phx-click="clear_search" class="my-1 w-full">Clear Search</.info_button>

            </.form>
          </div>

          <div class="m-4 bg-cyan-800 rounded-md overflow-y-auto h-auto w-auto col-span-11">
            <div phx-update="stream" id="jobs" class="mx-2">


              <table id="parthistory" class="text-center w-full px-4 table-fixed text-lg">
                <thead class="text-white text-base sticky top-0 z-10 bg-cyan-800">
                  <tr>
                    <th class="truncate" style="width: 5.0%">Job</th>
                    <th class="truncate" style="width: 3.0%">Make</th>
                    <th class="truncate" style="width: 3.0%">Pick</th>
                    <th class="truncate" style="width: 3.0%">Order</th>
                    <th class="" style="width: 3.0%">spares</th>
                    <th class="truncate" style="width: 5.0%">Profit %</th>
                    <th class="truncate" style="width: 6.0%">Order Date</th>
                    <th class="truncate" style="width: 6.0%">Cost/Part</th>
                    <th class="truncate" style="width: 6.0%">Sell Price</th>
                    <th class="truncate" style="width: 8.0%">Job Total</th>
                    <th class="truncate" style="width: 4.0%">Status</th>
                    <th class="truncate" style="width: 6.0%">est. rem. hrs</th>
                    <th class="truncate" style="width: 8.0%">Customer</th>
                    <th class="truncate" style="width: 10.0%">Current Operation</th>
                    <th class="truncate" style="width: 8.0%">Part Number</th>
                    <th class="truncate" style="">Description</th>
                  </tr>
                </thead>
                <tbody phx-update="stream" id="jobs">
                  <tr :for={{id, row} <- @streams.jobs}
                      id={id}
                      phx-click={JS.push("show_job", value: %{job: row.job})}
                      class={[
                        "hover:cursor-pointer border-b-2 border-stone-700",
                        row_color(row.job_status, row.job_info.pick_quantity, row.job_info.make_quantity)
                      ]}
                  >
                    <td class="truncate" ><%= row.job %></td>
                    <td class="truncate" ><%= row.job_info.make_quantity%></td>
                    <td class="truncate" ><%= row.job_info.pick_quantity%></td>
                    <td class="truncate" ><%= row.job_info.order_quantity%></td>
                    <td class="truncate" ><%= row.job_info.spares_made%></td>
                    <td class="truncate" ><%= row.job_info.percent_profit %>%</td>
                    <td class="truncate" ><%= Calendar.strftime(row.job_info.order_date, "%m-%d-%Y")%></td>
                    <td class="truncate" ><%= Number.Currency.number_to_currency(row.job_info.cost_each) %></td>
                    <td class="truncate" ><%= Number.Currency.number_to_currency(row.job_info.unit_price) %></td>
                    <td class="" ><%= Number.Currency.number_to_currency(row.job_info.total_price) %></td>
                    <td class="" ><%= row.job_status %></td>
                    <td class="truncate" ><%= row.job_info.est_rem_hrs%></td>
                    <td class="truncate" ><%= row.job_info.customer%></td>
                    <td class="truncate" ><%= row.job_info.currentop%></td>
                    <td class="truncate" ><%= row.job_info.part_number%></td>
                    <td class="truncate"><%= row.job_info.description %></td>
                  </tr>
                </tbody>
              </table>

            </div>
          </div>


        </div>

        <.showjob_modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.push("close_modal")}>
          <.live_component
            module={ShophawkWeb.ShowJobLive.ShowJob}
            id={@id || :show_job}
            job_ops={@job_ops}
            job_info={@job_info}
            title={@page_title}
            action={@live_action}
            current_user={@current_user}
            expanded={@expanded || []}
          />
        </.showjob_modal>
      </div>
    """
  end

  def mount(_params, _session, socket) do

    {:ok, set_default_assigns(socket)}
  end

  def handle_event("submit_form", params, socket) do
    {:noreply, push_patch(socket, to: ~p"/parthistory?#{params}")}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/parthistory")}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :live_action, nil)}
  end

  def handle_event("suggest_customer", %{"customer" => query}, socket) do
    # Example: Fetch customers matching the query (case-insensitive)
    matches =
      case Shophawk.Jobboss_db.search_customers_by_like_name(query) do
        [] -> ["none_found"]
        matches -> matches
      end
    {:noreply, assign(socket, :customer_matches, matches)}
  end

  def handle_event("select_customer", %{"name" => name}, socket) do
    socket =
      socket
      |> assign(:customer, name)
      |> assign(:customer_matches, []) # Clear suggestions after selection
    {:noreply, socket}
  end


  def handle_event("suggest_part_number", %{"part_number" => query}, socket) do
    # Example: Fetch customers matching the query (case-insensitive)
    matches =
      case Shophawk.Jobboss_db.search_part_number_by_like_name(query) do
        [] -> ["none_found"]
        matches -> matches
      end
    {:noreply, assign(socket, :part_number_matches, matches)}
  end

  def handle_event("select_part_number", %{"name" => part_number}, socket) do
    socket =
      socket
      |> assign(:part_number, part_number)
      |> assign(:part_number_matches, []) # Clear suggestions after selection
    {:noreply, socket}
  end

  def handle_event("clear_suggestions", _params, socket) do
    self = self()
    Task.async(fn ->
      Process.sleep(150)
      send(self, {:close_reccomendations, nil})
    end)

    {:noreply, socket}
  end

  def handle_params(params, _uri, socket) do
    if map_size(params) > 0 do
      params = #sets default values if calling part history search from another page
        params
        |> Map.put_new("customer", "")
        |> Map.put_new("customer_po", "")
        |> Map.put_new("description", "")
        |> Map.put_new("job", "")
        |> Map.put_new("part_number", "")
        |> Map.put_new("part_number_matches", "")
        |> Map.put_new("status", "")
        |> Map.put_new("start-date", to_string(Date.add(Date.utc_today(), -3650)))
        |> Map.put_new("end-date", to_string(Date.utc_today()))

      job_maps = Shophawk.Jobboss_db.jobs_search(params)
      case job_maps do
        [] ->
          Process.send_after(self(), :clear_flash, 1000)
          socket = put_flash(socket, :error, "No Data Found")
          {:noreply, socket |> stream(:jobs, [], reset: true)}

        job_maps ->
          self = self()
          batch_size = 5
          # Group job numbers into batches
          job_numbers = Enum.sort_by(job_maps, &(&1.order_date), {:desc, Date}) |> Enum.map(&(&1).job)
          batches = Enum.chunk_every(job_numbers, batch_size)

          # Start async task to process batches
          Task.async(fn ->
            batches
            |> Enum.map(fn batch ->
              # Process each batch and maintain job order within batch
              batch_results = showjob(batch)

              # Immediately send job data for this batch
              batch_results
              |> Enum.each(fn
                {:error} -> :skip
                job_data -> send(self, {:loaded_job, job_data})
              end)
            end)
          end)

          socket =
            socket
            |> assign(:customer, params["customer"])
            |> assign(:customer_po, params["customer_po"])
            |> assign(:description, params["description"])
            |> assign(:job, params["job"])
            |> assign(:part_number, params["part_number"])
            |> assign(:status, params["status"])
            |> assign(:start_date, to_string(Date.add(Date.utc_today(), -3650)))
            |> assign(:end_date, to_string(Date.utc_today()))
            |> assign(:customer_matches, [])
            |> assign(:part_number_matches, [])

          {:noreply, socket |> stream(:jobs, [], reset: true)}
      end
    else
      socket = set_default_assigns(socket)
      {:noreply, socket |> stream(:jobs, [], reset: true)}
    end
  end

  def handle_info({:loaded_job, job_data}, socket) do
    case job_data do
      {:error} ->
        Process.send_after(self(), :clear_flash, 1000)
        {:noreply, socket |> put_flash(:error, "No Data Found")}
      _ -> {:noreply, stream_insert(socket, :jobs, job_data, at: -1)}
    end
  end

  def handle_info({:close_reccomendations, nil}, socket) do
    {:noreply, socket |> assign(:customer_matches, []) |> assign(:part_number_matches, [])}
  end

  def handle_info({_ref, _result}, state) do
    {:noreply, state}
  end

  # Required to prevent Task.async/1 from crashing on exit
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket) do
    {:noreply, socket}
  end

  def set_default_assigns(socket) do
    socket
    |> assign(:customer, nil)
    |> assign(:customer_matches, [])
    |> assign(:customer_po, "")
    |> assign(:description, "")
    |> assign(:job, "")
    |> assign(:part_number, "")
    |> assign(:part_number_matches, [])
    |> assign(:status, "")
    |> assign(:start_date, to_string(Date.add(Date.utc_today(), -3650)))
    |> assign(:end_date, to_string(Date.utc_today()))
    |> assign(:page_title, "Part History")
    |> stream(:jobs, [])
  end

  def row_color(status, pick_qty, make_qty) do
    cond do
      make_qty == 0 and pick_qty > 0 -> "hover:bg-white bg-sky-100"
      status == "Active" -> " hover:bg-emerald-200 bg-emerald-300"
      true -> "hover:bg-cyan-400 bg-cyan-500"
    end
  end

  def selected_status(selected) do
    options = ["Active", "Complete", "Closed", "Hold", "Pending", "Template", "Canceled"]
    case selected in options do
      true -> [selected] ++ [""] ++ List.delete(options, selected)
      false -> [""] ++ options
    end
  end

end
