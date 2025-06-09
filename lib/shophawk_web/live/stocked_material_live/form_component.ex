defmodule ShophawkWeb.StockedMaterialLive.FormComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Material

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Only use this form for past bars not received properly, ask Caleb if unsure</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="stocked_material-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:material]} type="text" label="Material" value={@material} disabled="true" />
        <div class="hidden"><.input field={@form[:material]} type="text" label="Material" value={@material} /></div>
        <.input field={@form[:bar_length]} type="number" label="Bar Length" />
        <.input field={@form[:purchase_date]} type="date" label="Purchase Date" value={@form[:purchase_date]} />
        <.input field={@form[:purchase_price]} type="number" label="Purchase Price" />
        <.input field={@form[:vendor]} type="text" label="Vendor" phx-debounce="2000"/>
        <.input field={@form[:location]} type="text" label="Location" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Stocked material</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{stocked_material: stocked_material} = assigns, socket) do
    changeset = Material.change_stocked_material(stocked_material)
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"stocked_material" => stocked_material_params}, socket) do
    updated_params = ShophawkWeb.StockedMaterialLive.MaterialToOrder.autofill_vendor(stocked_material_params)
    changeset =
      socket.assigns.stocked_material
      |> Material.change_stocked_material(updated_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"stocked_material" => stocked_material_params}, socket) do
    save_stocked_material(socket, socket.assigns.action, stocked_material_params)
  end

  def handle_event("autofill_vendor", params, socket) do
    updated_params = ShophawkWeb.StockedMaterialLive.MaterialToOrder.autofill_vendor(params)

    changeset =
      socket.assigns.stocked_material
      |> Material.change_stocked_material(updated_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp save_stocked_material(socket, :edit, stocked_material_params) do
    case Material.update_stocked_material(socket.assigns.stocked_material, stocked_material_params) do
      {:ok, stocked_material} ->
        notify_parent({:saved, stocked_material})

        {:noreply,
         socket
         |> put_flash(:info, "Stocked material updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_stocked_material(socket, :new, stocked_material_params) do
    updated_stocked_material_params =
      Map.put(stocked_material_params, "original_bar_length", stocked_material_params["bar_length"])
      |> Map.put("in_house", true)

    case Material.create_stocked_material(updated_stocked_material_params) do
      {:ok, stocked_material} ->
        notify_parent({:saved, stocked_material})

        {:noreply,
         socket
         |> put_flash(:info, "Stocked material created successfully")
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
