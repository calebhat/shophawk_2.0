defmodule ShophawkWeb.StockedMaterialLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  alias Shophawk.Material.StockedMaterial
  alias Shophawk.Jobboss_db

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :stockedmaterials, Material.list_stockedmaterials())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Stocked material")
    |> assign(:stocked_material, Material.get_stocked_material!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Stocked material")
    |> assign(:stocked_material, %StockedMaterial{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Stockedmaterials")
    |> assign(:stocked_material, nil)
  end

  @impl true
  def handle_info({ShophawkWeb.StockedMaterialLive.FormComponent, {:saved, stocked_material}}, socket) do
    {:noreply, stream_insert(socket, :stockedmaterials, stocked_material)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    stocked_material = Material.get_stocked_material!(id)
    {:ok, _} = Material.delete_stocked_material(stocked_material)

    {:noreply, stream_delete(socket, :stockedmaterials, stocked_material)}
  end

  def handle_event("test", _params, socket) do
    #Jobboss_db.load_material_information("10XGI") |> IO.inspect
    Jobboss_db.load_materials_and_sizes_into_cache
    {:noreply, socket}
  end

end
