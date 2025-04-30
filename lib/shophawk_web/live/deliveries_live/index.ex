# In the file: lib/your_app_web/live/new_live_view.ex

defmodule ShophawkWeb.DeliveriesLive.Index do
  use ShophawkWeb, :live_view

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Shophawk.PubSub, "delivery_update")
      deliveries = load_active_deliveries()

      socket = if deliveries == [], do: assign(socket, :data_loaded?, false), else: assign(socket, :data_loaded?, true)
      {:ok, stream(socket, :deliveries, deliveries, reset: true)}

    else
      socket = assign(socket, :data_loaded?, true)
      {:ok, stream(socket, :deliveries, [], reset: true)}
    end

  end

  def load_active_deliveries() do
    active_routing_ops =
      case :ets.lookup(:runlist, :active_jobs) do
        [{:active_jobs, runlists}] -> Enum.sort_by(runlists, fn r -> r.job_operation end, :desc)
        [] -> []
      end

    service_operations =
      Enum.filter(active_routing_ops, fn j -> j.inside_oper == false and j.status == "O" end)
      |> Enum.map(fn j ->
        if j.status != "C" do
          j
          |> Map.take([:job, :sched_start, :make_quantity, :wc_vendor, :customer])
          |> Map.put(:promised_date, j.sched_start)
          |> Map.put(:shipped_date, nil)
          |> Map.put(:promised_quantity, j.make_quantity)
          |> Map.put(:shipped_quantity, 0)
          |> Map.put(:delivery, nil)
          |> Map.put(:comment, nil)
          |> Map.drop([:sched_start, :make_quantity])
        end
      end)
      |> Enum.reject(fn s -> s == nil end)


    unique_ops =
      #Enum.reject(active_routing_ops, fn r -> r.customer == "EDG GEAR" end)
      Enum.sort_by(active_routing_ops, fn r -> r.sequence end, :desc)
      |> Enum.uniq_by(fn r -> r.job end)
    job_numbers = Enum.map(unique_ops, fn r -> r.job end)
    jobs_with_current_location = Enum.map(unique_ops, fn j -> %{job: j.job, currentop: j.currentop, customer: j.customer} end)
    deliveries = Shophawk.Jobboss_db.load_deliveries(job_numbers)

    deliveries_and_services = deliveries ++ service_operations


    deliveries_with_id =
      Enum.with_index(deliveries_and_services)
      |> Enum.map(fn {map, index} -> Map.put(map, :id, index) end)
      #|> Enum.sort_by(&(&1.promised_date), {:asc, Date})

    deliveries =
      Enum.map(deliveries_with_id, fn d ->
        job = Enum.find(jobs_with_current_location, fn j -> j.job == d.job end)
        Map.put(d, :currentop, job.currentop)
        |> Map.put(:customer, job.customer)
        |> Map.put(:packaged, false)
        |> Map.put(:user_comment, "")
      end)
      |> Enum.reject(fn d -> d.comment == "PUT IN INVENTORY WHEN DONE" and d.currentop == "RED LINE" end)
      |> Enum.reject(fn r -> r.customer == "EDG GEAR" end)

    deliveries =
      deliveries
      |> Enum.group_by(& &1.promised_date)
      |> Enum.map(fn {date, deliveries} ->
        grouped_by_vendor = Enum.group_by(deliveries, fn g -> g.wc_vendor in ["", nil] end)
        vendors =
          Enum.filter(grouped_by_vendor, fn {bool, _list} -> bool == false end)
          |> Enum.flat_map(fn {_bool, list} -> list end)
          |> Enum.sort_by(fn list -> list.wc_vendor end)
        deliveries =
          Enum.filter(grouped_by_vendor, fn {bool, _list} -> bool == true end)
          |> Enum.flat_map(fn {_bool, list} -> list end)
          |> Enum.sort_by(fn list -> list.customer end)
        sorted_deliveries = deliveries ++ vendors
        {date, sorted_deliveries}
      end)
      |> Enum.reject(fn {date, _} -> date == nil end)
      |> Enum.sort_by(fn {date, _} -> date end, {:asc, Date})
      |> Enum.flat_map(fn {_date, deliveries} -> deliveries end)

    all_shophawk_deliveries =
      Shophawk.Shop.get_deliveries()
      |> Enum.map(fn d -> Map.put(d, :promised_date, NaiveDateTime.to_date(d.promised_date)) end)
    used_delivery_values = Enum.map(all_shophawk_deliveries, fn d -> d.delivery end)

    {deliveries, _} = #add a random delivery value for searching in shophawk db
      Enum.reduce(deliveries, {[], used_delivery_values}, fn s, {acc, used_values} ->
        case Enum.find(all_shophawk_deliveries, fn d -> d.job == s.job and d.promised_date == s.promised_date end) do
          nil ->
            unique_value = if s.delivery != nil, do: s.delivery, else: generate_unique_value(used_values)
            Map.put(s, :delivery, unique_value)
            |> Map.put(:packaged, false)
            |> Map.put(:user_comment, nil)
            {acc ++ [Map.put(s, :delivery, unique_value)], [unique_value | used_values]}
          found ->
            updated_map =
              Map.put(s, :packaged, found.packaged)
              |> Map.put(:user_comment, found.user_comment)
              |> Map.put(:delivery, found.delivery)
            {acc ++ [updated_map], used_values}
        end
      end)

    deliveries =
      deliveries
      |> add_date_rows()
      |> add_vendor_rows()
    :ets.insert(:delivery_list, {:data, deliveries})
    Phoenix.PubSub.broadcast(Shophawk.PubSub, "delivery_update", {:delivery_update, deliveries})
    deliveries
  end

  def generate_unique_value(existing_values) do
    new_value = Ecto.UUID.generate()
    if new_value in existing_values do
      generate_unique_value(existing_values)
    else
      new_value
    end
  end

  def merge_with_shophawk_db(deliveries) do
    saved_delivery_data = Shophawk.Shop.get_deliveries()
    Enum.map(deliveries, fn d ->
      case Enum.find(saved_delivery_data, fn s -> d.delivery == s.delivery end) do
        nil -> d
        found ->
          Map.put(d, :packaged, found.packaged)
          |> Map.put(:user_comment, found.user_comment)
      end
    end)
  end

  def add_date_rows(deliveries) do
    Enum.reduce(deliveries, {[], nil}, fn delivery, {acc, last_date} ->
      current_date = delivery.promised_date
      new_acc =
        if current_date != last_date do
          acc ++ [Map.put(delivery, :type, :date_separator) |> Map.put(:wc_vendor, nil), Map.put(delivery, :type, :normal)]
        else
          acc ++ [Map.put(delivery, :type, :normal)]
        end
      {new_acc, current_date}
    end)
    |> elem(0)
  end

  def add_vendor_rows(deliveries) do
    Enum.reduce(deliveries, {[], false}, fn delivery, {acc, last_is_vendor?} ->
      case delivery.wc_vendor == nil and delivery.type in [:normal, :date_separator] do
        true -> {acc ++ [delivery], false}
        false ->
          case last_is_vendor? do
            true -> {acc ++ [delivery], true}
            false -> {acc ++ [Map.put(delivery, :type, :vendor)] ++ [delivery], true}
          end
      end
    end)
    |> elem(0)
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-center">
      <%= if @data_loaded? == false do %>
        <div class="bg-cyan-800 pt-4 rounded-t-lg fade-in">
          <div class="pt-2 pb-2 px-2 text-center text-3xl border-b-2 border-black" >
            <div class="grid grid-cols-1 gap-3" >
              <div class="bg-stone-200 p-1 rounded-md border-2 border-black">Shophawk is Restarting. Please Refresh the page in 1 minute </div>
            </div>
          </div>
        </div>
      <% else %>
        <div class="w-10/12 bg-cyan-900 px-10 rounded-lg flex">
          <table id="stockedmaterials" class="text-center w-full">
            <thead class="text-white text-base">
              <tr>
                <th class="p-2">Job</th>
                <th>Promised Date</th>
                <th>Qty</th>
                <th>Comment</th>
                <th>Current Operation</th>
                <th>Packaged?</th>
                <th>User Comment</th>
              </tr>
            </thead>
            <tbody phx-update="stream" id="deliveries">
              <tr :for={{id, row} <- @streams.deliveries}
                  id={id}
                  phx-click={if row.type == :normal, do: JS.push("show_job", value: %{job: row.job}), else: nil}
                  class={[compact_row_color(row), "text-lg", underline(row)]}
              >
                <td>
                  <%= case row.type do %>
                    <% :normal -> %> <%= row.job %>
                    <% :vendor -> %>
                    <% :date_separator -> %> <%= Calendar.strftime(row.promised_date, "%A") %>
                  <% end %>
                </td>
                <td><%= if row.type == :date_separator, do: row.promised_date %><%= if row.type == :normal, do: row.customer %></td>
                <td><%= if row.type == :normal, do: row.promised_quantity %></td>
                <td>
                  <%= cond do %>
                    <% row.type == :normal && row.wc_vendor != nil -> %> <%= row.wc_vendor %>
                    <% row.type == :normal -> %> <%= row.comment %>
                    <% row.type == :vendor -> %> <%= "Vendor Shipments" %>
                    <% true -> %>
                  <% end %>
                </td>
                <td><%= if row.type == :normal, do: fill_in_current_op_if_nil(row.currentop) %></td>
                <td>
                  <%= if row.type == :normal do %>
                    <input
                      class="h-6 w-6 rounded text-gray-800 focus:ring-0"
                      type="checkbox"
                      phx-click="toggle_checkbox"
                      phx-value-delivery={row.delivery}
                      checked={row.packaged}
                    />
                  <% end %>
                </td>
                <td>
                  <%= if row.type == :normal do %>
                    <input
                      phx-click="prevent_row_click"
                      type="text"
                      phx-change="save_comment"
                      phx-hook="StandAloneInputboxChange"
                      id={"#{row.delivery}"}
                      phx-value-user_comment={row.user_comment}
                      value={row.user_comment}
                      class="text-black block w-full rounded-lg text-zinc-900 focus:ring-0 text-lg"
                    />
                  <% end %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      <% end %>

      <.modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.patch(~p"/deliveries")}>
        <.live_component
            module={ShophawkWeb.RunlistLive.ShowJob}
            id={@id || :show_job}
            job_ops={@job_ops}
            job_info={@job_info}
            title={@page_title}
            action={@live_action}
            current_user={@current_user}
        />
      </.modal>

      <.modal :if={@live_action in [:job_attachments]} id="job-attachments-modal" show on_cancel={JS.patch(~p"/deliveries")}>
        <div class="w-[1600px]">
        <.live_component
          module={ShophawkWeb.RunlistLive.JobAttachments}
          id={@id || :job_attachments}
          attachments={@attachments}
          title={@page_title}
          action={@live_action}
        />
        </div>
      </.modal>

    </div>
    """
  end

  @impl true
  def handle_info({:delivery_update, deliveries}, socket) do
    {:noreply, stream(socket, :deliveries, deliveries, reset: true)}
  end

  def fill_in_current_op_if_nil(current) do
    case current do
      nil -> "✅"
      "" -> "✅"
      "A-SHIP" -> "✅"
      _ -> current
    end
  end

  def compact_row_color(map) do

    case Map.has_key?(map, :packaged) do
      true ->
        cond do
          map.type == :date_separator -> "bg-stone-300 text-stone-800 hover:cursor-default"
          map.type == :vendor -> "bg-stone-400 text-stone-800 hover:cursor-default"
          map.packaged == true -> "hover:bg-stone-800 bg-cyan-950 hover:cursor-pointer text-white"
          true -> compact_row_color_on_time(map)
        end
      false -> "hover:bg-cyan-700 hover:cursor-pointer text-white"
    end
  end

  def compact_row_color_on_time(row) do
      case Date.compare(row.promised_date, Date.utc_today()) do
        :lt -> "hover:bg-rose-100 bg-rose-200 text-stone-950 hover:cursor-pointer"
        :eq -> "hover:bg-sky-100 bg-sky-200 text-stone-950 hover:cursor-pointer"
        :gt -> "hover:bg-cyan-700 hover:cursor-pointer text-white"
      end
  end

  def underline(row) do
    if row.type == :date_separator, do: "border-y border-black"
  end

  @impl true
  #@spec handle_event(<<_::64, _::_*8>>, any(), any()) :: {:noreply, any()}
  def handle_event("save_comment", %{"input" => comment, "id" => delivery}, socket) do
    updated_delivery = update_user_inputs(delivery, comment)
    {:noreply, stream_insert(socket, :deliveries, updated_delivery)}
    #{:noreply, assign(socket, :delivery, updated_delivery)}
  end

  def handle_event("toggle_checkbox", %{"delivery" => delivery}, socket) do
    updated_delivery = update_user_inputs(delivery)
    {:noreply, stream_insert(socket, :deliveries, updated_delivery)}
  end

  def handle_event("show_job", %{"job" => job}, socket), do: {:noreply, ShophawkWeb.RunlistLive.Index.showjob(socket, job)}


  def handle_event("attachments", _, socket) do
    job = socket.assigns.id
    attachments = Shophawk.Jobboss_db.export_attachments(job)
    socket =
      socket
      |> assign(id: job)
      |> assign(attachments: attachments)
      |> assign(page_title: "Job #{job} attachments")
      |> assign(:live_action, :job_attachments)

    {:noreply, socket}
  end

  def handle_event("download", %{"file-path" => file_path}, socket) do
    {:noreply, push_event(socket, "trigger_file_download", %{"url" => "/download/#{URI.encode(file_path)}"})}
  end

  def handle_event("download", _params, socket) do
    {:noreply, socket |> assign(:not_found, "File not found")}
  end

  def handle_event("close_job_attachments", _params, socket) do
    {:noreply, assign(socket, live_action: :show_job)}
  end

  def handle_event("prevent_row_click", _, socket) do
    {:noreply, socket}
  end

  def update_user_inputs(delivery, comment \\ nil) do
    [{:data, rows}] = :ets.lookup(:delivery_list, :data)
    active_delivery = Enum.find(rows, fn d -> d.delivery == delivery end)
    {:ok, updated_delivery} =
      case Shophawk.Shop.get_department_by_delivery(active_delivery.delivery) do
        nil -> Shophawk.Shop.create_delivery(%{delivery: active_delivery.delivery, packaged: true, job: active_delivery.job, user_comment: comment, promised_date: NaiveDateTime.new!(active_delivery.promised_date, ~T[00:00:00])})
        found ->
          cond do
            comment == nil -> Shophawk.Shop.update_delivery(found, %{packaged: !found.packaged})
            true -> Shophawk.Shop.update_delivery(found, %{user_comment: comment})
          end

      end

    #found_row = Enum.find(rows, &(&1.delivery) == updated_delivery.delivery)
    updated_delivery =
      active_delivery
      |> Map.put(:packaged, updated_delivery.packaged)
      |> Map.put(:user_comment, updated_delivery.user_comment)
      |> Map.put(:type, :normal)

    updated_deliveries = #updates ets cache
      Enum.map(rows, fn r ->
        if r.delivery == updated_delivery.delivery do
          Map.merge(r, updated_delivery)
        else
          r
        end
      end)
    :ets.insert(:delivery_list, {:data, updated_deliveries})
    updated_delivery
  end

end
