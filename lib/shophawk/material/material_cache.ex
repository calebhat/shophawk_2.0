defmodule Shophawk.MaterialCache do
  alias Shophawk.Jobboss_db
  alias Shophawk.Material
  #Used for all loading of ETS Caches related to the Material

  def create_material_cache() do
    #Create bare bones list for material cache and save to cache
    {material_list, jobboss_material_info} = create_barebones_material_list()
    :ets.insert(:material_list, {:data, material_list})

    #load all data needed
    mat_reqs = Jobboss_db.load_material_requirements()
    all_jb_material_info = Enum.map(jobboss_material_info, fn mat -> mat.material end) |> Jobboss_db.load_all_jb_material_on_hand()
    all_material_on_floor = Material.list_stocked_materials_on_floor_and_to_order

    #Reduce through material, save info, and assign jobs
    updated_material_list =
      Enum.map(material_list, fn mat ->
        material_name = List.first(mat.sizes).material_name
        matching_mat_reqs = Enum.reduce(mat_reqs, [], fn req, acc -> if String.ends_with?(req.material, material_name), do: [req | acc], else: acc end)
        mat = Map.put(mat, :mat_reqs_count, Enum.count(matching_mat_reqs))
        #matching_mat_reqs = Enum.reduce(mat_reqs, [], fn req, acc -> if String.ends_with?(req.material, material_name), do: [req | acc], else: acc end)

        sizes =
          Enum.map(mat.sizes, fn s ->
            material_name = s.material_name
            [size, _material] = String.split(s.material_name, "X", parts: 2)

            #Load all matching data for material and size
            matching_size_reqs =
              Enum.reduce(matching_mat_reqs, [], fn req, acc ->
                case String.split(req.material, "X", parts: 2) do
                  [size_to_find, _material] -> if size_to_find == size, do: [req | acc], else: acc
                  _ -> acc
                end
              end)

            matching_material = Enum.filter(all_material_on_floor, fn floor_mat -> floor_mat.material == material_name end)

            matching_material_on_floor_or_being_quoted_or_on_order = Enum.filter(matching_material, fn mat -> mat.in_house == true || mat.being_quoted == true || mat.ordered ==  true end)
            matching_material_to_order = Enum.reject(matching_material, fn mat -> mat.in_house == true || mat.being_quoted == true || mat.ordered == true end)


            matching_jobboss_material_info =
              case Enum.find(all_jb_material_info, fn info -> info.material_name == material_name end) do
                nil -> %{material_name: material_name, location_id: "", on_hand_qty: 0.0}
                found_info -> %{material_name: found_info.material_name, location_id: found_info.location_id, on_hand_qty: found_info.on_hand_qty}
              end

              #variables going into the function are correct. Something is wrong with how the list of being saved I think.
              populate_single_material_size(s, material_name, matching_size_reqs, matching_material_on_floor_or_being_quoted_or_on_order, matching_material_to_order, matching_jobboss_material_info)

          end)
        Map.put(mat, :sizes, sizes)
      end)
    :ets.insert(:material_list, {:data, updated_material_list})
    updated_material_list
  end

  def create_barebones_material_list() do
    jobboss_material_info = Shophawk.Jobboss_db.load_materials_and_sizes()

    material_list =
      Enum.reduce(jobboss_material_info, [], fn mat, acc ->
        case String.split(mat.material, "X", parts: 2) do
          [_] -> acc
          [size, material] ->
            case Enum.find(acc, fn m -> m.material == material end) do
              nil -> # New material/size not in list already
                [%{
                  material: material,
                  mat_reqs_count: nil,
                  sizes: [
                    %{
                      size: convert_string_to_float(size),
                      jobs_using_size: nil,
                      matching_jobs: nil,
                      material_name: mat.material,
                      location_id: nil,
                      on_hand_qty: nil,
                      need_to_order_amt: nil,
                      assigned_material_info: nil
                    }
                  ]
                } | acc]

              found_material -> # Add new sizes to existing material in list
                updated_map = Map.update!(found_material, :sizes, fn existing_sizes ->
                  [
                    %{
                      size: convert_string_to_float(size),
                      jobs_using_size: nil,
                      matching_jobs: nil,
                      material_name: mat.material,
                      location_id: nil,
                      on_hand_qty: nil,
                      need_to_order_amt: nil,
                      assigned_material_info: nil
                    } | existing_sizes
                  ]
                end)
                updated_acc = Enum.reject(acc, fn m -> m.material == found_material.material end)
                [updated_map | updated_acc]
            end

          _ -> acc
        end
      end)
      |> Enum.map(fn material ->
        Map.put(material, :sizes, Enum.sort_by(material.sizes, & &1.size, :asc))
      end)
      |> Enum.uniq_by(&(&1.material))
      |> Enum.sort_by(&(&1.material), :asc)
    {material_list, jobboss_material_info}
  end

  def populate_single_material_size(s, material, mat_reqs, material_on_floor, matching_material_to_order, material_info) do
    #Delete material to order so it's always just one that reset in this function
    Enum.each(matching_material_to_order, fn mat ->
      Material.delete_stocked_material(mat)
    end)

    #material = full material name: "2x1545"
    #mat_reqs = list of job requirements for said material
    #material_on_floor = bars/slugs in house
    #material_info = info from jobboss including jobboss stock amount
    [size, _material_name] = String.split(s.material_name, "X", parts: 2)

    jobs_to_assign =
      Enum.map(mat_reqs, fn job ->
        %{job: job.job, length: Float.round((job.part_length + 0.05), 2), make_qty: job.make_quantity, cutoff: job.cutoff, mat: material, size: size}
      end)
      |> Enum.sort_by(&(&1.make_qty), :desc)

    {assigned_material_info, need_to_order_amt} = assign_jobs_to_material(jobs_to_assign, material_on_floor, material)

    #IO.inspect(mat_reqs)
    #remove any empty job_assignments
    assigned_material_info =
      Enum.reduce(assigned_material_info, [], fn bar, acc -> if bar.job_assignments != [], do: [bar.job_assignments | acc], else: acc end)
      |> List.flatten
    matching_jobs = Enum.map(mat_reqs, fn mat -> %{job: mat.job, qty: mat.est_qty, part_length: mat.part_length, make_qty: mat.make_quantity, due_date: mat.due_date, uofm: mat.uofm} end) |> Enum.sort_by(&(&1.qty), :asc)


      %{
      size: convert_string_to_float(size),
      jobs_using_size: Enum.count(mat_reqs),
      matching_jobs: matching_jobs,
      material_name: material_info.material_name,
      location_id: material_info.location_id,
      on_hand_qty: material_info.on_hand_qty,
      need_to_order_amt: need_to_order_amt,
      assigned_material_info: assigned_material_info
      }
  end

  #Updates one size and saves updated material_list in cache
  def update_single_material_size_in_cache(material_name) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    updated_material_list =
      Enum.map(material_list, fn mat ->
        sizes =
          Enum.map(mat.sizes, fn s ->
            case s.material_name == material_name do
              true ->
                matching_size_reqs = Jobboss_db.load_single_material_requirements(material_name)

                matching_material = Material.list_stocked_material_by_material(material_name)
                matching_material_on_floor_or_being_quoted_or_on_order = Enum.filter(matching_material, fn mat -> mat.in_house == true || mat.being_quoted == true || mat.ordered ==  true end)
                matching_material_to_order = Enum.reject(matching_material, fn mat -> mat.in_house == true || mat.being_quoted == true || mat.ordered == true end)

                matching_jobboss_material_info = Jobboss_db.load_all_jb_material_on_hand([material_name]) |> List.first()

                updated_matching_jobboss_material_info =
                  case matching_jobboss_material_info do
                    nil -> %{material_name: material_name, location_id: "", on_hand_qty: 0.0}
                    found_info -> %{material_name: found_info.material_name, location_id: found_info.location_id, on_hand_qty: found_info.on_hand_qty}
                  end

                populate_single_material_size(s, material_name, matching_size_reqs, matching_material_on_floor_or_being_quoted_or_on_order, matching_material_to_order, updated_matching_jobboss_material_info)
              _ ->
                s
            end
          end)
        Map.put(mat, :sizes, sizes)
      end)

    :ets.insert(:material_list, {:data, updated_material_list})
    updated_material_list
  end

  def convert_string_to_float(string) do
    string = if String.at(string, 0) == ".", do: "0" <> string, else: string
    elem(Float.parse(string), 0)
  end

  def assign_jobs_to_material(jobs, material_on_floor, material) do
    if material_on_floor != [] do
      updated_material_on_floor =
        Enum.map(material_on_floor, fn map ->
          case map.bar_length do
            nil -> Map.put(map, :remaining_length_not_assigned, 0.0)
            _ -> Map.put(map, :remaining_length_not_assigned, map.bar_length)
          end
        end)
      {materials, remaining_jobs} =
        Enum.reduce(jobs, {updated_material_on_floor, []}, fn job, {materials, remaining_jobs} ->
          sawed_length = Float.round((job.length + job.cutoff + 0.1), 2)
          # Use slugs within .25" of length
          {materials, remaining_qty} = assign_to_slugs(materials, job)

          # Assign to Bars
          {materials, remaining_qty} =
            if remaining_qty > 0 do
              job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: remaining_qty}
              assign_to_bars(materials, job_that_needs_sawing)
            else
              {materials, remaining_qty}
            end

          # Assign to any long slugs
          {materials, remaining_qty} =
            if remaining_qty > 0 do
              longer_slugs_needed = Map.put(job, :make_qty, remaining_qty)
              last_resort_assign_to_slugs(materials, longer_slugs_needed)
            else
              {materials, remaining_qty}
            end

          #update the job mat req and save to use for other bars/create bar to order
          remaining_jobs =
            if remaining_qty > 0 do
              remaining_jobs ++ [Map.put(job, :make_qty, remaining_qty)]
            else
              remaining_jobs
            end
          {materials, remaining_jobs}
        end)


      length_needed_to_order = Enum.reduce(remaining_jobs, 0.0, fn job, acc ->
        ((job.length + job.cutoff + 0.1) * job.make_qty) + acc
      end)
      bar_to_order =
        if length_needed_to_order > 0.0 do
          [Material.create_stocked_material(%{material: material, bar_length: "#{length_needed_to_order}", in_house: false, remaining_length_not_assigned: "#{length_needed_to_order}"})
          |> elem(1)]
        else
          []
        end
      material_with_bar_to_order = bar_to_order ++ materials


      materials =
        Enum.reduce(remaining_jobs, material_with_bar_to_order, fn job, material ->
          sawed_length = Float.round((job.length + job.cutoff + 0.1), 2)
          #add cutoff and blade width for cutting
          job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: job.make_qty}

          {assigned_bars, _remaining_qty} = assign_to_bars(material, job_that_needs_sawing)
          assigned_bars
        end)

      materials = assign_percentage_used_to_bars(materials)
      {materials, Float.round(length_needed_to_order, 2)}

    else #if no stocked material assign_to_bars
      length_needed_to_order =
        Enum.reduce(jobs, 0.0, fn job, acc ->
          ((job.length + job.cutoff + 0.1) * job.make_qty) + acc
        end)
      bar_to_order =
        if length_needed_to_order > 0.0 do
          [Material.create_stocked_material(%{material: material, bar_length: "#{length_needed_to_order}", in_house: false, remaining_length_not_assigned: "#{length_needed_to_order}"})
          |> elem(1)]
        else
          []
        end
      assigned_bars =
        Enum.reduce(jobs, bar_to_order, fn job, materials ->
          sawed_length = Float.round((job.length + job.cutoff + 0.1), 2)
          #add cutoff and blade width for cutting
          job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: job.make_qty}

          {assigned_bars, _remaining_qty} = assign_to_bars(materials, job_that_needs_sawing)
          assigned_bars
        end)

        #calculate length needed to order at the end
      assigned_bars = assign_percentage_used_to_bars(assigned_bars)
      {assigned_bars, Float.round(length_needed_to_order, 2)}
    end
  end

  defp assign_percentage_used_to_bars(assigned_bars) do
    Enum.map(assigned_bars, fn bar ->
      case bar.bar_length do
        nil -> bar
        _ ->
          {updated_map, _cumulative_percentage} =
            Enum.reduce(bar.job_assignments, {[], 0.0}, fn map, {acc, cumulative_percentage} ->
              percentage_of_bar = map.length_to_use / bar.bar_length * 100.0
              updated_assignments =
                Map.put(map, :percentage_of_bar, percentage_of_bar)
                |> Map.put(:left_offset, cumulative_percentage)
              {acc ++ [updated_assignments], cumulative_percentage + percentage_of_bar}
            end)
          Map.put(bar, :job_assignments, updated_map)
      end
    end)
  end

  defp assign_to_slugs(materials, %{length: length_needed, make_qty: make_qty, job: job_id}) do
    materials
    |> Enum.sort_by(fn
      %{slug_length: nil} -> :infinity  # Treat nil as the furthest distance
      %{slug_length: slug_length} -> abs(slug_length - length_needed)
    end)
    |> Enum.reduce_while({[], make_qty}, fn material, {acc, remaining_qty} ->
      #if slug is withing .25" of length needed, assign to slug
      if material.slug_length >= (length_needed + 0.03) and material.slug_length <= (length_needed + 0.25) do
        assignments = Map.get(material, :job_assignments, [])
        slugs_available_to_use =
          case assignments do
            [] -> material.number_of_slugs
            list ->
              slugs_used = Enum.reduce(list, 0.0, fn x, acc -> x.slug_qty + acc end)
              material.number_of_slugs - slugs_used
          end
        if slugs_available_to_use > 0 do
          updated_assignments = [%{material_id: material.id, job: job_id, slug_qty: min(remaining_qty, material.number_of_slugs), length_to_use: 0.0, parts_from_bar: 0} | assignments]
          remaining_qty = max(0, remaining_qty - material.number_of_slugs)

          updated_material = Map.put(material, :job_assignments, updated_assignments)
          {:cont, {[updated_material | acc], remaining_qty}}
        else
          {:cont, {[material | acc], remaining_qty}}
        end
      else
        {:cont, {[material | acc], remaining_qty}}
      end
    end)
  end

  defp assign_to_bars(materials, %{job: job, sawed_length: sawed_length, remaining_qty: remaining_qty}) do
    Enum.reduce(materials, {[], remaining_qty}, fn material, {acc, remaining_qty} ->
      if remaining_qty <= 0 do
        # Keep including all materials after remaining_qty is depleted
        {[material | acc], remaining_qty}
      else
        # Skip material that is fully used or cannot satisfy even one part
        if material.remaining_length_not_assigned >= sawed_length do
          assignments = Map.get(material, :job_assignments, [])

          parts_from_bar = min(remaining_qty, floor(material.remaining_length_not_assigned / sawed_length))
          length_to_use = Float.round(sawed_length * parts_from_bar, 2)
          remaining_qty = max(0, remaining_qty - parts_from_bar)

          remaining_length_not_assigned = Float.round(material.remaining_length_not_assigned - length_to_use, 2)

          updated_assignments = [%{material_id: material.id, job: job, length_to_use: length_to_use, parts_from_bar: parts_from_bar, slug_qty: 0} | assignments]
          updated_material =
            material
            |> Map.put(:job_assignments, updated_assignments)
            |> Map.put(:remaining_length_not_assigned, remaining_length_not_assigned)

          {[updated_material | acc], remaining_qty}
        else
          {[material | acc], remaining_qty} # Move on to the next material
        end
      end
    end)
  end

  #DOES THIS LOOK AT MULTIPLE PARTS PER SLUG?
  defp last_resort_assign_to_slugs(materials, %{length: length_needed, make_qty: make_qty, job: job_id}) do
    Enum.reduce_while(materials, {[], make_qty}, fn material, {acc, remaining_qty} ->
      #if slug is withing .25" of length needed, assign to slug
      if material.slug_length != nil do
        if material.slug_length >= length_needed do
          assignments = Map.get(material, :job_assignments, [])
          slugs_left =
            case assignments do
              [] -> material.number_of_slugs
              list ->
                slugs_used = Enum.reduce(list, 0.0, fn x, acc -> x.slug_qty + acc end)
                material.number_of_slugs - slugs_used
            end
          if slugs_left > 0 do
            updated_assignments = [%{material_id: material.id, job: job_id, slug_qty: min(remaining_qty, material.number_of_slugs), length_to_use: 0.0, parts_from_bar: 0} | assignments]
            remaining_qty = max(0, remaining_qty - material.number_of_slugs)

            updated_material = Map.put(material, :job_assignments, updated_assignments)
            {:cont, {[updated_material | acc], remaining_qty}}
          else
            {:cont, {[material | acc], remaining_qty}}
          end
        else
          {:cont, {[material | acc], remaining_qty}}
        end
      else
        {:cont, {[material | acc], remaining_qty}}
      end
    end)
  end

end
