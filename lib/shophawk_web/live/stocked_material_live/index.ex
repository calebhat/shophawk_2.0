defmodule ShophawkWeb.StockedMaterialLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.StockedmaterialLive.SelectedMaterial
  alias Shophawk.Material
  alias Shophawk.Material.StockedMaterial
  alias Shophawk.Jobboss_db
  alias Shopahawk.MaterialCache

  @impl true
  @impl true
  def mount(_params, _session, socket) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)

    #material_list = if connected?(socket), do: Jobboss_db.load_materials_and_sizes_into_cache(), else: []

    socket =
      socket
      |> assign(:material_list, material_list)
      |> assign(:selected_material, "")
      |> assign(:selected_sizes, [])
      |> assign(:selected_size, "0.0")
      |> assign(:loading, false)
      |> assign(:size_info, nil)
      |> assign(:show_related_jobs, false)
      |> assign(:material_name, "")

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
    found_bar =
      Enum.find(socket.assigns.bars_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end)
      |> Map.put(:saved, false)
    updated_changeset = Material.change_stocked_material(found_bar, stocked_material_params)
    updated_bar = Map.merge(found_bar, updated_changeset.changes)
    bars_list =
      Enum.map(socket.assigns.bars_list, fn bar ->
        case bar.id == updated_bar.id do
          true -> updated_bar
          _ -> bar
        end
      end)
    bars_changeset = Enum.map(bars_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    {:noreply, socket |> assign(bars_list: bars_list) |> assign(bars_form: bars_changeset)}
  end

  def handle_event("validate_slugs", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar =
      Enum.find(socket.assigns.bars_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end)
      |> Map.put(:saved, false)
    updated_changeset = Material.change_stocked_material(found_bar, stocked_material_params)
    updated_slug = Map.merge(found_bar, updated_changeset.changes)
    slugs_list =
      Enum.map(socket.assigns.slugs_list, fn bar ->
        case bar.id == updated_slug.id do
          true -> updated_slug
          _ -> bar
        end
      end)
    slugs_changeset = Enum.map(slugs_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    {:noreply, socket |> assign(slugs_list: slugs_list) |> assign(slugs_form: slugs_changeset)}
  end

  def handle_event("bar_used", %{"selected-size" => selected_size, "selected-material" => selected_material, "id" => id}, socket) do
    found_bar = Material.get_stocked_material!(id)
    case found_bar.purchase_price do
      nil -> Material.delete_stocked_material(found_bar)
      _ -> Material.update_stocked_material(found_bar , %{slug_length: nil, bar_length: nil, bar_used: true})
    end
    Shophawk.MaterialCache.load_specific_material_and_size_into_cache(found_bar.material, socket)
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("make_slug", %{"selected-size" => selected_size, "selected-material" => selected_material, "id" => id}, socket) do
    found_bar = Material.get_stocked_material!(id)
    Material.update_stocked_material(found_bar , %{slug_length: found_bar.bar_length, number_of_slugs: 1, bar_length: nil})
    Shophawk.MaterialCache.load_specific_material_and_size_into_cache(found_bar.material, socket)
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
      Enum.find(socket.assigns.bars_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end)
      |> Map.put(:bar_length, nil) #need to clear value or it won't recognize there's a change bc we're changing the value during validations
      |> Map.put(:slug_length, nil) #need to clear value or it won't recognize there's a change bc we're changing the value during validations
      |> Map.put(:saved, true)
    {:ok, saved_material} = Material.update_stocked_material(found_bar, stocked_material_params |> Map.delete("id"))

    #MATERIAL_LIST IS SAVED TO CACHE AND UPDATED HERE
    #Currently this function re-checks for new mat_reqs in JB, change to only update current reqs?
    updated_material_list = Shophawk.MaterialCache.load_specific_material_and_size_into_cache(saved_material.material, socket)

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

  def handle_event("show_related_jobs", _params, socket), do: {:noreply, assign(socket, :show_related_jobs, !socket.assigns.show_related_jobs)}

  ###### Showjob and attachments downloads ########
  def handle_event("show_job", %{"job" => job}, socket), do: {:noreply, ShophawkWeb.RunlistLive.Index.showjob(socket, job)}

  def handle_event("attachments", _, socket) do
    job = socket.assigns.id
    #[{:data, attachments}] = :ets.lookup(:job_attachments, :data)
    attachments = Shophawk.Jobboss_db.export_attachments(job)
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
    #open_material_reqs = Jobboss_db.load_material_requirements
    #find_material_to_order(socket)
    #Jobboss_db.load_jb_material_information("10XGI")
    #material_list = Jobboss_db.load_materials_and_sizes_into_cache
    {:noreply, socket}
  end

  ##### other functions #####

  defp reload_size(socket, selected_size, selected_material) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    sizes = Enum.find(material_list, fn mat -> mat.material == selected_material end).sizes
    material_info =
      case Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end) do
        nil -> nil
        material -> material
      end
    socket =
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:material_info, material_info)
      load_material_forms(socket, material_info)
  end

  def load_material_forms(socket, material_info) do
    single_material_and_size =
      Material.list_stocked_material_by_material(material_info.material_name)
      |> Enum.map(fn bar ->
        assigned_jobs =
          Enum.reduce(material_info.assigned_material_info, [], fn job, acc ->
            acc = if job.material_id == bar.id, do: [job | acc], else: acc
          end)
        %{bar | job_assignments: assigned_jobs}
      end)

    #updated_material_list = Shophawk.MaterialCache.load_specific_material_and_size_into_cache(List.first(single_material_and_size).material, socket)

    bars_list = Enum.filter(single_material_and_size, fn bar -> bar.bar_length != nil end) |> Enum.sort_by(&(&1.bar_length))
    slugs_list = Enum.filter(single_material_and_size, fn slug -> slug.slug_length != nil end) |> Enum.sort_by(&(&1.slug_length))
    bars_changeset = Enum.map(bars_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    slugs_changeset = Enum.map(slugs_list, fn slug -> Material.change_stocked_material(slug, %{}) |> to_form() end)
    related_jobs = Enum.find(socket.assigns.selected_sizes, fn size -> size.size == String.to_float(socket.assigns.selected_size) end).matching_jobs

    socket
    |> assign(bars_list: bars_list)
    |> assign(bars_form: bars_changeset)
    |> assign(slugs_list: slugs_list)
    |> assign(slugs_form: slugs_changeset)
    |> assign(related_jobs: related_jobs) #list of job numbers to saw for material
    |> assign(show_related_jobs: false) #toggles div from "jobs to saw" button
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
              [size, material_name] -> material_name == material.material
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
