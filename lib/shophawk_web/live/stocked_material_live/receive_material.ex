defmodule ShophawkWeb.StockedMaterialLive.ReceiveMaterial do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJob #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  alias Shophawk.Material
  #import ShophawkWeb.StockedMaterialLive.Index

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user}/>
      <div class="rounded-lg text-center text-white p-4 flex justify-center">
        <div class="bg-cyan-900 p-4 rounded-lg w-max">
          <div class="bg-cyan-900 rounded-lg m-2 pb-2">
          <div class="grid grid-cols-3 items-center">
            <div class="p-1"></div>
            <div class="text-2xl underline text-center">Material To Receive</div>
            <div class="flex justify-end">
              <.button type="" phx-click="receive_all" phx-disable-with="Saving...">
                Receive All
              </.button>
            </div>
          </div>
              <table class="table-auto m-4">
                <thead class="text-lg underline">
                  <tr>
                    <th class="px-2">Material</th>
                    <th class="px-2">
                      <div class="flex items-center justify-between ml-6">
                        <div class="">length</div>
                        <div class="">Location</div>
                        <div class="">Receive</div>
                      </div>
                    </th>
                    <th class="px-2">Add Bar</th>
                    <th class="px-2">Delete</th>
                  </tr>
                </thead>
                <div :for={{date, bars_by_date} <- @bars_on_order_form}>
                  <tbody>
                    <tr><td colspan="4" class="text-xl text-center bg-cyan-950"><%= date %></td></tr>
                    <div :for={bars <- bars_by_date}>
                      <tr><td class="text-xl underline p-1"><%= List.first(bars).data.vendor %></td></tr>
                        <%= for bar <- bars do %>
                            <tr class="place-items-center text-lg bg-cyan-800">
                              <td class="dark-tooltip-container">
                                <.link
                                  navigate={~p"/stockedmaterials?#{[material: bar.data.material_name, size: bar.data.size]}"}
                                  class="dark-tooltip-container font-bold"
                                >
                                  <div>
                                    <%= bar.data.material %>
                                  </div>
                                </.link>
                                  <!-- Loop through job assignments and display colored sections -->
                                  <div class="relative h-full w-full">
                                    <div class="tooltip ml-12 w-60" style="z-index: 12;">
                                      <.fixed_widths_table_with_show_job
                                      id="bar_assignments"
                                      rows={Enum.reverse(bar.data.job_assignments)}
                                      row_click={fn _row_data -> "show_job" end}
                                      >
                                        <:col :let={bar} label="Job" width=""><%= bar.job %></:col>
                                        <:col :let={bar} label="Length" width=""><%= bar.length_to_use %>"</:col>
                                        <:col :let={bar} label="Parts" width=""><%= bar.parts_from_bar %></:col>
                                      </.fixed_widths_table_with_show_job>
                                    </div>
                                  </div>
                              </td>
                              <td class="px-2 text-center">
                                <.form
                                  for={bar}
                                  id={"bar-#{bar.data.id}"}
                                  phx-change="validate_bar_to_receive"
                                  phx-submit="receive_bar"
                                >
                                  <div class="flex items-center justify-between">
                                    <div class="hidden"><.input field={bar[:id]} type="text" /></div>
                                    <div class=" pb-2 px-2 w-48">
                                      <.input field={bar[:bar_length]}
                                      type="number"
                                      placeholder={if Map.has_key?(bar.data, :bar_length_placeholder), do: bar.data.bar_length_placeholder}
                                      step=".01"
                                      value={if Map.has_key?(bar.source.changes, :bar_length), do: bar.source.changes.bar_length, else: nil} />
                                    </div>
                                    <div class="mr-2 pb-2"><.input field={bar[:location]} type="text" placeholder="Location"/></div>
                                    <div class=""><.button type="submit" phx-disable-with="Saving...">Receive</.button></div>
                                  </div>
                                </.form>
                              </td>

                              <td class="">
                                <.info_button type="button" phx-click="add_bar" phx-value-id={bar.data.id}>
                                  Add Bar
                                </.info_button>
                              </td>
                              <td class="">
                                <%= if bar.data.extra_bar_for_receiving == true do %>
                                  <.delete_button type="button" phx-click="delete_bar" phx-value-id={bar.data.id}>
                                    Remove Extra Bar
                                  </.delete_button>
                                <% else %>
                                <.link
                                  class="mx-2 hover:text-red-500"
                                  phx-click={JS.push("delete_bar", value: %{id: bar.data.id}) |> hide("##{bar.data.id}")}
                                  data-confirm="Are you sure?"
                                >
                                  Delete
                                </.link>
                                <% end %>
                              </td>
                            </tr>
                        <% end %>
                    </div>
                  </tbody>
                </div>
              </table>
          </div>
        </div>

        <div class="text-black">
          <.modal :if={@live_action in [:show_job]} id="runlist-job-modal" show on_cancel={JS.patch(~p"/stockedmaterials/receive_material")}>
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

          <.modal :if={@live_action in [:job_attachments]} id="job-attachments-modal" show on_cancel={JS.push("show_job", value: %{job: @id})}>
          <.live_component
              module={ShophawkWeb.RunlistLive.JobAttachments}
              id={@id || :job_attachments}
              attachments={@attachments}
              title={@page_title}
              action={@live_action}
          />
          </.modal>
        </div>

      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do

    {:noreply, update_material_forms(socket)}
  end

  def update_material_forms(socket) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    assign(socket, bars_on_order_form: load_material_on_order(material_list) |> sort_by_vendor() |> IO.inspect)
  end

  def load_material_on_order(material_list) do
    material_to_order = Material.list_material_on_order
    list_of_sizes =
      Enum.reduce(material_list, [], fn mat, acc ->
        [mat.sizes | acc]
      end)
      |> List.flatten

    sorted_material_with_assignments_and_dates =
      Enum.map(material_to_order, fn mat ->
        found_assignments =
          Enum.find(list_of_sizes, fn size -> size.material_name == mat.material end).assigned_material_info
        Map.put(mat, :job_assignments, found_assignments)
        |> Map.put(:bar_length_placeholder, mat.bar_length)
      end)
      |> Enum.group_by(fn material ->
        material.purchase_date
      end)
      |> Enum.map(fn {date, materials} ->
        sorted_materials =
          Enum.map(materials, fn bar ->
            [size_str, material_name] =
              case String.split(bar.material, "X") do
                [size_str, material_name] -> [size_str, material_name]
                [size1, size2, material_name] ->
                    size_str = size1 <> "X" <> size2
                  [size_str, material_name]
              end
              |> Enum.map(&String.trim/1)

            size =
              case Float.parse(size_str) do
                {size, ""} -> size
                _ ->
                  case Integer.parse(size_str) do
                    {int_size, ""} -> int_size / 1
                    _ -> 0.0
                  end
              end

            {size, material_name, bar, size_str}
          end)
          |> Enum.sort_by(fn {size, material_name, _, _} -> {material_name, size} end)
          #|> Enum.map(fn {_, _, material} -> material end)

        {date, sorted_materials}
      end)

    Enum.map(sorted_material_with_assignments_and_dates, fn {date, sorted_materials} ->

      updated_sorted_materials =
        Enum.map(sorted_materials, fn {_size, material_name, bar, size_str} ->

          bar = Map.put(bar, :size, size_str) |> Map.put(:material_name, material_name)
          Material.change_stocked_material(bar, %{}) |> to_form()

        end)
      {date, updated_sorted_materials}
    end)
  end

  def sort_by_vendor(bars_sorted_by_date) do
    Enum.map(bars_sorted_by_date, fn {date, bars} ->
      list_of_vendors =
        Enum.reduce(bars, [], fn bar, acc ->
          case Enum.member?(acc, bar.data.vendor) do
            true -> acc
            false -> [bar.data.vendor | acc]
          end
        end)
        |> Enum.sort()
        |> Enum.map(fn vendor ->
          Enum.reduce(bars, [], fn bar, acc ->
            if bar.data.vendor == vendor, do: acc ++ [bar], else: acc
          end)
        end)
      {date, list_of_vendors}
    end)
  end

  @impl true
  def handle_event("validate_bar_to_receive", %{"stocked_material" => params}, socket) do
    {:noreply, validate_bar_to_receive(params, socket)}
  end

  def handle_event("receive_bar", params, socket) do
    params = params["stocked_material"]
    found_bar = Material.get_stocked_material!(params["id"])
    updated_params = Map.put(params, "ordered", false) |> Map.put("in_house", true) |> Map.put("bar_used", false)
    updated_params =
      case updated_params["bar_length"] do
        nil -> updated_params
        length -> Map.put(updated_params, "original_bar_length", length)
      end

    case Material.update_stocked_material(found_bar, updated_params, :receive) do
      {:ok, _stocked_material} ->
        Shophawk.MaterialCache.update_single_material_size_in_cache(found_bar.material)
        {:noreply, update_material_forms(socket)}

      {:error, _changeset} ->
        bars = socket.assigns.bars_on_order_form
        updated_bars =
          Enum.map(bars, fn vendor ->
            Enum.map(vendor, fn bar ->
              if bar.data.id == found_bar.id do

                changeset =
                  Material.change_stocked_material(found_bar, params, :receive)
                  |> Map.put(:action, :validate)

                to_form(changeset)
              else
                bar
              end
            end)
          end)

        {:noreply, assign(socket, bars_on_order_form: updated_bars)}
    end

  end

  def handle_event("receive_all", _params, socket) do
    Enum.each(socket.assigns.bars_on_order_form, fn vendor ->
      Enum.each(vendor, fn bar ->
        case bar.source.valid? do
          true ->
            updated_params = Map.put(bar.params, "ordered", false) |> Map.put("in_house", true) |> Map.put("bar_used", false)
            updated_params =
              case updated_params["bar_length"] do
                nil -> updated_params
                length -> Map.put(updated_params, "original_bar_length", length)
              end

            Material.update_stocked_material(bar.data, updated_params, :receive)
            Shophawk.MaterialCache.update_single_material_size_in_cache(bar.data.material)
          _ -> nil
          end
        end)
      end)
    {:noreply, update_material_forms(socket)}
  end

  def handle_event("add_bar", %{"id" => id}, socket) do
    bar_struct = Material.get_stocked_material!(id)
    attrs =
      bar_struct
      |> Map.from_struct()
      |> Map.drop([:id, :inserted_at, :updated_at])
      |> Map.put(:extra_bar_for_receiving, true)

    Material.create_stocked_material(attrs)

    {:noreply, update_material_forms(socket)}
  end

  def handle_event("delete_bar", %{"id" => id}, socket) do
    bar_struct = Material.get_stocked_material!(id)
    Material.delete_stocked_material(bar_struct)
    {:noreply, update_material_forms(socket)}
  end

  def validate_bar_to_receive(params, socket) do
    form_id = Map.get(params, "id")

    updated_bars =
      Enum.map(socket.assigns.bars_on_order_form, fn {date, bars_by_date} ->
        updated_bars_by_date =
          Enum.map(bars_by_date, fn bars ->
            Enum.map(bars, fn bar ->
              if Integer.to_string(bar.data.id) == form_id do
                updated_params = Map.put(params, "original_bar_length", params["bar_length"])
                changeset =
                  Material.change_stocked_material(bar.data, updated_params, :receive)
                  |> Map.put(:action, :validate)

                to_form(changeset)
              else
                bar
              end
            end)
          end)
          {date, updated_bars_by_date}
      end)
      assign(socket, :bars_on_order_form, updated_bars)
  end

end
