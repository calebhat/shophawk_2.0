defmodule ShophawkWeb.StockedMaterialLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  alias Shophawk.Material.StockedMaterial
  alias Shophawk.Jobboss_db

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:material_list, Jobboss_db.load_materials_and_sizes_into_cache)
      |> assign(:selected_material, "")
      |> assign(:selected_sizes, [])
      |> assign(:selected_size, "0.0")
      |> assign(:loading, false)
      |> assign(:material_info, nil)

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

  def handle_info({ref, material_info}, socket) do #Loads the material and size
    Process.demonitor(ref, [:flush])

    #IO.inspect(Material.list_stocked_material_by_material(material_info.material))
    bars_list = Material.list_stocked_material_by_material(material_info.material)
    bars_changeset = Enum.map(bars_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    #IO.inspect(bars_changeset)

    {:noreply,
    socket
    |> assign(loading: false)
    |> assign(material_info: material_info)
    |> assign(bars_list: bars_list)
    |> assign(bars_form: bars_changeset)
    }
  end

  @impl true
  def handle_event("validate", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar = Enum.find(socket.assigns.bars_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end)
    updated_changeset = Material.change_stocked_material(found_bar, stocked_material_params)
    updated_bar = Map.merge(found_bar, updated_changeset.changes)
    bars_list =
      Enum.map(socket.assigns.bars_list, fn bar ->
        IO.inspect(bar.id == updated_bar.id)
        case bar.id == updated_bar.id do
          true -> updated_bar
          _ -> bar
        end
      end)

    bars_changeset = Enum.map(bars_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    #IO.inspect(socket.assigns)
    #bars = Material.list_stocked_material_by_material(material_info.material)
    #bars_changeset = Enum.map(bars, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)

    #changeset =
    #  Enum.find(socket.assigns.bars_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end)
    #  |> Material.change_stocked_material(stocked_material_params)
    #  |> IO.inspect()
    #  |> Map.put(:action, :validate)



    #bars_list = Material.list_stocked_material_by_material(material_info.material)
    #bars_changeset = Enum.map(bars_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)

    #{:noreply, assign_bar_form(socket, changeset)}
    {:noreply,
    socket
    |> assign(bars_list: bars_list)
    |> assign(bars_form: bars_changeset)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    stocked_material = Material.get_stocked_material!(id)
    {:ok, _} = Material.delete_stocked_material(stocked_material)

    {:noreply, stream_delete(socket, :stockedmaterials, stocked_material)}
  end

  def handle_event("test", _params, socket) do
    #Jobboss_db.load_material_information("10XGI") |> IO.inspect
    #material_list = Jobboss_db.load_materials_and_sizes_into_cache
    #|> IO.inspect
    {:noreply, assign(socket, :loading, !socket.assigns.loading)}
  end

  def handle_event("load_material_sizes", %{"selected-material" => selected_material, "selected-size" => selected_size}, socket) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    {selected_size, loading} =
      if String.to_float(selected_size) in sizes do
        Task.async(fn -> load_material_information(selected_material, selected_size) end)
        {selected_size, true}
        else
          {"0.0", false}
      end
    {:noreply,
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:selected_sizes, sizes)
      |> assign(:selected_material, selected_material)
      |> assign(:material_info, nil)
      |> assign(:loading, loading)
    }
  end

  def handle_event("load_material_size", %{"selected-size" => selected_size, "selected-material" => selected_material}, socket) do
    Task.async(fn -> load_material_information(selected_material, selected_size) end)
    {:noreply,
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:material_info, nil)
      |> assign(:loading, true)}
  end

  defp load_material_information(selected_material, selected_size) do
    Jobboss_db.load_material_information(prepare_size_for_query(selected_size) <> "X" <> selected_material)
  end

  defp prepare_size_for_query(selected_size) do
    cond do
      String.ends_with?(selected_size, ".0") -> String.slice(selected_size, 0..-3)
      String.starts_with?(selected_size, "0.") -> String.slice(selected_size, 1..-1)
      true -> selected_size
    end
  end

  defp set_bg_color(entity, selected_entity) do
    selected_entity = if is_float(selected_entity) == true, do: Float.to_string(selected_entity), else: selected_entity
    #IO.inspect(entity)
    #IO.inspect(selected_entity)
    if selected_entity == entity, do: "bg-cyan-500 ml-2", else: "bg-stone-200"
  end

  defp assign_bar_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :bars, to_form(changeset))
  end


end
