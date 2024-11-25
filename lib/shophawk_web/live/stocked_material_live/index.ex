defmodule ShophawkWeb.StockedMaterialLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  alias Shophawk.Material.StockedMaterial
  alias Shophawk.Jobboss_db
  alias Shophawk.MaterialCache

  @impl true
  def mount(_params, _session, socket) do
    #reload material into cache with assignments
    #Shophawk.MaterialCache.create_material_cache
    [{:data, material_list}] = :ets.lookup(:material_list, :data)

    material_needed_to_order_count = Enum.count(Material.list_material_needed_to_order_and_material_being_quoted())
    material_on_order_count = Enum.count(Material.list_material_on_order())




    #material_list = if connected?(socket), do: Jobboss_db.load_materials_and_sizes_into_cache(), else: []
    socket =
      socket
      |> assign(:material_list, material_list)
      |> assign(:selected_material, "")
      |> assign(:selected_sizes, [])
      |> assign(:selected_size, "0.0")
      |> assign(:loading, false)
      |> assign(:size_info, nil)
      |> assign(:material_name, "")
      |> assign(:material_to_order_count, material_needed_to_order_count)
      |> assign(:material_on_order_count, material_on_order_count)

    {:ok, socket}
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
  def handle_event("validate_bars", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar = Material.get_stocked_material!(stocked_material_params["id"]) |> Map.put(:saved, false)
    socket =
      if found_bar.in_house == true do
        bar_in_stock_list =
          Material.list_stocked_material_by_material(found_bar.material) |> Enum.sort_by(&(&1.bar_length))
          |> Enum.reject(fn mat -> mat.in_house == false && mat.being_quoted == false && mat.ordered == false end)
          |> Enum.reject(fn mat -> mat.bar_length == nil end)
          |> Enum.map(fn bar -> if bar.id == found_bar.id, do: found_bar, else: bar end)

        bars_in_stock_changeset = Enum.map(bar_in_stock_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)

        assign(socket, bars_in_stock_form: bars_in_stock_changeset)
      else
        bar_to_order_list  =
          Material.list_stocked_material_by_material(found_bar.material) |> Enum.sort_by(&(&1.bar_length))
          |> Enum.map(fn bar -> if bar.id == found_bar.id, do: found_bar, else: bar end)
          bars_to_order_changeset  = Enum.map(bar_to_order_list , fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)

        assign(socket, bars_to_order_form: bars_to_order_changeset)
      end
    {:noreply, socket}
  end

  def handle_event("validate_bars_to_order", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar = Material.get_stocked_material!(stocked_material_params["id"]) |> Map.put(:saved, false)
    socket =
      if found_bar.in_house == false do
        bar_to_order_list =
          Material.list_stocked_material_by_material(found_bar.material) |> Enum.sort_by(&(&1.bar_length))
          |> Enum.reject(fn mat -> mat.in_house == true end) #reject bars in stock
          |> Enum.reject(fn mat -> mat.bar_length == nil end) #reject slugs
          |> Enum.map(fn bar -> if bar.id == found_bar.id, do: found_bar, else: bar end)

        bars_to_order_changeset = Enum.map(bar_to_order_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)

        assign(socket, bars_to_order_form: bars_to_order_changeset)

      end
    {:noreply, socket}
  end

  def handle_event("validate_slugs", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar = Material.get_stocked_material!(stocked_material_params["id"]) |> Map.put(:saved, false)
    #updated_changeset = Material.change_stocked_material(found_bar, stocked_material_params)
    #updated_slug = Map.merge(found_bar, updated_changeset.changes)
    slugs_list =
      Material.list_stocked_material_by_material(found_bar.material) |> Enum.sort_by(&(&1.slug_length))
      |> Enum.reject(fn mat -> mat.in_house == false && mat.being_quoted == false && mat.ordered == false end)
      |> Enum.reject(fn mat -> mat.bar_length != nil end)
      |> Enum.map(fn bar -> if bar.id == found_bar.id, do: found_bar, else: bar end)

    slugs_changeset = Enum.map(slugs_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    {:noreply, socket |> assign(slugs_form: slugs_changeset)}
  end

  def handle_event("bar_used", %{"selected-size" => selected_size, "selected-material" => selected_material, "id" => id}, socket) do
    found_bar = Material.get_stocked_material!(id)
    case found_bar.purchase_price do
      nil -> Material.delete_stocked_material(found_bar)
      _ -> Material.update_stocked_material(found_bar , %{slug_length: nil, bar_length: nil, bar_used: true})
    end
    MaterialCache.update_single_material_size_in_cache(found_bar.material)
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("make_slug", %{"selected-size" => selected_size, "selected-material" => selected_material, "id" => id}, socket) do
    found_bar = Material.get_stocked_material!(id)
    Material.update_stocked_material(found_bar , %{slug_length: found_bar.bar_length, number_of_slugs: 1, bar_length: nil})
    MaterialCache.update_single_material_size_in_cache(found_bar.material)
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("new_bar", %{"selected-size" => selected_size, "selected-material" => selected_material}, socket) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    size_info =
      case Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end) do
        nil -> nil
        size_info -> size_info
      end
    Material.create_stocked_material(%{material: size_info.material_name, bar_length: "0.0", in_house: true})
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("new_slug", %{"selected-size" => selected_size, "selected-material" => selected_material}, socket) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    size_info =
      case Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end) do
        nil -> nil
        size_info -> size_info
      end
    Material.create_stocked_material(%{material: size_info.material_name, slug_length: "0.0", number_of_slugs: "1", in_house: true})
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  #Replace above two functions with this.
  def handle_event("save_material", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar =
      Material.get_stocked_material!(stocked_material_params["id"])
      |> Map.put(:bar_length, nil) #need to clear value or it won't recognize there's a change bc we're changing the value during validations
      |> Map.put(:slug_length, nil) #need to clear value or it won't recognize there's a change bc we're changing the value during validations
      |> Map.put(:saved, true)
    {:ok, saved_material} = Material.update_stocked_material(found_bar, stocked_material_params)

    #MATERIAL_LIST IS SAVED TO CACHE AND UPDATED HERE
    #Currently this function re-checks for new mat_reqs in JB, change to only update current reqs?
    MaterialCache.update_single_material_size_in_cache(saved_material.material)

    {:noreply, reload_size(socket, socket.assigns.selected_size, socket.assigns.selected_material)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    stocked_material = Material.get_stocked_material!(id)
    {:ok, _} = Material.delete_stocked_material(stocked_material)

    {:noreply, stream_delete(socket, :stockedmaterials, stocked_material)}
  end

  @impl true
  def handle_event("load_material", %{"selected-material" => selected_material, "selected-size" => selected_size}, socket) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    sizes = Enum.find(material_list, fn mat -> mat.material == selected_material end).sizes
    size_info = Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end)

    socket =
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:size_info, size_info)
      |> assign(:selected_sizes, sizes)
      |> assign(:selected_material, selected_material)

    if size_info do
      {:noreply, load_material_forms(socket, %{material_name: size_info.material_name, location_id: size_info.location_id, on_hand_qty: size_info.on_hand_qty, assigned_material_info: size_info.assigned_material_info})}
    else
      {:noreply, socket}
    end
end

  ###### Showjob and attachments downloads ########
  def handle_event("show_job", %{"job" => job}, socket), do: {:noreply, ShophawkWeb.RunlistLive.Index.showjob(socket, job)}

  def handle_event("attachments", _, socket) do
    job = socket.assigns.id
    #[{:data, attachments}] = :ets.lookup(:job_attachments, :data)
    attachments = Jobboss_db.export_attachments(job)
    socket =
      socket
      |> assign(id: job)
      |> assign(attachments: attachments)
      |> assign(page_title: "Job #{job} attachments")
      |> assign(:live_action, :job_attachments)

    {:noreply, socket}
  end

  def handle_event("download", %{"file-path" => file_path}, socket) do
    {:noreply, push_event(socket, "trigger_file_download", %{"url" => "/download/#{URI.encode(file_path)}"})}
  end

  def handle_event("download", _params, socket), do: {:noreply, socket |> assign(:not_found, "File not found")}

  def handle_event("close_job_attachments", _params, socket), do: {:noreply, assign(socket, live_action: :show_job)}

  def handle_event("test", _params, socket) do

    MaterialCache.create_material_cache
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    {:noreply, socket |> assign(:material_list, material_list)}
  end

  ##### other functions #####

  defp reload_size(socket, selected_size, selected_material) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    sizes = Enum.find(material_list, fn mat -> mat.material == selected_material end).sizes
    size_info = Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end)
    material_info =
      case Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end) do
        nil -> nil
        material -> material
      end
    socket =
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:material_info, material_info)
      |> assign(:size_info, size_info)
      load_material_forms(socket, material_info)
  end

  def load_material_forms(socket, material_info) do
    single_material_and_size =
      Material.list_stocked_material_by_material(material_info.material_name)
      |> Enum.map(fn bar ->
        assigned_jobs =
          Enum.reduce(material_info.assigned_material_info, [], fn job, acc ->
            if job.material_id == bar.id, do: [job | acc], else: acc
          end)
        %{bar | job_assignments: assigned_jobs}
      end)
    bar_in_stock_list = Enum.filter(single_material_and_size, fn bar -> bar.bar_length != nil && bar.in_house == true end) |> Enum.sort_by(&(&1.bar_length))

    bars_in_stock_changeset = Enum.map(bar_in_stock_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    bar_to_order_list = Enum.filter(single_material_and_size, fn bar -> bar.bar_length != nil && bar.in_house == false end) |> Enum.sort_by(&(&1.bar_length))
    bars_to_order_changeset = Enum.map(bar_to_order_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    slugs_list = Enum.filter(single_material_and_size, fn slug -> slug.slug_length != nil end) |> Enum.sort_by(&(&1.slug_length))
    slugs_changeset = Enum.map(slugs_list, fn slug -> Material.change_stocked_material(slug, %{}) |> to_form() end)
    related_jobs =
      Enum.find(socket.assigns.selected_sizes, fn size -> size.size == String.to_float(socket.assigns.selected_size) end).matching_jobs
      |> Enum.sort_by(&(&1.due_date), Date)

    socket
    |> assign(bars_in_stock_form: bars_in_stock_changeset)
    |> assign(bars_to_order_form: bars_to_order_changeset)
    |> assign(slugs_form: slugs_changeset)
    |> assign(related_jobs: related_jobs) #list of job numbers to saw for material
  end

  def calc_left_offset(assignments, current_assignment) do
    previous_assignments = Enum.take_while(assignments, fn assignment -> assignment != current_assignment end)

    total_length_used = Enum.reduce(previous_assignments, 0, fn assignment, acc ->
      acc + assignment.length_to_use
    end)

    Float.round((total_length_used / Enum.at(assignments, 0).bar_length) * 100, 2)
  end

  def find_material_to_order(socket) do
    material_that_needs_cutting =
      Enum.flat_map(socket.assigns.material_list, fn map -> map.sizes end)
      |> Enum.filter(fn size_map -> size_map.matching_jobs != [] end)

      Enum.map(socket.assigns.material_list, fn material ->
        material_to_order =
          Enum.find(material_that_needs_cutting, fn map ->
            case String.split(map.material_info.material_name, "X", parts: 2) do
              [_] -> nil
              [_size, material_name] -> material_name == material.material
            end
          end)

          case material_to_order do
            nil -> material
            x ->
              amount_to_order = Enum.reduce(x.matching_jobs, 0.0, fn job, acc -> job.qty + acc end)
              Map.put(material_to_order, :need_to_order_amt, amount_to_order)
            end
      end)

  end

  ##### Functions ran during HTML generation from heex template #####
  defp set_bg_color(entity, selected_entity) do
    selected_entity = if is_float(selected_entity) == true, do: Float.to_string(selected_entity), else: selected_entity
    if selected_entity == entity, do: "bg-cyan-500 ml-2", else: "bg-stone-200"
  end

end
