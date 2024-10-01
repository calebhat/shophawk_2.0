defmodule ShophawkWeb.StockedMaterialLive.Index do
  use ShophawkWeb, :live_view

  alias Shophawk.Material
  alias Shophawk.Material.StockedMaterial
  alias Shophawk.Jobboss_db

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      socket =
        socket
        |> assign(:material_list, Jobboss_db.load_materials_and_sizes_into_cache)
        |> assign(:selected_material, "")
        |> assign(:selected_sizes, [])
        |> assign(:selected_size, "0.0")
        |> assign(:loading, false)
        |> assign(:material_info, nil)
        |> assign(:show_related_jobs, false)
        |> assign(:material_name, "")

      {:ok, socket}
    else
      socket =
        socket
        |> assign(:material_list, [])
        |> assign(:selected_material, "")
        |> assign(:selected_sizes, [])
        |> assign(:selected_size, "0.0")
        |> assign(:loading, false)
        |> assign(:material_info, nil)
        |> assign(:show_related_jobs, false)
        |> assign(:material_name, "")

      {:ok, socket}
    end

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
    {:noreply, load_bar_forms(stocked_material_params, socket, :validate)}
  end

  def handle_event("validate_slugs", %{"stocked_material" => stocked_material_params}, socket) do
    {:noreply, load_slug_forms(stocked_material_params, socket, :validate)}
  end

  def handle_event("bar_used", %{"selected-size" => selected_size, "selected-material" => selected_material, "id" => id}, socket) do
    found_bar = Material.get_stocked_material!(id)
    case found_bar.purchase_price do
      nil -> Material.delete_stocked_material(found_bar)
      _ -> Material.update_stocked_material(found_bar , %{slug_length: nil, bar_length: nil, bar_used: true})
    end
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("make_slug", %{"selected-size" => selected_size, "selected-material" => selected_material, "id" => id}, socket) do
    found_bar = Material.get_stocked_material!(id)
    Material.update_stocked_material(found_bar , %{slug_length: found_bar.bar_length, number_of_slugs: 1, bar_length: nil})
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("new_bar", %{"selected-size" => selected_size, "selected-material" => selected_material}, socket) do
    Material.create_stocked_material(%{material: socket.assigns.material_info.material_name, bar_length: "0.0"})
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("new_slug", %{"selected-size" => selected_size, "selected-material" => selected_material}, socket) do
    Material.create_stocked_material(%{material: socket.assigns.material_info.material_name, slug_length: "0.0", number_of_slugs: "1"})
    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("save_bar_length", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar =
      Enum.find(socket.assigns.bars_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end)
      |> Map.put(:bar_length, nil) #need to clear value or it won't recognize there's a change bc we're changing the value during validations
      |> Map.put(:saved, true)
    Material.update_stocked_material(found_bar , stocked_material_params |> Map.delete("id"))
    {:noreply, load_bar_forms(stocked_material_params, socket, :save)}
  end

  def handle_event("save_slug_length", %{"stocked_material" => stocked_material_params}, socket) do
    found_slug =
      Enum.find(socket.assigns.slugs_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end)
      |> Map.put(:slug_length, nil) #need to clear value or it won't recognize there's a change bc we're changing the value during validations
      |> Map.put(:saved, true)
    Material.update_stocked_material(found_slug , stocked_material_params |> Map.delete("id"))
    {:noreply, load_slug_forms(stocked_material_params, socket, :save)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    stocked_material = Material.get_stocked_material!(id)
    {:ok, _} = Material.delete_stocked_material(stocked_material)

    {:noreply, stream_delete(socket, :stockedmaterials, stocked_material)}
  end

  def handle_event("load_material_sizes", %{"selected-material" => selected_material, "selected-size" => selected_size, "material-name" => material_name}, socket) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    socket =
      if String.to_float(selected_size) in Enum.map(sizes, fn size -> size.size end) do
        material_info =
          case Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end) do
            nil -> nil
            material -> material.material_info
          end
        socket
        |> assign(:selected_size, selected_size)
        |> assign(:material_info, material_info)
        |> assign(:selected_sizes, sizes)
        |> load_material_forms(material_info)
      else
        socket
        |> assign(:selected_size, "0.0")
        |> assign(:material_info, nil)
        |> assign(:selected_sizes, sizes)
      end
    {:noreply, socket |> assign(:selected_material, selected_material)
    }
  end

  def handle_event("load_material_size", %{"selected-size" => selected_size, "selected-material" => selected_material, "material-name" => material_name}, socket) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    material_info =
      case Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end) do
        nil -> nil
        material -> material.material_info
      end
    socket =
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:material_info, material_info)
    {:noreply, load_material_forms(socket, material_info)}
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
    open_material_reqs = Jobboss_db.load_material_requirements
    IO.inspect(Enum.count(open_material_reqs))
    IO.inspect(Enum.count(socket.assigns.material_list))
    #IO.inspect(socket.assigns.material_list)
    #Jobboss_db.load_jb_material_information("10XGI") |> IO.inspect
    #material_list = Jobboss_db.load_materials_and_sizes_into_cache
    #|> IO.inspect
    {:noreply, socket}
  end

  ##### other functions #####

  defp reload_size(socket, selected_size, selected_material) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    material_info =
      case Enum.find(sizes, fn size -> size.size == String.to_float(selected_size) end) do
        nil -> nil
        material -> material.material_info
      end
    socket =
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:material_info, material_info)
    load_material_forms(socket, material_info)
  end

  def load_material_forms(socket, material_info) do
    material_list = Material.list_stocked_material_by_material(material_info.material_name)
    bars_list = Enum.filter(material_list, fn bar -> bar.bar_length != nil end) |> Enum.sort_by(&(&1.bar_length))
    slugs_list = Enum.filter(material_list, fn slug -> slug.slug_length != nil end) |> Enum.sort_by(&(&1.slug_length))
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

  defp load_bar_forms(stocked_material_params, socket, action) do
    found_bar = #toggles visability of save button.
      case action do
        :validate -> Enum.find(socket.assigns.bars_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end) |> Map.put(:saved, false)
        :save -> Enum.find(socket.assigns.bars_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end) |> Map.put(:saved, true)
      end
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
      |> Enum.sort_by(fn bar -> if action == :save, do: bar.bar_length, else: nil end)

    bars_changeset = Enum.map(bars_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    socket |> assign(bars_list: bars_list) |> assign(bars_form: bars_changeset)
  end

  defp load_slug_forms(stocked_material_params, socket, action) do
    found_slug = #toggles visability of save button.
      case action do
        :validate -> Enum.find(socket.assigns.slugs_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end) |> Map.put(:saved, false)
        :save -> Enum.find(socket.assigns.slugs_list, fn bar -> bar.id == String.to_integer(stocked_material_params["id"]) end) |> Map.put(:saved, true)
      end
    updated_changeset = Material.change_stocked_material(found_slug, stocked_material_params)
    updated_bar = Map.merge(found_slug, updated_changeset.changes)
    slugs_list =
      Enum.map(socket.assigns.slugs_list, fn bar ->
        IO.inspect(bar.id == updated_bar.id)
        case bar.id == updated_bar.id do
          true -> updated_bar
          _ -> bar
        end
      end)
      |> Enum.sort_by(fn bar -> if action == :save, do: bar.bar_length, else: nil end)

    slugs_changeset = Enum.map(slugs_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    socket |> assign(slugs_list: slugs_list) |> assign(slugs_form: slugs_changeset)
  end

  def find_material_to_order(socket) do
    #Jobboss_db.load_jb_material_information(prepare_size_for_query(selected_size) <> "X" <> selected_material)
    #related_jobs = Enum.find(socket.assigns.selected_sizes, fn size -> size.size == String.to_float(socket.assigns.selected_size) end).matching_jobs
    #total_qty_needed =  Enum.reduce(related_jobs, 0.0, fn job, acc -> job.qty + acc end) |> IO.inspect
  end

  ##### Functions ran during HTML generation from heex template #####
  defp set_bg_color(entity, selected_entity) do
    selected_entity = if is_float(selected_entity) == true, do: Float.to_string(selected_entity), else: selected_entity
    if selected_entity == entity, do: "bg-cyan-500 ml-2", else: "bg-stone-200"
  end

end
