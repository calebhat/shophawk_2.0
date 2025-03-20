defmodule ShophawkWeb.ToolLive.CheckoutComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Inventory

  def render(assigns) do
    ~H"""
    <div>
      <div class="text-center content-center">
        <.header>
          <%= @title %>
          <:subtitle></:subtitle>
        </.header>
      </div>
      <div class="text-4xl">
        <%= @tool.description %>
      </div>
      <div class="text-2xl">
        <%= @tool.part_number %>
        <br>
        <.link_button link={@tool.tool_info}>Tool Info</.link_button>
        <br>
        <.link_button link={@tool.vendor}>Order Page </.link_button>

        <br>
        <%= @tool.location %>
      </div>

      <.simple_form
        for={@form}
        id="tool-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:checkout_amount]} type="text" label="Amount to Checkout" phx-hook="AutofocusHook"/>

        <%= if Map.has_key?(assigns.form.source.changes, :negative_checkout_message ) do %>
          <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
            <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
            <%= assigns.form.source.changes.negative_checkout_message %>
          </p>
        <% end %>

        <.input field={@form[:balance]} type="number" label="New Balance" readonly />
        <div class="hidden">
          <.input field={@form[:minimum]} type="number" label="Minimum to have in Stock" readonly />
          <.input field={@form[:original_balance]} type="number" label="Original Balance" readonly />
          <.input field={@form[:number_of_checkouts]} type="number" label="checkouts" readonly />
        </div>

        <:actions>
        <div class="flex justify-between items-center">
        <div>
          <.button phx-disable-with="Saving...">Checkout</.button>
        </div>
        <div>
            <.link patch={~p"/tools/#{@tool.id}/edit"} class="hover:bg-lime-700 hover:text-white py-1.5 px-3 rounded-lg">Edit</.link>
        </div>
        </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("save", %{"tool" => tool_params}, socket) do
    checkouts = String.to_integer(Map.get(tool_params,  "number_of_checkouts", 0))
    new_checkouts = checkouts + 1
    updated_tool_params = Map.update!(tool_params, "number_of_checkouts", fn _current_value -> Integer.to_string(new_checkouts) end)
    save_tool(socket, socket.assigns.action, updated_tool_params)
  end

  def handle_event("validate", %{"tool" => tool_params}, socket) do
    tool_params =
      case Integer.parse(Map.get(tool_params, "checkout_amount")) do
        {_, ""} -> #checks if the string can be converted to an integer
          Map.update!(tool_params, "balance", fn _value -> String.to_integer(Map.get(tool_params, "original_balance", "0")) - String.to_integer(Map.get(tool_params, "checkout_amount", "0")) end )
          #Map.update!(tool_params, "balance", fn _value -> calculate_checkout(tool_params) end)
        _ -> #if empty or not convertable to an integer, set balance to original balance
            Map.update!(tool_params, "balance", fn _value -> String.to_integer(Map.get(tool_params, "original_balance", "0")) end)
      end

    changeset =
      socket.assigns.tool
      |> Inventory.change_tool(tool_params) #get nil here
      |> Map.put(:action, :validate)
    socket = assign_form(socket, changeset)
    {:noreply, socket}
  end

  defp save_tool(socket, :checkout, tool_params) do
    min = String.to_integer(tool_params["minimum"])
    balance = String.to_integer(tool_params["balance"])
    tool_params =
      cond do
        min > balance -> Map.put(tool_params, "status", "needs_restock")
        min <= balance -> Map.put(tool_params, "status", "stocked")
        true -> tool_params
      end

    case Inventory.update_tool(socket.assigns.tool, tool_params) do
      {:ok, tool} ->
        notify_parent({:saved, tool})
        {:noreply,
         socket
         |> put_flash(:info, "Tool updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  def update(%{tool: tool} = assigns, socket) do
    changeset = Inventory.change_tool(tool)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

end
