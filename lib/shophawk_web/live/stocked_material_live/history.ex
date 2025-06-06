defmodule ShophawkWeb.StockedMaterialLive.History do
  use ShophawkWeb, :live_view
  use Timex

  alias Shophawk.Material
  #alias Shophawk.MaterialCache

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={ShophawkWeb.Components.Navbar} id="navbar" current_user={@current_user}/>
    <div class="flex justify-center pt-6">



      <div class="w-11/12 bg-cyan-900 px-10 rounded-lg">

      <div class="flex">
      <.compact_table
        id="stockedmaterials"
        rows={@streams.stockedmaterials}
      >
        <:col :let={{_id, stocked_material}} label="Material">
          <.link
            navigate={~p"/stockedmaterials?#{[material: stocked_material.material_name, size: stocked_material.size]}"}
            class="dark-tooltip-container font-bold"
          >
            <div>
              <%= stocked_material.material %>
            </div>
          </.link>
        </:col>
        <:col :let={{_id, stocked_material}} label="Purchase Bar Length"><%= stocked_material.original_bar_length %>"</:col>
        <:col :let={{_id, stocked_material}} label="Current Bar Length"><%= stocked_material.bar_length %>"</:col>
        <:col :let={{_id, stocked_material}} label="Slug Count"><%= stocked_material.number_of_slugs %></:col>
        <:col :let={{_id, stocked_material}} label="Slug Length"><%= stocked_material.slug_length %>"</:col>
        <:col :let={{_id, stocked_material}} label="Vendor"><%= stocked_material.vendor %></:col>
        <:col :let={{_id, stocked_material}} label="Price"><%= Number.Currency.number_to_currency(stocked_material.purchase_price) %></:col>
        <:col :let={{_id, stocked_material}} label="Status"><%= stocked_material.status %></:col>
        <:col :let={{_id, stocked_material}} label="TimeStamp" width="w-48">
        <% {:ok, utc_timestamp} = DateTime.from_naive(stocked_material.updated_at, "Etc/UTC") %>
        <% {:ok, chicago_timestamp} = DateTime.shift_zone(utc_timestamp, "America/Chicago") %>
        <%= Timex.format!(chicago_timestamp, "{YYYY}-{0M}-{0D} {h12}:{m} {AM}") %>
        </:col>
        <:action :let={{_id, stocked_material}}>
          <div class="sr-only">
            <.link navigate={~p"/stockedmaterials/#{stocked_material}"}>Show</.link>
          </div>
          <.link patch={~p"/stockedmaterials/#{stocked_material}/detailededit"}>Edit</.link>
        </:action>
        <:action :let={{id, stocked_material}}>
          <.link
            phx-click={JS.push("delete", value: %{id: stocked_material.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.compact_table>
      </div>

      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    history =
      case params do
        %{"material" => material} ->
          Material.list_stockedmaterials_history(material)
          |> Enum.map(fn h ->
            [size_str, material_name] =
              case String.split(h.material, "X") do
                [size_str, material_name] -> [size_str, material_name]
                [size1, size2, material_name] ->
                    size_str = size1 <> "X" <> size2
                  [size_str, material_name]
              end
              |> Enum.map(&String.trim/1)

            cond do
              h.bar_used == true -> %{h | status: "Bar Used"}
              h.ordered == true -> %{h | status: "ordered"}
              h.in_house == true -> %{h | status: "In House"}
              h.being_quoted == true -> %{h | status: "Being Quoted"}
              true -> h
            end
            |> Map.put(:material_name, material_name)
            |> Map.put(:size, size_str)
          end)
        %{} ->
          Material.list_stockedmaterials_history
          |> Enum.map(fn h ->
            [size_str, material_name] =
              case String.split(h.material, "X") do
                [size_str, material_name] -> [size_str, material_name]
                [size1, size2, material_name] ->
                    size_str = size1 <> "X" <> size2
                  [size_str, material_name]
              end
              |> Enum.map(&String.trim/1)
            cond do
              h.bar_used == true -> %{h | status: "Bar Used"}
              h.ordered == true -> %{h | status: "ordered"}
              h.in_house == true -> %{h | status: "In House"}
              h.being_quoted == true -> %{h | status: "Being Quoted"}
              true -> h
            end
            |> Map.put(:material_name, material_name)
            |> Map.put(:size, size_str)
          end)
      end

    socket =
      socket
      |> assign(:material_name, params["material_name"])
      |> assign(:size, params["size"])

    {:ok, stream(socket, :stockedmaterials, history, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    stocked_material = Material.get_stocked_material!(id)
    Material.delete_stocked_material(stocked_material)

    {:noreply, socket}
  end

end
