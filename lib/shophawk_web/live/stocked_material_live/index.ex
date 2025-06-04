defmodule ShophawkWeb.StockedMaterialLive.Index do
  use ShophawkWeb, :live_view
  use ShophawkWeb.ShowJob #functions needed for showjob modal to work
  use ShophawkWeb.FlashRemover

  alias Shophawk.Material
  alias Shophawk.Material.StockedMaterial
  alias Shophawk.MaterialCache
  #import Number.Currency

  @topic "materials:updates"

  on_mount {ShophawkWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      ShophawkWeb.Endpoint.subscribe(@topic)
    end

    #{:ok, initial_material_list_creation(socket)}

    case :ets.lookup(:material_list, :data) do
      [{:data, []}] ->
        {:ok, initial_material_list_creation(socket)}
      [{:data, material_list}] ->
        {:ok, assign_material_data(socket, material_list)}
    end
  end

  defp assign_material_data(socket, material_list) do
    material_needed_to_order_count =
      Material.list_material_needed_to_order_and_material_being_quoted()
      |> ShophawkWeb.StockedMaterialLive.MaterialToOrder.ignore_material_to_order()
      |> Enum.count()
    material_on_order_count = Enum.count(Material.list_material_on_order())

    socket
    |> assign(:material_list, material_list)
    |> assign(:grouped_materials, create_material_categories(material_list))
    |> assign(:collapsed_groups, [1, 2, 3, 4])
    |> assign(:selected_material, "")
    |> assign(:selected_sizes, [])
    |> assign(:selected_size, "0.0")
    |> assign(:loading, false)
    |> assign(:size_info, nil)
    |> assign(:material_name, "")
    |> assign(:material_to_order_count, material_needed_to_order_count)
    |> assign(:material_on_order_count, material_on_order_count)
  end

  defp initial_material_list_creation(socket) do
    material_list = Shophawk.MaterialCache.create_material_cache()
    material_needed_to_order_count =
      Material.list_material_needed_to_order_and_material_being_quoted()
      |> ShophawkWeb.StockedMaterialLive.MaterialToOrder.ignore_material_to_order()
      |> Enum.count()
    material_on_order_count = Enum.count(Material.list_material_on_order())

    socket
    |> assign(:material_list, material_list)
    |> assign(:grouped_materials, create_material_categories(material_list))
    |> assign(:collapsed_groups, [1, 2, 3, 4])
    |> assign(:selected_material, "")
    |> assign(:selected_sizes, [])
    |> assign(:selected_size, "0.0")
    |> assign(:loading, false)
    |> assign(:size_info, nil)
    |> assign(:material_name, "")
    |> assign(:material_to_order_count, material_needed_to_order_count)
    |> assign(:material_on_order_count, material_on_order_count)
  end

  defp push_material_data_update(socket, material_list) do
    material_needed_to_order_count =
      Material.list_material_needed_to_order_and_material_being_quoted()
      |> ShophawkWeb.StockedMaterialLive.MaterialToOrder.ignore_material_to_order()
      |> Enum.count()
    material_on_order_count = Enum.count(Material.list_material_on_order())

    socket =
      socket
      |> assign(:material_list, material_list)
      |> assign(:grouped_materials, create_material_categories(material_list))
      |> assign(:material_to_order_count, material_needed_to_order_count)
      |> assign(:material_on_order_count, material_on_order_count)


    found_material = Enum.find(material_list, fn mat -> mat.material == socket.assigns.selected_material end)
    sizes =
      case found_material do
        nil -> []
        found -> found.sizes
      end

      case sizes do
        [] -> socket
        sizes ->
          size_info =  Enum.find(sizes, fn size ->
            this_size =
              case Float.parse(size.size) do
                {this_size, _} -> this_size
                _ -> 0.0
              end
            selected_size =
              case Float.parse(socket.assigns.selected_size) do
                {selected_size, _} -> selected_size
                _ -> 1.0
              end
            this_size >= selected_size
          end) || List.first(sizes)
          selected_size = size_info.size
          socket
          |> assign(:selected_size, selected_size)
          |> assign(:selected_sizes, sizes)
          |> assign(:selected_material, socket.assigns.selected_material)
          |> assign(:size_info, size_info)
      end
  end

  @impl true
  def handle_params(params, _url, socket) do
    case Map.has_key?(params, "size") do
      true ->
        corrected_material_name = Shophawk.MaterialCache.merge_materials([%{material: params["material"]}])
        |> List.first()
        {:noreply, reload_size(socket, params["size"], corrected_material_name.material)}
      _ -> {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end

  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Stocked material")
    |> assign(:stocked_material, Material.get_stocked_material!(id))
  end

  defp apply_action(socket, :detailededit, %{"id" => id}) do
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
  def handle_info(%{event: "material_update", payload: new_material_list}, socket) do
    {:noreply, push_material_data_update(socket, new_material_list)}
  end

  def handle_info({ShophawkWeb.StockedMaterialLive.FormComponent, {:saved, _stocked_material}}, socket) do
    {:noreply, reload_size(socket, socket.assigns.selected_size, socket.assigns.selected_material)}

    #{:noreply, socket}
  end
  def handle_info({ShophawkWeb.StockedMaterialLive.DetailedFormComponent, {:saved, _stocked_material, _assigns}}, socket) do
    {:noreply, reload_size(socket, socket.assigns.selected_size, socket.assigns.selected_material)}
  end

  @impl true
  def handle_event("validate_bars", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar = Material.get_stocked_material!(stocked_material_params["id"]) |> Map.put(:saved, false)
    socket =
      if found_bar.in_house == true do
        bar_in_stock_list =
          Material.list_material_not_used_by_material(found_bar.material) |> Enum.sort_by(&(&1.bar_length))
          |> Enum.filter(fn mat -> mat.in_house == true end)
          #|> Enum.reject(fn mat -> mat.in_house == false && mat.being_quoted == false && mat.ordered == false end)
          |> Enum.reject(fn mat -> mat.bar_length == nil end)
          |> Enum.map(fn bar -> if bar.id == found_bar.id, do: found_bar, else: bar end)

        bars_in_stock_changeset = Enum.map(bar_in_stock_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)

        assign(socket, bars_in_stock_form: bars_in_stock_changeset)
      else
        bar_to_order_list  =
          Material.list_material_not_used_by_material(found_bar.material) |> Enum.sort_by(&(&1.bar_length))
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
          Material.list_material_not_used_by_material(found_bar.material) |> Enum.sort_by(&(&1.bar_length))
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
    slugs_list =
      Material.list_material_not_used_by_material(found_bar.material) |> Enum.sort_by(&(&1.slug_length))
      |> Enum.reject(fn mat -> mat.in_house == false && mat.being_quoted == false && mat.ordered == false end)
      |> Enum.reject(fn mat -> mat.bar_length != nil end)
      |> Enum.map(fn bar -> if bar.id == found_bar.id, do: found_bar, else: bar end)

    slugs_changeset = Enum.map(slugs_list, fn bar -> Material.change_stocked_material(bar, %{}) |> to_form() end)
    {:noreply, socket |> assign(slugs_form: slugs_changeset)}
  end

  def handle_event("bar_used", %{"selected-size" => selected_size, "selected-material" => selected_material, "id" => id}, socket) do
    found_bar = Material.get_stocked_material!(id)
    updated_in_jobboss =
      case found_bar.purchase_price do
        nil -> Material.delete_stocked_material(found_bar)
        _ -> Material.update_stocked_material(found_bar , %{slug_length: nil, bar_length: nil, bar_used: true})
      end
    MaterialCache.update_single_material_size_in_cache(found_bar.material)

    socket =
      if updated_in_jobboss == false, do: socket |> assign(:live_action, :jobboss_save_error), else: socket

    {:noreply, reload_size(socket, selected_size, selected_material)}
  end

  def handle_event("make_slug", %{"selected-size" => selected_size, "selected-material" => selected_material, "id" => id}, socket) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    size_info =
      case Enum.find(sizes, fn size -> size.size == selected_size end) do
        nil -> nil
        size_info -> size_info
      end
    location = if size_info.location_id == nil, do: "", else: size_info.location_id
    case location do
      "" -> {:noreply, assign(socket, :live_action, :jobboss_save_error)}
      _ ->
        found_bar = Material.get_stocked_material!(id)
        Material.update_stocked_material(found_bar , %{slug_length: found_bar.bar_length, number_of_slugs: 1, bar_length: nil})
        MaterialCache.update_single_material_size_in_cache(found_bar.material)
        {:noreply, reload_size(socket, selected_size, selected_material)}
    end
  end

  def handle_event("new_bar", %{"selected-size" => selected_size, "selected-material" => selected_material}, socket) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    size_info =
      case Enum.find(sizes, fn size -> size.size == selected_size end) do
        nil -> nil
        size_info -> size_info
      end
    location = if size_info.location_id == nil, do: "", else: size_info.location_id
    case location do
      "" -> {:noreply, assign(socket, :live_action, :jobboss_save_error)}
      _ ->
        Material.create_stocked_material(%{material: size_info.material_name, bar_length: "0.0", in_house: true})
        {:noreply, reload_size(socket, selected_size, selected_material)}
    end

  end

  def handle_event("new_slug", %{"selected-size" => selected_size, "selected-material" => selected_material}, socket) do
    sizes = Enum.find(socket.assigns.material_list, fn mat -> mat.material == selected_material end).sizes
    size_info =
      case Enum.find(sizes, fn size -> size.size == selected_size end) do
        nil -> nil
        size_info -> size_info
      end
    location = if size_info.location_id == nil, do: "", else: size_info.location_id
    case location do
      "" -> {:noreply, assign(socket, :live_action, :jobboss_save_error)}
      _ ->
        Material.create_stocked_material(%{material: size_info.material_name, slug_length: "0.0", number_of_slugs: "1", in_house: true})
        {:noreply, reload_size(socket, selected_size, selected_material)}
    end
  end

  def handle_event("save_material", %{"stocked_material" => stocked_material_params}, socket) do
    found_bar = Material.get_stocked_material!(stocked_material_params["id"])

    {jobboss_saved, _updated_material} = Material.update_stocked_material(found_bar, stocked_material_params)

    case jobboss_saved do
      :ok ->
        updated_found_bar =
          found_bar
          |> Map.put(:bar_length, nil) #need to clear value or it won't recognize there's a change bc we're changing the value during validations
          |> Map.put(:slug_length, nil) #need to clear value or it won't recognize there's a change bc we're changing the value during validations
          |> Map.put(:saved, true)
        #MATERIAL_LIST IS SAVED TO CACHE AND UPDATED HERE
        MaterialCache.update_single_material_size_in_cache(updated_found_bar.material)

        {:noreply, reload_size(socket, socket.assigns.selected_size, socket.assigns.selected_material)}
      _ -> #if false displays a modal with instructions to make a material adjustment
        {:noreply, assign(socket, :live_action, :jobboss_save_error)}
    end


  end

  def handle_event("delete", %{"id" => id}, socket) do
    stocked_material = Material.get_stocked_material!(id)
    Material.delete_stocked_material(stocked_material)

    {:noreply, socket}
  end

  def handle_event("load_material", %{"selected-material" => selected_material, "selected-size" => selected_size}, socket) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    sizes = Enum.find(material_list, fn mat -> mat.material == selected_material end).sizes
    size_info =  Enum.find(sizes, fn size -> size.size == selected_size end) || List.first(sizes)
    selected_size = size_info.size

    socket =
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:selected_sizes, sizes)
      |> assign(:selected_material, selected_material)

    if size_info do
      socket = assign(socket, :size_info, size_info)
      {:noreply, load_material_forms(socket, %{material_name: size_info.material_name, location_id: size_info.location_id, on_hand_qty: size_info.on_hand_qty, assigned_material_info: size_info.assigned_material_info})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_group", %{"group-index" => index}, socket) do
    index = String.to_integer(index)

    updated_collapsed = if index in (socket.assigns.collapsed_groups || []) do
      List.delete(socket.assigns.collapsed_groups || [], index)
    else
      [index | (socket.assigns.collapsed_groups || [])]
    end

    groups =
      Enum.map(socket.assigns.grouped_materials, fn {group, index} ->
        materials = Enum.reduce(group.materials, [], fn g, acc -> [g.material | acc] end)
        %{index => materials}
      end)

    group_being_collapsed =
      Enum.find(groups, fn g -> Map.has_key?(g, index) end)
      |> Map.get(index)

    #Hide sizes if open group is collapsed
    socket =
      if socket.assigns.selected_material in group_being_collapsed do
      socket
        |> assign(:selected_size, 0.0)
        |> assign(:selected_sizes, [])
        |> assign(:selected_material, "")
        |> assign(:size_info, nil)
      else
        socket
      end

    {:noreply, assign(socket, :collapsed_groups, updated_collapsed)}
  end

  ##### other functions #####

  defp reload_size(socket, selected_size, selected_material) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    sizes = Enum.find(material_list, fn mat -> mat.material == selected_material end).sizes
    size_info = Enum.find(sizes, fn size -> size.size == selected_size end)
    material_info =
      case Enum.find(sizes, fn size -> size.size == selected_size end) do
        nil -> nil
        material -> material
      end

    socket =
      socket
      |> assign(:selected_size, selected_size)
      |> assign(:selected_sizes, sizes)
      |> assign(:material_info, material_info)
      |> assign(:size_info, size_info)
      load_material_forms(socket, material_info)
  end

  def load_material_forms(socket, material_info) do
    single_material_and_size =
      Material.list_material_not_used_by_material(material_info.material_name)
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
      Enum.find(socket.assigns.selected_sizes, fn size -> size.size == socket.assigns.selected_size end).matching_jobs
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
  defp set_material_bg_color(entity, selected_entity) do
    selected_entity = if is_float(selected_entity) == true, do: Float.to_string(selected_entity), else: selected_entity
    if selected_entity == entity, do: "bg-cyan-500 ml-4 w-[7rem]", else: " ml-3 bg-stone-200 w-[7.2rem]"
  end

  defp set_size_bg_color(entity, selected_entity) do
    selected_entity = if is_float(selected_entity) == true, do: Float.to_string(selected_entity), else: selected_entity
    if selected_entity == entity, do: "bg-cyan-500 ml-4 w-[5.75rem]", else: " ml-3 bg-stone-200 w-[6rem]"
  end

  defp create_material_categories(materials) do
    most_used = ["1144", "1545", "4140", "4140HT", "GI","DI", "303", "304", "316", "6061"]
    kzoo =
      ["6/6 NATURAL",
      "ACETAL",
      "DELRIN 500 AF (DARK BROWN)",
      "DELRIN 550",
      "DELRIN AF",
      "KEVLAR (LIGHT TAN)",
      "2.5XMC901 (BLACK)",
      "NSM", "NYLON 101",
      "NYOIL FG",
      "ACETRON GP (NATURAL)",
      "ACETAL (BLACK)",
      "ACETRON GP (BLACK)",
      "DELRIN 150 (BLACK)",
      "DELRIN 150 (NATURAL)",
      "GSM",
      "GSM (BLUE)",
      "NYOIL",
      "MC901 (BLUE)",
      "MC901 (BLACK)",
      "TEFLON-15% G.F., 5% M.D."]
      tubing = ["PEEK Tubing", "316 Tubing", "954 Tubing", "GSM Tubing","NSM Tubing", "932 Tubing"]
      rectangle = ["1018 C.F. Rectangle", "17-4 Rectangle", "17-4PH Rectangle", "303 Rectangle", "304 Rectangle", "A-36 Rectangle", "C360 BRASS Rectangle", "4140 Rectangle", "4140  Rectangle", "4140  Rectangle", "4140HT Rectangle", "6061 Rectangle", "932 Rectangle"]
    groups = [
      %{
        name: "Primary",
        materials: Enum.filter(materials, &(&1.material in most_used)) |> Enum.sort_by(& &1.material, :asc)
      },
      %{
        name: "Main Saws",
        materials: Enum.filter(materials, fn material ->
          not (material.material in (most_used ++ kzoo ++ tubing ++ rectangle))
        end)
        |> Enum.sort_by(&(&1.material), :asc) |> Enum.sort_by(& &1.mat_reqs_count, :desc)
      },
      %{
        name: "Kzoo",
        materials: Enum.filter(materials, &(&1.material in kzoo)) |> Enum.sort_by(& &1.mat_reqs_count, :desc)
      },
      %{
        name: "Tubing",
        materials: Enum.filter(materials, &(&1.material in tubing)) |> Enum.sort_by(& &1.mat_reqs_count, :desc)
      },
      %{
        name: "Rectangle",
        materials: Enum.filter(materials, &(&1.material in rectangle)) |> Enum.sort_by(& &1.mat_reqs_count, :desc)
      }
    ]

    # Add an index to each group for tracking collapse state
    Enum.with_index(groups)
  end

end
