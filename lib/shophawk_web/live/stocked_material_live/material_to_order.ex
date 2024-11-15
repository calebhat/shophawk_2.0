defmodule ShophawkWeb.StockedMaterialLive.MaterialToOrder do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  #import ShophawkWeb.StockedMaterialLive.Index

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-cyan-900 rounded-lg justify-center text-center text-white p-4">

      <div class="grid grid-cols-3">
        <div class="bg-cyan-800 rounded-lg m-2">
          <div class="mb-4 text-2xl underline">Material To Order</div>
          <div class="grid grid-cols-4 text-lg underline">
            <div>Material</div>
            <div>Amount Needed</div>
            <div>12 Month Usage</div>
            <div>Request sent</div>
          </div>
          <div :for={bar <- @bars_to_order_form}>
            <.form
              for={bar}
              id={"bar-#{bar.id}"}
              phx-change="validate_bars"
              phx-submit="save_material"
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
                          <:col :let={bar} label="Job" width="w-20"><%= bar.job %></:col>
                          <:col :let={bar} label="Length" width="w-16"><%= bar.length_to_use %>"</:col>
                          <:col :let={bar} label="Parts" width="w-16"><%= bar.parts_from_bar %></:col>
                        </.fixed_widths_table_with_show_job>
                      </div>
                    </div>

                </div>
                  <%= "#{if bar.data.bar_length != nil, do: (Float.round((bar.data.bar_length / 12), 2)), else: 0} ft" %>
                <div>

                </div>
                <div class="px-2 text-center">
                  <.button type="button" phx-click="being_quoted" phx-value-material={bar.data.material}>
                    ->
                  </.button>
                </div>
              </div>
            </.form>
          </div>
        </div>

        <div class="bg-cyan-800 rounded-lg m-2">
          <div class="mb-4 text-2xl underline">Quote Request Sent</div>
        </div>

        <div class="bg-cyan-800 rounded-lg m-2">
          <div class="mb-4 text-2xl underline">On Order</div>
            <div :for={bar <- @bars_to_order_form}>
              <.form
                for={bar}
                id={"bar-#{bar.id}"}
                phx-change="validate_bars"
                phx-submit="save_material"
              >
                <div class="flex p-1">
                  <div class="grow relative dark-tooltip-container">
                    <div class="bg-black rounded text-left h-full max-w-full" style={"width: #{if bar.data.bar_length != nil, do: (bar.data.bar_length * 100 / 12 / 12), else: 0}%"}>
                      <span class="absolute inset-0 flex justify-center items-center">
                        <%= "#{if bar.data.bar_length != nil, do: (Float.round((bar.data.bar_length / 12), 2)), else: 0} ft" %>
                        <%= "#{bar.data.material}" %>
                      </span>

                      <!-- Loop through job assignments and display colored sections -->
                      <div class="relative h-full w-full">
                        <%= for assignment <- bar.data.job_assignments do %>
                          <div
                            class="absolute h-full border border-dashed border-violet-500 "
                            style={"width: #{assignment.percentage_of_bar}%; left: #{assignment.left_offset}%;"}
                          >
                          </div>
                        <% end %>
                        <div class="tooltip mt-14 w-60" style="z-index: 12;">
                          <.fixed_widths_table_with_show_job
                          id="bar_assignments"
                          rows={Enum.reverse(bar.data.job_assignments)}
                          row_click={fn row_data -> "show_job" end}
                          >
                            <:col :let={bar} label="Job" width="w-20"><%= bar.job %></:col>
                            <:col :let={bar} label="Length" width="w-16"><%= bar.length_to_use %>"</:col>
                            <:col :let={bar} label="Parts" width="w-16"><%= bar.parts_from_bar %></:col>
                          </.fixed_widths_table_with_show_job>
                        </div>
                      </div>

                    </div>
                  </div>
                  <div>

                  </div>
                  <div>
                    <div class="hidden"><.input field={bar[:id]} type="text" /></div>
                    <div class="w-24 pb-2 pl-2"><.input field={bar[:bar_length]} type="number" placeholder="Length" step=".01" /></div>
                  </div>
                  <div class="pr-2">
                    <%= if bar.data.saved == false do %>
                      <img class="pl-2 pt-3" src={~p"/images/red_x.svg"} />
                      <div class="hidden"><.button phx-disable-with="Saving...">Save</.button></div>
                    <% else %>
                    <div class="flex">
                      <img class="pl-2 pt-3" src={~p"/images/black_checkmark.svg"} />

                      </div>
                    <% end %>
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
  def mount(_params, _session, socket) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    bars_to_order_changeset = load_material_to_order(material_list)
    bars_being_quoted_changeset = load_material_being_quoted(material_list)
    bars_on_order = load_material_on_order(material_list)

    {:ok, socket |> assign(bars_to_order_form: bars_to_order_changeset)}
  end

  def load_material_to_order(material_list) do
    material_to_order = Material.list_material_needed_to_order
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

  def load_material_being_quoted(material_list) do
    material_to_order = Material.list_material_being_quoted
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

  def handle_event("being_quoted", %{"material" => material}, socket) do
    IO.inspect(material)

    {:noreply, socket}
  end

  @impl true

end
