defmodule ShophawkWeb.ToolLive.CheckinComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Inventory

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle></:subtitle>
      </.header>
      <div class="text-xl">
      <%= @tool.part_number %>
      </div>
      <%= @tool.description %>
      <br>
      <%= @tool.location %>

      <.simple_form
        for={@form}
        id="tool-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:checkout_amount]} type="text" label="Amount to Checkout" autofocus="true" />
        <.input field={@form[:balance]} type="number" label="Balance" readonly />
        <div class="hidden">
          <.input field={@form[:original_balance]} type="number" label="Original Balance" readonly />
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Check In</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("save", %{"tool" => tool_params}, socket) do
    save_tool(socket, socket.assigns.action, tool_params)
  end

  def handle_event("validate", %{"tool" => tool_params}, socket) do
    tool_params =
      case Integer.parse(Map.get(tool_params, "checkout_amount")) do
        {_, ""} -> #checks if the string can be converted to an integer
          Map.update!(tool_params, "balance", fn _value -> String.to_integer(Map.get(tool_params, "original_balance", "0")) + String.to_integer(Map.get(tool_params, "checkout_amount", "0")) end )
          #Map.update!(tool_params, "balance", fn _value -> calculate_checkout(tool_params) end)
        _ -> #if empty or not convertable to an integer, set balance to original balance
            Map.update!(tool_params, "balance", fn _value -> String.to_integer(Map.get(tool_params, "original_balance", "0")) end)
      end
    changeset =
      socket.assigns.tool
      |> Inventory.change_tool(tool_params)
      |> Map.put(:action, :validate)
    socket = assign_form(socket, changeset)
      #IO.inspect(socket)
    {:noreply, socket}
  end

  def update(%{tool: tool} = assigns, socket) do
    changeset = Inventory.change_tool(tool)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp save_tool(socket, :checkin, tool_params) do
    case Inventory.update_tool(socket.assigns.tool, tool_params) do
      {:ok, tool} ->
        notify_parent({:saved, tool})

        {:noreply,
         socket
         |> put_flash(:info, "Tool updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

end
