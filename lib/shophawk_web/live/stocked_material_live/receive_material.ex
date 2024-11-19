defmodule ShophawkWeb.StockedMaterialLive.ReceiveMaterial do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  alias Shophawk.MaterialCache
  #import ShophawkWeb.StockedMaterialLive.Index

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex rounded-lg justify-center text-center text-white p-4">

      <div class="bg-cyan-950 p-4 rounded-lg">

        <div class="bg-cyan-800 rounded-lg m-2 pb-2">
          <div class="mb-4 text-2xl underline">Material To Receive</div>
          <div class="grid grid-cols-4 text-lg underline">
            <div>Material</div>
            <div>Length Needed</div>
            <div>Measured Length (Inches)</div>
            <div></div>
          </div>
          <div :for={bar <- @bars_on_order_form}}>
            <.form
              for={bar}
              id={"bar-#{bar.id}"}
              phx-change="validate_bar_to_receive"
              phx-submit="receive_bar"
            >
              <div class="grid grid-cols-4 p-1 place-items-center text-center text-lg bg-cyan-900 rounded-lg m-2">
                <div class="dark-tooltip-container">
                    <%= "#{bar.data.material}" %>
                    <!-- Loop through job assignments and display colored sections -->
                    <div class="relative h-full w-full">
                      <div class="tooltip ml-12 w-60" style="z-index: 12;">
                        <.fixed_widths_table_with_show_job
                        id="bar_assignments"
                        rows={Enum.reverse(bar.data.job_assignments)}
                        row_click={fn row_data -> "show_job" end}
                        >
                          <:col :let={bar} label="Job" width=""><%= bar.job %></:col>
                          <:col :let={bar} label="Length" width=""><%= bar.length_to_use %>"</:col>
                          <:col :let={bar} label="Parts" width=""><%= bar.parts_from_bar %></:col>
                        </.fixed_widths_table_with_show_job>
                      </div>
                    </div>
                </div>

                <div class="w-32">
                  <%= "#{if bar.data.bar_length != nil, do: (Float.round((bar.data.bar_length / 12), 2)), else: 0} ft" %>
                </div>

                <div class="px-2 text-center">
                  <div>
                    <div class="hidden"><.input field={bar[:id]} type="text" /></div>
                    <div class="w-32 pb-2 pl-2"><.input field={bar[:bar_length]} type="number" placeholder="Length" step=".01" /></div>
                  </div>
                </div>
                <div class="grid grid-cols-3">
                    <div class=""><.button phx-disable-with="Saving...">Receive</.button></div>
                    <div class="mx-4 w-24">
                      <.button type="button" phx-click="add_bar" phx-value-id={bar.data.id}>
                        Add Bar
                      </.button>
                    </div>
                    <div class="w-36">
                      <%= if bar.data.extra_bar_for_receiving == true do %>
                        <.delete_button type="button" phx-click="delete_bar" phx-value-id={bar.data.id}>
                          Remove Extra Bar
                        </.delete_button>
                      <% end %>
                    </div>
                </div>
              </div>
            </.form>
          </div>
        </div>

      </div>

    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    #IO.inspect(params)
    {:ok, update_material_forms(socket)}
  end

  def update_material_forms(socket) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    socket
    |> assign(bars_on_order_form: load_material_on_order(material_list))
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

    bars_to_order_changeset = Enum.map(sorted_material_to_order, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
  end

  def handle_event("validate_bar_to_receive", %{"stocked_material" => params}, socket) do
    {:noreply, validate_bar_to_receive(params, socket)}
  end

  def handle_event("receive_bar", params, socket) do
    params = params["stocked_material"]
    found_bar = Material.get_stocked_material!(params["id"])
    updated_params = Map.put(params, "ordered", false) |> Map.put("in_house", true)

    case Material.update_stocked_material(found_bar, updated_params, :receive) do
      {:ok, stocked_material} ->
        {:noreply, update_material_forms(socket)}

      {:error, changeset} ->
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
    |> IO.inspect

    {:noreply, update_material_forms(socket)}
  end

  def validate_bar_to_receive(params, socket) do
    bars = socket.assigns.bars_on_order_form
    # Determine the form being updated by matching the `id` hidden field
    form_id = Map.get(params, "id")

    updated_bars =
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
      assign(socket, :bars_on_order_form, updated_bars)
  end

  #validate_bar_to_receive

end
