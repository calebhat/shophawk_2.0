defmodule ShophawkWeb.ToolLive.FormComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage tool records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="tool-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:part_number]} type="text" label="Part number (barcode)" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:balance]} type="number" label="Balance" />
        <.input field={@form[:minimum]} type="number" label="Minimum to have in Stock" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:vendor]} type="text" label="Vendor (name/website)" />
        <.input field={@form[:tool_info]} type="text" label="Tool info (website)" />
        <.input field={@form[:number_of_checkouts]} type="number" label="Number of checkouts" readonly />
        <.input field={@form[:status]} type="text" label="Status" readonly />
       <!-- <.input field={@form[:department]} type="text" label="Department" /> -->
        <:actions>
          <.button phx-disable-with="Saving...">Save Tool</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{tool: tool} = assigns, socket) do
    changeset = Inventory.change_tool(tool)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"tool" => tool_params}, socket) do
    IO.inspect(tool_params)
    changeset =
      socket.assigns.tool
      |> Inventory.change_tool(tool_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"tool" => tool_params}, socket) do
    save_tool(socket, socket.assigns.action, tool_params)
  end

  defp save_tool(socket, :edit, tool_params) do
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

  defp save_tool(socket, :new, tool_params) do
    case Inventory.create_tool(tool_params) do
      {:ok, tool} ->
        notify_parent({:saved, tool})

        {:noreply,
         socket
         |> put_flash(:info, "Tool created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
