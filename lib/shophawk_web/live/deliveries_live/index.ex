# In the file: lib/your_app_web/live/new_live_view.ex

defmodule ShophawkWeb.DeliveriesLive.Index do
  use ShophawkWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    deliveries = load_active_deliveries()



    :ets.insert(:delivery_list, {:data, deliveries})
    {:ok, stream(socket, :deliveries, deliveries, reset: true)}
  end

  def load_active_deliveries() do
    active_routing_ops =
      case :ets.lookup(:runlist, :active_jobs) do
        [{:active_jobs, runlists}] ->
          Enum.reverse(runlists)
        [] -> []
      end

    all_deliveries_delievery = Shophawk.Shop.get_deliveries_delivery()

    service_operations =
      Enum.filter(active_routing_ops, fn j -> j.inside_oper == false end)
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
    {service_operations, _} =
      Enum.reduce(service_operations, {[], all_deliveries_delievery}, fn s, {acc, used_names} ->
        unique_value = generate_unique_value(used_names)
        Map.put(s, :delivery, unique_value)
        {acc ++ [Map.put(s, :delivery, unique_value)], [unique_value | used_names]}
      end)


    unique_ops = Enum.uniq_by(active_routing_ops, fn r -> r.job end)
    job_numbers = Enum.map(unique_ops, fn r -> r.job end)
    jobs_with_current_location = Enum.map(unique_ops, fn j -> %{job: j.job, currentop: j.currentop} end)
    deliveries = Shophawk.Jobboss_db.load_deliveries(job_numbers)

    deliveries_and_services = deliveries ++ service_operations
    sorted_deliveries_and_services =
      Enum.sort_by(deliveries_and_services, fn d ->
        [d.promised_date,
          d.wc_vendor not in ["", nil],
          d.wc_vendor,
          d.comment
        ]
      end)

    deliveries_with_id =
      Enum.with_index(sorted_deliveries_and_services)
      |> Enum.map(fn {map, index} -> Map.put(map, :id, index) end)
      |> Enum.sort_by(&(&1.promised_date), {:asc, Date})

    deliveries =
      Enum.map(deliveries_with_id, fn d ->
        job = Enum.find(jobs_with_current_location, fn j -> j.job == d.job end)
        Map.put(d, :currentop, job.currentop)
        |> Map.put(:packaged, false)
        |> Map.put(:user_comment, "")
      end)
    merge_with_shophawk_db(deliveries)
    |> add_date_rows()
    |> add_vendor_rows()

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
            <td><%= if row.type != :vendor, do: row.promised_date %></td>
            <td><%= if row.type == :normal, do: row.promised_quantity %></td>
            <td>
              <%= cond do %>
                <% row.type == :normal && row.wc_vendor != nil -> %> <%= row.wc_vendor %>
                <% row.type == :normal -> %> <%= row.comment %>
                <% row.type == :vendor -> %> <%= "Vendor Shipments" %>
                <% true -> %>
              <% end %>
            </td>
            <td><%= if row.type == :normal, do: row.currentop %></td>
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

      <.modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.patch(~p"/deliveries")}>
        <.live_component
            module={ShophawkWeb.RunlistLive.ShowJob}
            id={@id || :show_job}
            job_ops={@job_ops}
            job_info={@job_info}
            title={@page_title}
            action={@live_action}
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

    updated_delivery =
      case Shophawk.Shop.get_department_by_delivery(delivery) do
        nil -> Shophawk.Shop.create_delivery(%{delivery: delivery, user_comment: comment})
        found -> Shophawk.Shop.update_delivery(found, %{user_comment: comment})
      end

    {:noreply, assign(socket, :delivery, updated_delivery)}
  end

  def handle_event("toggle_checkbox", %{"delivery" => delivery}, socket) do
    [{:data, rows}] = :ets.lookup(:delivery_list, :data)
    {:ok, updated_delivery} =
      case Shophawk.Shop.get_department_by_delivery(delivery) do
        nil -> Shophawk.Shop.create_delivery(%{delivery: delivery, packaged: true})
        found -> Shophawk.Shop.update_delivery(found, %{packaged: !found.packaged})
      end

    found_row = Enum.find(rows, &(&1.delivery) == updated_delivery.delivery)
    merged_row =
      Map.put(found_row, :packaged, updated_delivery.packaged)
      |> Map.put(:user_comment, updated_delivery.user_comment)
      |> Map.put(:type, :normal)

    # Logic to toggle the checkbox state or do something with the id
    # For example, you might want to update a state or perform an action based on this id
    {:noreply, stream_insert(socket, :deliveries, merged_row)}
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

end
