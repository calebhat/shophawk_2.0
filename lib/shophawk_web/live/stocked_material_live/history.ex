defmodule ShophawkWeb.StockedMaterialLive.History do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  #alias Shophawk.MaterialCache

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div class="w-8/12 bg-cyan-900 px-10 rounded-lg flex">
      <.compact_table
        id="stockedmaterials"
        rows={@streams.stockedmaterials}
      >
        <:col :let={{_id, stocked_material}} label="Material"><%= stocked_material.material %></:col>
        <:col :let={{_id, stocked_material}} label="Bar Length"><%= stocked_material.bar_length %>"</:col>
        <:col :let={{_id, stocked_material}} label="Slug Count"><%= stocked_material.number_of_slugs %></:col>
        <:col :let={{_id, stocked_material}} label="Slug Length"><%= stocked_material.slug_length %>"</:col>
        <:col :let={{_id, stocked_material}} label="Vendor"><%= stocked_material.vendor %></:col>
        <:col :let={{_id, stocked_material}} label="Price"><%= Number.Currency.number_to_currency(stocked_material.purchase_price) %></:col>
        <:col :let={{_id, stocked_material}} label="Status"><%= stocked_material.status %></:col>
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
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    history = Material.list_stockedmaterials_history
    history =
      Enum.map(history, fn h ->
          cond do
            h.bar_used == true -> %{h | status: "Bar Used"}
            h.ordered == true -> %{h | status: "ordered"}
            h.in_house == true -> %{h | status: "In House"}
            h.being_quoted == true -> %{h | status: "Being Quoted"}
            true -> h
          end
      end)
    {:ok, stream(socket, :stockedmaterials, history)}
  end

end
