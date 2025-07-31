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

    <!--
        <div class="flex">
        <.button phx-click="load_quote" class="my-1 w-full">Load Quote</.button>
        </div>
    -->

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

          <!-- Main Window -->
          <div class="col-span-11">
            <div class="flex">
              <div class="w-fixed my-4 ml-4">
                <button
                  type="button"
                  phx-click="show_jobs_history"
                  class={[
                    "hover:bg-stone-200 py-1.5 px-3 w-20 rounded-l-lg",
                    "text-sm font-semibold leading-6 text-black",
                    (if @show_job_history == true, do: "bg-stone-100", else: "bg-stone-400")
                  ]}
                >
                  Jobs
                </button>
                <button
                  type="button"
                  phx-click="show_quotes_history"
                  class={[
                    "hover:bg-stone-200 py-1.5 px-3 w-20 rounded-r-lg",
                    "text-sm font-semibold leading-6 text-black",
                    (if @show_job_history == false, do: "bg-stone-100", else: "bg-stone-400")
                  ]}
                >
                  Quotes
                </button>
              </div>
              <%= if @stock_status != nil do %>
              <div class="w-auto my-4">
                <div class="flex mx-4">
                  <div class="ml-2 pl-2 py-1.5 font-semibold rounded-l-lg bg-stone-200"> On Hand Qty:</div>
                  <div class="mr-2 px-2 py-1.5 font-semibold rounded-r-lg bg-stone-200"><%=@stock_status.on_hand%></div>

                  <div class="ml-2 pl-2 py-1.5 font-semibold rounded-l-lg bg-stone-200">In Production:</div>
                  <div class="mr-2 px-2 py-1.5 font-semibold rounded-r-lg bg-stone-200"><%=@stock_status.in_production%></div>

                  <div class="ml-2 pl-2 py-1.5 font-semibold rounded-l-lg bg-stone-200">Allocated:</div>
                  <div class="mr-2 px-2 py-1.5 font-semibold rounded-r-lg bg-stone-200"><%=@stock_status.allocated%></div>

                  <div class="ml-2 pl-2 py-1.5 font-semibold rounded-l-lg bg-stone-200">Part Number:</div>
                  <div class="mr-2 px-2 py-1.5 font-semibold rounded-r-lg bg-stone-200"><%=@stock_status.part_number%></div>
                </div>
              </div>
              <% end %>
            </div>
            <div class="mx-4 bg-cyan-800 rounded-md w-auto " style="max-height: calc(100vh - 12rem);">

              <!-- Job history -->
              <div id="jobs" class={["mx-2 overflow-y-auto", (if @show_job_history == true, do: "", else: "hidden")]}>
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
                  <tbody phx-update="stream" id="jobs-rows">
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

              <!-- Display Quotes -->
              <div class={["mx-2", (if @show_job_history == true, do: "hidden", else: "")]}>
              <div class="flex mb-4">
                <div id="quotehistory" class="w-2/5 px-4 text-lg text-center rounded-lg">
                  <div class="grid grid-cols-[10%_20%_15%_10%_30%_15%] text-sm text-white sticky top-0 z-10 bg-cyan-800 rounded-lg">
                    <div class="truncate py-2 font-bold">Quote</div>
                    <div class="truncate py-2 font-bold">Customer</div>
                    <div class="truncate py-2 font-bold">Quote Date</div>
                    <div class="truncate py-2 font-bold">Rev</div>
                    <div class="truncate py-2 font-bold">Description</div>
                    <div class="truncate py-2 font-bold">Quoted By</div>
                  </div>
                  <div id="quotes-rows">

                    <%= for row <- @quotes do %>
                      <div
                        id={row.id}
                        phx-click="display_quote_details"
                        phx-value-id={row.id}
                        class={["grid grid-cols-[10%_20%_15%_10%_30%_15%] text-base text-white hover:cursor-pointer hover:bg-stone-600 border-b-2 border-stone-700 rounded-lg",
                        (if row.id == @selected_quote, do: "bg-cyan-600", else: "bg-cyan-700")
                        ]}
                      >
                        <div class="truncate py-2"><%= row.rfq %></div>
                        <div class="truncate py-2"><%= row.customer %></div>
                        <div class="truncate py-2"><%= Calendar.strftime(row.quote_date, "%m-%d-%Y") %></div>
                        <div class="truncate py-2"><%= row.rev %></div>
                        <div class="truncate py-2"><%= row.description %></div>
                        <div class="truncate py-2"><%= row.quoted_by %></div>
                      </div>
                    <% end %>
                  </div>
                </div>

                <div class="w-3/5 px-2 text-center overflow-y-auto" id="quotes-rows-qty" style="height: calc(100vh - 12rem);">
                  <%= for row <- @quotes do %>
                  <%= if row.id == @selected_quote do %>
                      <!-- Qty's -->
                      <div class="bg-cyan-800">
                      <div class="grid grid-cols-[1fr_1fr_1fr_1fr_1fr_1fr] text-sm text-white sticky top-0 z-10 bg-cyan-800 border-b-2 border-stone-700">
                        <div class="truncate py-2 font-bold">Qty</div>
                        <div class="truncate py-2 font-bold">Unit Price</div>
                        <div class="truncate py-2 font-bold">Total Price</div>
                        <div class="truncate py-2 font-bold">Labor Markup</div>
                        <div class="truncate py-2 font-bold">Material Markup</div>
                        <div class="truncate py-2 font-bold">Service Markup</div>
                      </div>
                      <%= for q <- row.quantities do %>
                        <div
                          id={Integer.to_string(q.quote_qty_key) <> "-quantities"}
                          class="grid grid-cols-[1fr_1fr_1fr_1fr_1fr_1fr] text-base text-white hover:bg-stone-600 border-b-2 border-stone-700 bg-cyan-700 rounded-lg"
                        >
                          <div class="truncate py-1"><%= q.quote_qty %></div>
                          <div class="truncate py-1"><%= Number.Currency.number_to_currency(q.quoted_unit_price) %></div>
                          <div class="truncate py-1"><%= Number.Currency.number_to_currency(q.total_price) %></div>
                          <div class="truncate py-1"><%= q.labor_markup_pct %>%</div>
                          <div class="truncate py-1"><%= q.mat_markup_pct %>%</div>
                          <div class="truncate py-1"><%= q.serv_markup_pct %>%</div>
                        </div>
                      <% end %>
                      </div>

                      <!-- material requirements -->
                      <%= if row.requirements != [] do %>
                      <div class="mt-2">
                        <div class="grid grid-cols-[4fr_1fr_1fr_1fr_1fr_1fr_1fr] text-sm text-white sticky bg-cyan-800 top-0 z-10 border-b-2 border-stone-700">
                          <div class="truncate py-2 font-bold">Material</div>
                          <div class="truncate py-2 font-bold">Length</div>
                          <div class="truncate py-2 font-bold">Cutoff</div>
                          <div class="truncate py-2 font-bold">Price</div>
                          <div class="truncate py-2 font-bold">Pick or Buy</div>
                          <div class="truncate py-2 font-bold">Qty/Part</div>
                          <div class="truncate py-2 font-bold">Cost/Part</div>
                        </div>
                        <%= for q <- row.requirements do %>
                          <div
                            id={Integer.to_string(q.quote_req) <> "-requirements"}
                            class="grid grid-cols-[4fr_1fr_1fr_1fr_1fr_1fr_1fr] text-base text-white rounded-lg border-b border-stone-700 bg-cyan-700 hover:bg-stone-600"
                          >
                            <div class="truncate py-.5"><%= q.material %></div>
                            <div class="truncate py-.5"><%= if q.part_length == 0.0, do: "", else: Float.to_string(Float.round(q.part_length, 2)) <> "\"" %></div>
                            <div class="truncate py-.5"><%= if q.cutoff == 0.0, do: "", else: Float.to_string(Float.round(q.cutoff, 2)) <> "\"" %></div>
                            <div class="truncate py-.5"><%= if q.cost_uofm != "lb", do: "", else: Number.Currency.number_to_currency(q.est_unit_cost) <> "/" <> q.cost_uofm %></div>
                            <div class="truncate py-.5"><%= if q.pick_buy_indicator == "P", do: "Pick", else: "Buy" %></div>
                            <div class="py-.5"><%= if q.pick_buy_indicator == "B", do: q.quantity_per, else: "" %></div>
                            <div class="py-.5"><%= calculate_cost_per_part(q) %></div>
                          </div>
                        <% end %>
                      </div>
                      <% end %>

                      <!-- operations -->
                      <%= if row.operations != [] do %>
                      <div class="mt-2">
                        <div class="grid grid-cols-[1fr_1fr_1fr_1fr_5fr] text-sm text-white sticky bg-cyan-800 top-0 z-10 border-b-2 border-stone-700">
                          <div class="truncate py-2 font-bold">Work Center</div>
                          <div class="truncate py-2 font-bold">Setup</div>
                          <div class="truncate py-2 font-bold">Run Rate</div>
                          <div class="truncate py-2 font-bold">Run Labor Rate</div>
                          <div class="truncate py-2 font-bold">Notes</div>
                        </div>
                        <%= for q <- row.operations do %>
                          <div
                            id={Integer.to_string(q.quote_operation) <> "-operations"}
                            class="grid grid-cols-[1fr_1fr_1fr_1fr_5fr] text-base text-white rounded-lg border-b border-stone-700 bg-cyan-700 hover:bg-stone-600"
                          >
                            <div class="truncate py-.5"><%= q.wc_vendor %></div>
                            <div class="truncate py-.5"><%= q.est_setup_hrs %> hrs</div>
                            <div class="truncate py-.5"><%= Float.to_string(q.run) <> " " <> q.run_method %></div>
                            <div class="truncate py-.5"><%= Number.Currency.number_to_currency(q.run_labor_rate) %></div>
                            <div class="py-.5"><%= q.note_text %></div>
                          </div>
                        <% end %>
                      </div>
                      <% end %>

                  <% end %>
                  <% end %>
                </div>


              </div>

              </div>

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

    ####TEST FUNCTION FOR QUOTES IN PART HISTORY####
          #if connected?(socket), do: Shophawk.Jobboss_db_quote.load_quote()
    #######

    {:ok, set_default_assigns(socket)}
  end

  def handle_event("load_quote", _params, socket) do
    #Shophawk.Jobboss_db_quote.load_quote()
    {:noreply, socket}
  end

  def handle_event("show_jobs_history", _params, socket) do
    {:noreply, assign(socket, :show_job_history, true)}
  end
  def handle_event("show_quotes_history", _params, socket) do
    {:noreply, assign(socket, :show_job_history, false)}
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
      case Shophawk.Jobboss_db_parthistory.search_customers_by_like_name(query) do
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
      case Shophawk.Jobboss_db_parthistory.search_part_number_by_like_name(query) do
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

  def handle_event("display_quote_details", %{"id" => id}, socket) do
    {:noreply, socket |> assign(:selected_quote, id)}
  end

  def handle_params(params, _uri, socket) do
    if map_size(params) > 0 do
      params_updated = #sets default values if calling part history search from another page
        params
        |> Map.put_new("customer", "")
        |> Map.put_new("customer_po", "")
        |> Map.put_new("description", "")
        |> Map.put_new("job", "")
        |> Map.put_new("part_number", "")
        |> Map.put_new("part_number_matches", "")
        |> Map.put_new("status", "")
        |> Map.put_new("start-date", to_string(~D[1990-01-01]))
        |> Map.put_new("end-date", to_string(Date.utc_today()))

      jobs_map = Shophawk.Jobboss_db_parthistory.jobs_search(params_updated)

      if jobs_map != [] do
        self = self()
        batch_size = 5
        # Group job numbers into batches
        job_numbers = Enum.sort_by(jobs_map, &(&1.order_date), {:desc, Date}) |> Enum.map(&(&1).job)
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
      end

      #CHANGES QUOTES MAP TO LOAD WITH ASYNC PROCESSES JUST LIKE JOBS AND SAVE TO CACHEX FOR QUICK LOADING
      quotes_map =
        case params_updated["part_number"] != "" do
          true -> Shophawk.Jobboss_db_quote.load_quote(params["part_number"]) |> Enum.sort_by(&(&1.quote_date), {:desc, Date}) |> IO.inspect
          false -> []
        end


      if jobs_map == [] and quotes_map == [] do
        Process.send_after(self(), :clear_flash, 1000)
        socket = put_flash(socket, :error, "No Data Found")
        {:noreply, socket |> stream(:jobs, [], reset: true) |> stream(:quotes, [], reset: true)}
      end

      stock_status =
        case params_updated["part_number"] != "" do
          true -> load_stock_status(params["part_number"])
          false -> nil
        end

      socket =
        socket
        |> assign(:customer, params_updated["customer"])
        |> assign(:customer_po, params_updated["customer_po"])
        |> assign(:description, params_updated["description"])
        |> assign(:job, params_updated["job"])
        |> assign(:part_number, params_updated["part_number"])
        |> assign(:status, params_updated["status"])
        |> assign(:start_date, to_string(~D[1990-01-01]))
        |> assign(:end_date, to_string(Date.utc_today()))
        |> assign(:customer_matches, [])
        |> assign(:part_number_matches, [])
        |> assign(:stock_status, stock_status)
        |> assign(:selected_quote, List.first(quotes_map).id)
        |> assign(:quotes, quotes_map)

      {:noreply, socket |> stream(:jobs, [], reset: true) |> stream(:quotes, quotes_map, reset: true)}
    else
      socket = set_default_assigns(socket)
      {:noreply, socket |> stream(:jobs, [], reset: true) |> stream(:quotes, [], reset: true)}
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

  def handle_info({:loaded_quote, quote_data}, socket) do
    case quote_data do
      {:error} ->
        Process.send_after(self(), :clear_flash, 1000)
        {:noreply, socket |> put_flash(:error, "No Data Found")}
      _ -> {:noreply, stream_insert(socket, :quotes, quote_data, at: -1)}
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
    |> assign(:start_date, to_string(~D[1990-01-01]))
    |> assign(:end_date, to_string(Date.utc_today()))
    |> assign(:page_title, "Part History")
    |> assign(:stock_status, nil)
    |> assign(:show_job_history, false)
    |> assign(:quotes, [])
    |> stream(:jobs, [])
    |> stream(:quotes, [])
  end

  def load_stock_status(part_number) do
    stock_status =
      case Shophawk.Jobboss_db_quote.load_material_stock(part_number) do
        [] -> %{on_hand_qty: 0, material: part_number}
        stock -> stock |> List.first
      end
    runlists =
      Cachex.stream!(:active_jobs, Cachex.Query.build(output: :value))
      |> Enum.to_list
      |> List.flatten
      |> Enum.filter(fn j -> j.job_info.part_number == part_number end)
    allocated =
      Enum.reduce(runlists, 0, fn j, acc ->
        case j.job_info.pick_quantity do
          0 -> acc
          nil -> acc
          _ -> acc + j.job_info.pick_quantity
        end
      end)

    in_production =
      Enum.reduce(runlists, 0, fn j, acc ->
        case j.job_info.make_quantity do
          0 -> acc
          nil -> acc
          _ -> acc + j.job_info.make_quantity
        end
      end)
    %{on_hand: stock_status.on_hand_qty, in_production: in_production, allocated: allocated, part_number: stock_status.material}
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

  def calculate_cost_per_part(q) do
    case q.cost_uofm do
      "lb" -> (((q.part_length + q.cutoff) / 12) * q.cost_unit_conv * q.est_unit_cost) |> Float.round(2) |> Number.Currency.number_to_currency()
      "ea" -> q.est_unit_cost |> Float.round(2) |> Number.Currency.number_to_currency()
      _ -> q.est_unit_cost
    end

  end

end
