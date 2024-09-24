defmodule ShophawkWeb.StockedMaterialLive.FormComponent do
  use ShophawkWeb, :live_component

  alias Shophawk.Material

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage stocked_material records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="stocked_material-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:material]} type="text" label="Material" />
        <.input field={@form[:bars]} type="text" label="Bars" />
        <.input field={@form[:slugs]} type="text" label="Slugs" />
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
    changeset =
      socket.assigns.stocked_material
      |> Material.change_stocked_material(stocked_material_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"stocked_material" => stocked_material_params}, socket) do
    save_stocked_material(socket, socket.assigns.action, stocked_material_params)
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
    case Material.create_stocked_material(stocked_material_params) do
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
