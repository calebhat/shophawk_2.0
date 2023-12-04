defmodule ShophawkWeb.ToolLive.RestockComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Inventory

  def render(assigns) do
    ~H"""
      <div>

        <.header>
          Tools to be restocked
        </.header>
        <.table
          id="tools"
          rows={@streams.tools}
          row_click={fn {_id, tool} -> JS.navigate(~p"/tools/#{tool}/checkin") end}
        >
          <:col :let={{_id, tool}} label="Part number"><%= tool.part_number %></:col>
          <:col :let={{_id, tool}} label="Description"><%= tool.description %></:col>
          <:col :let={{_id, tool}} label="Balance"><%= tool.balance %></:col>
          <:col :let={{_id, tool}} label="Minimum"><%= tool.minimum %></:col>
          <:col :let={{_id, tool}} label="Location"><%= tool.location %></:col>
          <:col :let={{_id, tool}} label="Vendor"><%= tool.vendor %></:col>
          <:col :let={{_id, tool}} label="Tool info"><%= tool.tool_info %></:col>
          <:col :let={{_id, tool}} label="Number of checkouts"><%= tool.number_of_checkouts %></:col>
          <:col :let={{_id, tool}} label="Status"><%= tool.status %></:col>
          <:col :let={{_id, tool}} label="Department"><%= tool.department %></:col>
          <:action :let={{_id, tool}}>
            <div class="sr-only">
              <.link navigate={~p"/tools/#{tool}"}>Show</.link>
            </div>
            <.link patch={~p"/tools/#{tool}/edit"}>Edit</.link>
          </:action>
          <:action :let={{_id, tool}}>
            <.link patch={~p"/tools/#{tool}/checkout"}>Checkout</.link>
          </:action>
          <:action :let={{id, tool}}>
            <.link
              phx-click={JS.push("delete", value: %{id: tool.id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
            >
              Delete
            </.link>
          </:action>
        </.table>
      </div>
    """
  end


  def update(assigns, socket) do
    {:ok,
    socket
    |> assign(assigns)
    |> stream(:tools, Inventory.check_status())}
  end

end
