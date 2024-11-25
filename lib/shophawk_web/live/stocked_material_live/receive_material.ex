defmodule ShophawkWeb.StockedMaterialLive.ReceiveMaterial do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  #import ShophawkWeb.StockedMaterialLive.Index

  @impl true
  def render(assigns) do
    ~H"""
    <div class="rounded-lg text-center text-white p-4 flex justify-center">
      <div class="bg-cyan-950 p-4 rounded-lg w-max">
        <div class="bg-cyan-800 rounded-lg m-2 pb-2">
          <div class="mb-4 text-2xl underline">Material To Receive</div>
            <table class="table-auto m-4">
              <thead class="text-lg underline">
                <tr>
                  <th class="px-2">Material</th>
                  <th class="px-2">Length Needed</th>
                  <th class="px-2">Measured Length (In.)</th>
                  <th class="px-2">Add Bar</th>
                  <th class="px-2">Remove Extra</th>
                </tr>
              </thead>
              <div :for={vendor <- @bars_on_order_form}>
                <tbody>
                  <tr><td class="text-2xl underline p-1"><%= List.first(vendor).data.vendor %></td></tr>

                  <%= for bar <- vendor do %>

                      <tr class="place-items-center text-lg bg-cyan-900">

                        <td class="dark-tooltip-container">
                            <%= "#{bar.data.material}" %>
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

                        <td class="">
                          <%= "#{if bar.data.bar_length != nil, do: (Float.round((bar.data.bar_length / 12), 2)), else: 0} ft" %>
                        </td>

                        <td class="px-2 text-center">
                          <.form
                            for={bar}
                            id={"bar-#{bar.data.id}"}
                            phx-change="validate_bar_to_receive"
                            phx-submit="receive_bar"
                          >
                            <div class="flex items-center">
                              <div class="hidden"><.input field={bar[:id]} type="text" /></div>
                              <div class=" pb-2 px-2"><.input field={bar[:bar_length]} type="number" placeholder="Length" step=".01" /></div>
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
                              Remove Bar
                            </.delete_button>
                          <% end %>
                        </td>
                      </tr>
                  <% end %>
                </tbody>
              </div>
            </table>
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
    assign(socket, bars_on_order_form: load_material_on_order(material_list) |> sort_by_vendor() )
  end

  def load_material_on_order(material_list) do
    material_to_order = Material.list_material_on_order
    list_of_sizes =
      Enum.reduce(material_list, [], fn mat, acc ->
        [mat.sizes | acc]
      end)
      |> List.flatten

    material_with_assignments =
      Enum.map(material_to_order, fn mat ->
        found_assignments =
          Enum.find(list_of_sizes, fn size -> size.material_name == mat.material end).assigned_material_info
        Map.put(mat, :job_assignments, found_assignments)
      end)

    sorted_material_to_order =
      material_with_assignments
      |> Enum.map(fn material ->
      [size_str, material_name] =
        material.material
        |> String.split("X")
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

      {size, material_name, material}
      end)
      |> Enum.sort_by(fn {size, material_name, _} -> {material_name, size} end)
      |> Enum.map(fn {_, _, material} -> material end)

    Enum.map(sorted_material_to_order, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
  end

  def sort_by_vendor(bars_to_order_changeset) do
    list_of_vendors = Enum.reduce(bars_to_order_changeset, [], fn bar, acc ->
      case Enum.member?(acc, bar.data.vendor) do
        true -> acc
        false -> [bar.data.vendor | acc]
      end
    end)
    |> Enum.sort()


    Enum.map(list_of_vendors, fn vendor ->
      Enum.reduce(bars_to_order_changeset, [], fn bar, acc ->
        if bar.data.vendor == vendor, do: acc ++ [bar], else: acc
      end)
    end)
  end

  @impl true
  def handle_event("validate_bar_to_receive", %{"stocked_material" => params}, socket) do
    {:noreply, validate_bar_to_receive(params, socket)}
  end

  def handle_event("receive_bar", params, socket) do
    params = params["stocked_material"]
    found_bar = Material.get_stocked_material!(params["id"])
    updated_params = Map.put(params, "ordered", false) |> Map.put("in_house", true)
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
          Enum.map(bars, fn bar ->
            if bar.data.id == found_bar.id do

              changeset =
                Material.change_stocked_material(found_bar, params, :receive)
                |> Map.put(:action, :validate)

              to_form(changeset)
            else
              bar
            end
          end)

        {:noreply, assign(socket, bars_on_order_form: updated_bars)}
    end

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
    vendors = socket.assigns.bars_on_order_form
    # Determine the form being updated by matching the `id` hidden field
    form_id = Map.get(params, "id")

    updated_bars =
      Enum.map(vendors, fn bars ->
        Enum.map(bars, fn bar ->
          if Integer.to_string(bar.data.id) == form_id do
            changeset =
              Material.change_stocked_material(bar.data, params, :receive)
              |> Map.put(:action, :validate)

            to_form(changeset)
          else
            bar
          end
        end)
      end)
      assign(socket, :bars_on_order_form, updated_bars)
  end

  #validate_bar_to_receive

end
