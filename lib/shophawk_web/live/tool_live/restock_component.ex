defmodule ShophawkWeb.ToolLive.RestockComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Inventory

  def render(assigns) do
    ~H"""
      <div class="bg-cyan-800 p-8 rounded-lg">

        <.header>
          <div class="text-2xl text-stone-200 underline">
            Tools to be restocked
          </div>
        </.header>
        <.table
          id="tools"
          rows={@streams.needs_restock}
          row_click={fn {_id, tool} -> JS.navigate(~p"/tools/#{tool}/checkin") end}
        >
          <:col :let={{_id, tool}} label="Part number"><%= tool.part_number %></:col>
          <:col :let={{_id, tool}} label="Description"><%= tool.description %></:col>
          <:col :let={{_id, tool}} label="Balance"><%= tool.balance %></:col>
          <:col :let={{_id, tool}} label="Minimum"><%= tool.minimum %></:col>
          <:col :let={{_id, tool}} label="Location"><%= tool.location %></:col>
          <:col :let={{_id, tool}} label="Status"><%= tool.status %></:col>
          <:action :let={{_id, tool}}>
              <a class="hover:text-stone-900" href={tool.vendor} target="_blank">Order Website</a>
          </:action>
          <:action :let={{_id, tool}}>
          <.link navigate={~p"/tools/#{tool}"}>Details</.link>
          </:action>
          <:action :let={{_id, tool}}>
          <div phx-click="ordered" phx-value-id={tool.id}>Ordered</div>
          </:action>
        </.table>

        <br>
        <div class="text-2xl text-stone-200 underline">In Cart</div>
        <.table
          id="tools"
          rows={@streams.in_cart}
          row_click={fn {_id, tool} -> JS.navigate(~p"/tools/#{tool}/checkin") end}
        >
          <:col :let={{_id, tool}} label="Part number"><%= tool.part_number %></:col>
          <:col :let={{_id, tool}} label="Description"><%= tool.description %></:col>
          <:col :let={{_id, tool}} label="Balance"><%= tool.balance %></:col>
          <:col :let={{_id, tool}} label="Minimum"><%= tool.minimum %></:col>
          <:col :let={{_id, tool}} label="Location"><%= tool.location %></:col>
          <:col :let={{_id, tool}} label="Status"><%= tool.status %></:col>
          <:action :let={{_id, tool}}>
              <a class="hover:text-stone-900" href={tool.vendor} target="_blank">Order Website</a>
          </:action>
          <:action :let={{_id, tool}}>
          <.link navigate={~p"/tools/#{tool}"}>Details</.link>
          </:action>
          <:action :let={{_id, tool}}>
          <div phx-click="in_cart" phx-value-id={tool.id}>In Cart</div>
          </:action>
        </.table>

        <br>
        <div class="text-2xl text-stone-200 underline">Tools On Order</div>
        <.table
          id="tools"
          rows={@streams.ordered}
          row_click={fn {_id, tool} -> JS.navigate(~p"/tools/#{tool}/checkin") end}
        >
          <:col :let={{_id, tool}} label="Part number"><%= tool.part_number %></:col>
          <:col :let={{_id, tool}} label="Description"><%= tool.description %></:col>
          <:col :let={{_id, tool}} label="Balance"><%= tool.balance %></:col>
          <:col :let={{_id, tool}} label="Minimum"><%= tool.minimum %></:col>
          <:col :let={{_id, tool}} label="Location"><%= tool.location %></:col>
          <:col :let={{_id, tool}} label="Status"><%= tool.status %></:col>
          <:action :let={{_id, tool}}>
              <a class="hover:text-stone-900" href={tool.vendor} target="_blank">Order Website</a>
          </:action>
          <:action :let={{_id, tool}}>
          <.link navigate={~p"/tools/#{tool}"}>Details</.link>
          </:action>
          <:action :let={{_id, tool}}>
          <div phx-click="needs_restock" phx-value-id={tool.id}>Restock</div>
          </:action>
        </.table>
      </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
    socket
    |> assign(assigns)
    |> stream(:needs_restock, Inventory.needs_restock?(), reset: true)
    |> stream(:in_cart, Inventory.in_cart?(), reset: true)
    |> stream(:ordered, Inventory.ordered?(), reset: true)}
  end

end
