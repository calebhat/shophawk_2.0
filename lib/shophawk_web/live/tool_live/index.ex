defmodule ShophawkWeb.ToolLive.Index do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJob #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  alias Shophawk.Inventory
  alias Shophawk.Inventory.Tool

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(results: [])
      |> assign(restock: [])
      |> assign(search_term: "")
      |> stream(:tools, Inventory.list_tools())
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = assign(socket, restock: Inventory.all_not_stocked?())
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket =
      socket
      |> assign(:page_title, "Edit Tool")
      |> assign(:tool, Inventory.get_tool!(id))
    updated_tool = %{ socket.assigns.tool | original_balance: socket.assigns.tool.balance}
    assign(socket, :tool, updated_tool)
  end

  defp apply_action(socket, :checkout, %{"id" => id}) do
    socket =
      socket
      |> assign(:page_title, "Checkout")
      |> assign(:tool, Inventory.get_tool!(id))
      updated_tool = %{ socket.assigns.tool | original_balance: socket.assigns.tool.balance, negative_checkout_message: nil } #save balance to :original_balance for use in live form calcs
      assign(socket, :tool, updated_tool)
  end

  defp apply_action(socket, :checkin, %{"id" => id}) do
    socket =
      socket
      |> assign(:page_title, "Check In Tool")
      |> assign(:tool, Inventory.get_tool!(id))
      updated_tool = %{ socket.assigns.tool | original_balance: socket.assigns.tool.balance} #save balance to :original_balance for use in live form calcs
      assign(socket, :tool, updated_tool)
  end

  defp apply_action(socket, :restock, _params) do
    socket =
      socket
      |> assign(:page_title, "Restock")
      |> assign(:tool, nil)
      |> stream(:tools, Inventory.list_tools(), reset: true)
      socket
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tool")
    |> assign(:tool, %Tool{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tools")
    |> assign(:tool, nil)
  end

  @impl true
  def handle_info({ShophawkWeb.ToolLive.FormComponent, {:saved, tool}}, socket) do
    {:noreply, stream_insert(socket, :tools, tool)}
  end

  def handle_info({ShophawkWeb.ToolLive.CheckoutComponent, {:saved, tool}}, socket) do
    {:noreply, stream_insert(socket, :tools, tool)}
  end

  def handle_info({ShophawkWeb.ToolLive.CheckinComponent, {:saved, tool}}, socket) do
    socket = if Inventory.needs_restock?() == [] do
      socket
    else
      assign(socket, :live_action, :restock)
    end
    {:noreply, stream_insert(socket, :tools, tool)}
  end

  def handle_info({ShophawkWeb.ToolLive.RestockComponent, {:saved, tool}}, socket) do
    {:noreply, stream_insert(socket, :tools, tool)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tool = Inventory.get_tool!(id)
    {:ok, _} = Inventory.delete_tool(tool)

    {:noreply, stream_delete(socket, :tools, tool)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    #search logic here
    if String.length(query) > 0 do
      result = Inventory.search(query)
      case length(result) do #checks how many results are found
        1 -> #if only one tool is found, go directly to checkout for that tool
          [%Shophawk.Inventory.Tool{id: id}] = result
          socket =
            socket
            |> stream(:tools, Inventory.search(query), reset: true)
            |> assign(:live_action, :checkout)
          {:noreply, apply_action(socket, :checkout, %{"id" => id})}
        _ -> #every other option
          {:noreply, stream(socket, :tools, Inventory.search(query), reset: true)}
      end
    else
      {:noreply, stream(socket, :tools, Inventory.list_tools(), reset: true)}
    end
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply, socket |> assign(:search_term, "")}
  end


end
