defmodule ShophawkWeb.StockedMaterialLive.History do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  #import ShophawkWeb.StockedMaterialLive.Index

  @impl true
  def render(assigns) do
    ~H"""
    <div class="rounded-lg text-center text-white p-4 flex justify-center">
      <div class="bg-cyan-950 p-4 rounded-lg w-max">
        <div class="bg-cyan-800 rounded-lg m-2 pb-2">
          <div class="mb-4 text-2xl underline">History</div>
            <table class="table-auto m-4">
              <thead class="text-lg underline">
                <tr>
                  <th class="px-2">Material</th>
                  <th class="px-2">Make Bar</th>
                  <th class="px-2">Waiting on Quote</th>
                  <th class="px-2">Need to Order</th>
                  <th class="px-2">Not Used</th>
                  <th class="px-2">Last Edited</th>
                </tr>
              </thead>
                <tbody>
                  <%= for bar <- @bar_history do %>

                      <tr class="place-items-center text-lg bg-cyan-900">

                        <td class="p-1">
                            <%= "#{bar.data.material}" %>
                        </td>

                        <td class="p-1">
                        <.button phx-click="make_bar" phx-value-id={bar.data.id}>Make Bar</.button>
                        </td>

                        <td class="px-2 text-center">
                        <.button phx-click="make_bar" phx-value-id={bar.data.id}>Waiting On Quote</.button>
                        </td>

                        <td class="p-1">
                        <.button phx-click="make_bar" phx-value-id={bar.data.id}>Need to Order</.button>
                        </td>

                        <td class="p-1">
                        <.button phx-click="make_bar" phx-value-id={bar.data.id}>NOT Used</.button>
                        </td>

                        <td class="p-1">
                        <%= "#{bar.data.updated_at}" %>
                        </td>
                      </tr>
                  <% end %>
                </tbody>
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

    {:noreply, update_history_form(socket)}
  end

  def update_history_form(socket) do
    #[{:data, _material_list}] = :ets.lookup(:material_list, :data)

    bar_history_form = Enum.map(Material.list_stockedmaterials_history, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)

    assign(socket, bar_history: bar_history_form)
  end

  @impl true
  def handle_event("validate_bar_to_receive", %{"stocked_material" => _params}, socket) do
    {:noreply, socket}
  end

  def handle_event("make_bar", %{"id" => id}, socket) do
    IO.inspect(id)
    {:noreply, socket}
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
        {:noreply, update_history_form(socket)}

      {:error, _changeset} ->
        bars = socket.assigns.bar_history
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

        {:noreply, assign(socket, bar_history: updated_bars)}
    end

  end

end
