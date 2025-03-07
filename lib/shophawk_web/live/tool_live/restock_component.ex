defmodule ShophawkWeb.ToolLive.RestockComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Inventory

  def render(assigns) do
    ~H"""
      <div class="bg-cyan-900 p-8 rounded-lg">

        <.header>
          <div class="text-2xl text-stone-200 underline">
            Tools to be restocked
          </div>
        </.header>
        <.compact_table
          id="tools"
          rows={@streams.needs_restock}
          row_click={fn {_id, tool} -> JS.navigate(~p"/tools/#{tool}/checkin") end}
        >
          <:col :let={{_id, tool}} label="Part number" width="w-1/12"><%= tool.part_number %></:col>
          <:col :let={{_id, tool}} label="Description" width="w-max"><%= tool.description %></:col>
          <:col :let={{_id, tool}} label="Balance" width="w-16"><%= tool.balance %></:col>
          <:col :let={{_id, tool}} label="Minimum" width="w-16"><%= tool.minimum %></:col>
          <:action :let={{_id, tool}}>
            <%= if String.contains?(tool.vendor, ".com") do %>
            <.light_link_button link={tool.vendor}>Order Page </.light_link_button>
            <% else %>
            <span class="px-2"><%= tool.vendor %></span>
            <% end %>
            <.light_link_button link={tool.tool_info}>Tool Info</.light_link_button>
          </:action>
          <:action :let={{_id, tool}}>
            <.link class="" navigate={~p"/tools/#{tool}/edit"}>Edit</.link>
          </:action>
          <:action :let={{_id, tool}}>
            <a class="cursor-pointer hover:text-stone-900" phx-click="in_cart" phx-value-id={tool.id} phx-target={@myself}>In Cart</a>
          </:action>
          <:action :let={{_id, tool}}>
            <a class="cursor-pointer hover:text-stone-900" phx-click="ordered" phx-value-id={tool.id} phx-target={@myself}>Ordered</a>
          </:action>
        </.compact_table>

        <br>
        <div class="text-2xl text-stone-200 underline">In Cart</div>
        <.compact_table
          id="tools"
          rows={@streams.in_cart}
          row_click={fn {_id, tool} -> JS.navigate(~p"/tools/#{tool}/checkin") end}
        >
          <:col :let={{_id, tool}} label="Part number" width="w-1/12"><%= tool.part_number %></:col>
          <:col :let={{_id, tool}} label="Description" width="w-max"><%= tool.description %></:col>
          <:col :let={{_id, tool}} label="Balance" width="w-16"><%= tool.balance %></:col>
          <:col :let={{_id, tool}} label="Minimum" width="w-16"><%= tool.minimum %></:col>
          <:action :let={{_id, tool}}>
            <%= if String.contains?(tool.vendor, ".com") do %>
            <.light_link_button link={tool.vendor}>Order Page </.light_link_button>
            <% else %>
            <span class="px-2"><%= tool.vendor %></span>
            <% end %>
            <.light_link_button link={tool.tool_info}>Tool Info</.light_link_button>
          </:action>
          <:action :let={{_id, tool}}>
            <.link class="" navigate={~p"/tools/#{tool}/edit"}>Edit</.link>
          </:action>
          <:action :let={{_id, tool}}>
            <a class="cursor-pointer hover:text-stone-900" phx-click="needs_restock" phx-value-id={tool.id} phx-target={@myself}>Needs Restock</a>
          </:action>
          <:action :let={{_id, tool}}>
            <a class="cursor-pointer hover:text-stone-900" phx-click="ordered" phx-value-id={tool.id} phx-target={@myself}>Ordered</a>
          </:action>
        </.compact_table>

        <br>
        <div class="text-2xl text-stone-200 underline">Tools On Order</div>
        <.compact_table
          id="tools"
          rows={@streams.ordered}
          row_click={fn {_id, tool} -> JS.navigate(~p"/tools/#{tool}/checkin") end}
        >
          <:col :let={{_id, tool}} label="Part number" width="w-1/12"><%= tool.part_number %></:col>
          <:col :let={{_id, tool}} label="Description" width="w-max"><%= tool.description %></:col>
          <:col :let={{_id, tool}} label="Balance" width="w-16"><%= tool.balance %></:col>
          <:col :let={{_id, tool}} label="Minimum" width="w-16"><%= tool.minimum %></:col>
          <:action :let={{_id, tool}}>
            <%= if String.contains?(tool.vendor, ".com") do %>
            <.light_link_button link={tool.vendor}>Order Page </.light_link_button>
            <% else %>
            <span class="px-2"><%= tool.vendor %></span>
            <% end %>
            <.light_link_button link={tool.tool_info}>Tool Info</.light_link_button>
          </:action>
          <:action :let={{_id, tool}}>
            <.link class="" navigate={~p"/tools/#{tool}/edit"}>Edit</.link>
          </:action>
          <:action :let={{_id, tool}}>
            <a class="cursor-pointer hover:text-stone-900" phx-click="needs_restock" phx-value-id={tool.id} phx-target={@myself}>Needs Restock</a>
          </:action>
          <:action :let={{_id, tool}}>
            <a class="cursor-pointer hover:text-stone-900" phx-click="in_cart" phx-value-id={tool.id} phx-target={@myself}>In Cart</a>
          </:action>
        </.compact_table>
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

  def handle_event("ordered", %{"id" => id}, socket) do
    Inventory.update_tool(Inventory.get_tool!(id), %{status: "ordered"})
    send_update(self(), ShophawkWeb.ToolLive.RestockComponent, id: "restock")

    {:noreply, socket}
  end

  def handle_event("needs_restock", %{"id" => id}, socket) do
    Inventory.update_tool(Inventory.get_tool!(id), %{status: "needs_restock"})
    send_update(self(), ShophawkWeb.ToolLive.RestockComponent, id: "restock")
    {:noreply, socket}
  end

  def handle_event("in_cart", %{"id" => id}, socket) do
    Inventory.update_tool(Inventory.get_tool!(id), %{status: "in_cart"})
    send_update(self(), ShophawkWeb.ToolLive.RestockComponent, id: "restock")
    {:noreply, socket}
  end

end
