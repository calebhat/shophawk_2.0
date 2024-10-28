defmodule Shophawk.MaterialCache do
  alias Shophawk.Jobboss_db
  alias Shophawk.Material
  #Used for all loading of ETS Caches related to the Material

  def load_all_material_and_sizes() do
    material = Shophawk.Jobboss_db.load_materials_and_sizes()
    mat_reqs = Jobboss_db.load_material_requirements()
    all_jb_material_info =
      Enum.map(material, fn mat -> mat.material end)
      |> Jobboss_db.load_all_jb_material_on_hand()
    all_material_on_floor = Material.list_stocked_materials_on_floor_and_to_order

    round_stock = Enum.reduce(material, [], fn mat, acc ->
      case String.split(mat.material, "X", parts: 2) do
        [_] -> acc
        [size, material] ->
          matching_mat_reqs = Enum.reduce(mat_reqs, [], fn req, acc -> if String.ends_with?(req.material, material), do: [req | acc], else: acc end)
          matching_size_reqs = Enum.reduce(matching_mat_reqs, [], fn req, acc ->
            matching_size = case String.split(req.material, "X", parts: 2) do
              [size_to_find, _material] -> if size_to_find == size, do: [req | acc], else: acc
              _ -> acc
            end
          end)
          matching_material_on_floor = Enum.filter(all_material_on_floor, fn floor_mat -> floor_mat.material == mat.material end)


          jobs_to_assign =
            Enum.map(matching_size_reqs, fn job ->
              %{job: job.job, length: Float.round((job.part_length + 0.05), 2), make_qty: job.make_quantity, cutoff: job.cutoff, mat: material, size: size}
            end)
            |> Enum.sort_by(&(&1.make_qty), :desc)

          #WORKS
          #need to update material or make map with list of %{material, size, length needed} for ordering page
          {assigned_material_info, need_to_order_amt} = assign_jobs_to_material(jobs_to_assign, matching_material_on_floor, mat.material)
          assigned_material_info =
            Enum.reduce(assigned_material_info, [], fn bar, acc -> if bar.job_assignments != [], do: [bar.job_assignments | acc], else: acc end)
            |> List.flatten
          matching_jobs = Enum.map(matching_size_reqs, fn mat -> %{job: mat.job, qty: mat.est_qty} end) |> Enum.sort_by(&(&1.qty), :asc)
          material_info =
            case Enum.find(all_jb_material_info, fn mat_info -> mat_info.material_name == mat.material end) do
              nil ->  %{material_name: mat.material, location_id: "", on_hand_qty: 0.0}
              found_mat_info -> found_mat_info
            end
          case Enum.find(acc, fn mat -> mat.material == material end) do
            nil -> #new material/size not in list already
              [%{
                material: material,
                mat_reqs_count: Enum.count(matching_mat_reqs),
                sizes:
                  [%{size: convert_string_to_float(size),
                  jobs_using_size: Enum.count(matching_size_reqs),
                  matching_jobs: matching_jobs,
                  material_name: material_info.material_name,
                  location_id: material_info.location_id,
                  on_hand_qty: material_info.on_hand_qty,
                  need_to_order_amt: need_to_order_amt,
                  assigned_material_info: assigned_material_info}]
                } | acc]
            found_material -> #add new sizes to existing material in list.
              updated_map =
                Map.update!(found_material, :sizes, fn existing_sizes ->
                  [
                    %{size: convert_string_to_float(size),
                    jobs_using_size: Enum.count(matching_size_reqs),
                    matching_jobs: matching_jobs,
                    material_name: material_info.material_name,
                    location_id: material_info.location_id,
                    on_hand_qty: material_info.on_hand_qty,
                    need_to_order_amt: need_to_order_amt,
                    assigned_material_info: assigned_material_info
                    } | existing_sizes]
                  end)
              updated_acc = Enum.reject(acc, fn mat -> mat.material == found_material.material end) #removes previous material for replacement with updated_map
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
  end


  #Updates one size and saves updated material_list in cache
  def load_specific_material_and_size_into_cache(material, socket) do
    [size, material_name] = String.split(material, "X", parts: 2)
    mat_reqs = Jobboss_db.load_single_material_requirements(material)
    material_on_floor = Material.list_stocked_material_by_material(material) |> Enum.reject(fn mat -> mat.in_house == false end)
    material_info = Jobboss_db.load_all_jb_material_on_hand([material]) |> List.first()
    jobs_to_assign =
      Enum.map(mat_reqs, fn job ->
        %{job: job.job, length: Float.round((job.part_length + 0.05), 2), make_qty: job.make_quantity, cutoff: job.cutoff, mat: material, size: size}
      end)
      |> Enum.sort_by(&(&1.make_qty), :desc)

    {assigned_material_info, need_to_order_amt} = new_assign_jobs_to_material(jobs_to_assign, material_on_floor, material)

    assigned_material_info =
      Enum.reduce(assigned_material_info, [], fn bar, acc -> if bar.job_assignments != [], do: [bar.job_assignments | acc], else: acc end)
      |> List.flatten
    matching_jobs = Enum.map(mat_reqs, fn mat -> %{job: mat.job, qty: mat.est_qty} end) |> Enum.sort_by(&(&1.qty), :asc)

    material_to_insert_into_material_list =
      Enum.reduce(material_on_floor, [], fn mat, acc ->
        case Enum.find(acc, fn mat -> mat.material == material_name end) do
          nil -> # New material/size not in list already
            [%{
              material: material_name,
              mat_reqs_count: Enum.count(mat_reqs),
              sizes: [%{
                size: convert_string_to_float(size),
                jobs_using_size: Enum.count(mat_reqs),
                matching_jobs: matching_jobs,
                material_name: material_info.material_name,
                location_id: material_info.location_id,
                on_hand_qty: material_info.on_hand_qty,
                need_to_order_amt: need_to_order_amt,
                assigned_material_info: assigned_material_info
              }]
            } | acc]
          found_material -> # Add new sizes to existing material in list
            updated_map =
              Map.update!(found_material, :sizes, fn existing_sizes ->
                [
                  %{
                    size: convert_string_to_float(size),
                    jobs_using_size: Enum.count(mat_reqs),
                    matching_jobs: matching_jobs,
                    material_name: material_info.material_name,
                    location_id: material_info.location_id,
                    on_hand_qty: material_info.on_hand_qty,
                    need_to_order_amt: need_to_order_amt,
                    assigned_material_info: assigned_material_info
                  } | existing_sizes
                ]
              end)

            updated_acc = Enum.reject(acc, fn mat -> mat.material == found_material.material end)
            [updated_map | updated_acc]
        end
    end)
    |> Enum.map(fn material ->
      Map.put(material, :sizes, Enum.sort_by(material.sizes, & &1.size, :asc))
    end)
    |> Enum.uniq_by(&(&1.material))
    |> Enum.sort_by(&(&1.material), :asc)


    replacement_size_info = List.first(material_to_insert_into_material_list).sizes |> List.first()
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    updated_material_list =
      Enum.map(material_list, fn mat ->
        if mat.material == material_name do
          updated_sizes =
            Enum.map(mat.sizes, fn size ->
              if size.material_name == material do
                replacement_size_info
              else
                size
              end
            end)
            #|> Enum.sort_by(& &1.size, :asc)  # Sort the sizes by the `size` field
          %{mat | sizes: updated_sizes}
        else
          mat
        end
      end)

    :ets.insert(:material_list, {:data, updated_material_list})
    updated_material_list
  end

  def convert_string_to_float(string) do
    string = if String.at(string, 0) == ".", do: "0" <> string, else: string
    elem(Float.parse(string), 0)
  end

  def new_assign_jobs_to_material(jobs, material_on_floor, material) do
    if material_on_floor != [] do
      updated_material_on_floor = Enum.map(material_on_floor, fn map -> Map.put(map, :remaining_length_not_assigned, map.bar_length) end)
      {materials, length_needed_to_order} =
        Enum.reduce(jobs, {updated_material_on_floor, 0.0}, fn job, {materials, length_needed_to_order} ->
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

          # Calculate length needed to order new material
          length_needed_to_order = Float.round((remaining_qty * sawed_length) + length_needed_to_order, 2)


          #update bar to order with new value, leaving the bars in house alone.
          materials =
            if length_needed_to_order > 0.0 do #create new bar if needed for ordering
              #find previous bar to order if any
              IO.inspect(material)
              previous_bar_to_order =
                Material.list_stocked_material_by_material(material)
                |> Enum.find(fn mat -> mat.in_house == false && mat.being_quoted == false && mat.ordered == false end)

              previous_bar_length = if previous_bar_to_order == nil, do: 0.0, else: previous_bar_to_order.bar_length
              previous_bar_assignments = if previous_bar_to_order == nil, do: %{}, else: previous_bar_to_order.job_assignments
              #create a new bar to order add the previous length to order
              bar_to_order =
                if previous_bar_to_order == nil do
                  Material.create_stocked_material(%{material: material, bar_length: length_needed_to_order + previous_bar_length, in_house: false, remaining_length_not_assigned: length_needed_to_order}) |> elem(1)
                else
                  Material.update_stocked_material(previous_bar_to_order, %{bar_length: length_needed_to_order, remaining_length_not_assigned: length_needed_to_order}) |> elem(1)
                end

              job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: remaining_qty}
              #assign current job to bar
              {assigned_bar_to_order, remaining_qty} = assign_to_bars([bar_to_order], job_that_needs_sawing)
              assigned_bar_to_order = List.first(assigned_bar_to_order)
              #merge previous bar to order assignments to bar
              merged_assignments =
                if previous_bar_to_order == nil do
                  assigned_bar_to_order.job_assignments
                else
                  [assigned_bar_to_order.job_assignments | previous_bar_assignments]
                end
                |> List.flatten
              assigned_and_merged_bar_to_order = Map.put(assigned_bar_to_order, :job_assignments, merged_assignments)

              [assigned_and_merged_bar_to_order | materials]
            else
              previous_bar_to_order =
                Material.list_stocked_material_by_material(material)
                |> Enum.find(fn mat -> mat.in_house == false && mat.being_quoted == false && mat.ordered == false end)
              if previous_bar_to_order != nil, do: Material.delete_stocked_material(previous_bar_to_order)
              materials
            end

          {materials, length_needed_to_order}
        end)
      materials = assign_used_material_percentages(materials)
      {materials, length_needed_to_order}
    else #if no stocked materialassign_to_bars
      length_needed_to_order = Enum.reduce(jobs, 0.0, fn job, acc ->
        ((job.length + job.cutoff + 0.1) * job.make_qty) + acc
      end)
      bar_to_order = if length_needed_to_order > 0.0, do: [create_new_stocked_material_to_order([], length_needed_to_order, material)], else: []

      assigned_bars =
        Enum.reduce(jobs, bar_to_order, fn job, materials ->
          sawed_length = Float.round((job.length + job.cutoff + 0.1), 2)
          #add cutoff and blade width for cutting
          job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: job.make_qty}

          {assigned_bars, _remaining_qty} = assign_to_bars(materials, job_that_needs_sawing)

          assigned_bars
        end)

      assigned_bars = assign_used_material_percentages(assigned_bars)
      {assigned_bars, Float.round(length_needed_to_order, 2)}
    end
  end

  def assign_jobs_to_material(jobs, stocked_materials, material_name) do
    if stocked_materials != [] do
      Enum.reduce(jobs, {stocked_materials, 0.0}, fn job, {materials, length_needed_to_order} ->
        sawed_length = Float.round((job.length + job.cutoff + 0.1), 2)

        #use slugs within .25" of length
        {materials_with_slugs, remaining_qty} = assign_to_slugs(materials, job)
        #assign to Bars
        {materials_with_bars, remaining_qty} =
          if remaining_qty > 0 do
            #add cutoff and blade width for cutting
            job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: remaining_qty}
            assign_to_bars(materials_with_slugs, job_that_needs_sawing)
          else
            {materials_with_slugs, remaining_qty}
          end
        #assign to any long slugs
        {assigned_bars, remaining_qty} =
          if remaining_qty > 0 do #use longer slugs if nothing else works
            #revert to length without saw cuts
            longer_slugs_needed = Map.put(job, :make_qty, remaining_qty)
            last_resort_assign_to_slugs(materials_with_bars, longer_slugs_needed)
          else
            {materials_with_bars, remaining_qty}
          end
        length_needed_to_order = Float.round((remaining_qty * sawed_length) + length_needed_to_order, 2)

        assigned_bars =
          if length_needed_to_order > 0.0 do
            bar_to_order = create_new_stocked_material_to_order(assigned_bars, length_needed_to_order, material_name)
            assigned_bars = Enum.reject(assigned_bars, fn bar -> bar.in_house && bar.ordered == false end)
            job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: remaining_qty}
            assign_to_bars(assigned_bars, job_that_needs_sawing)
            [bar_to_order | assigned_bars]
          else
            assigned_bars
          end

        assigned_bars = assign_used_material_percentages(assigned_bars)
        {assigned_bars, length_needed_to_order}
      end)
    else #if no stocked material
      length_needed_to_order = Enum.reduce(jobs, 0.0, fn job, acc ->
        ((job.length + job.cutoff + 0.1) * job.make_qty) + acc
      end)
      bar_to_order = if length_needed_to_order > 0.0, do: [create_new_stocked_material_to_order([], length_needed_to_order, material_name)], else: []

      assigned_bars =
        Enum.reduce(jobs, bar_to_order, fn job, materials ->
          sawed_length = Float.round((job.length + job.cutoff + 0.1), 2)
          #add cutoff and blade width for cutting
          job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: job.make_qty}

          {assigned_bars, _remaining_qty} = assign_to_bars(materials, job_that_needs_sawing)

          assigned_bars
        end)

      assigned_bars = assign_used_material_percentages(assigned_bars)
      {assigned_bars, Float.round(length_needed_to_order, 2)}
    end
  end

  defp assign_used_material_percentages(assigned_bars) do
    Enum.map(assigned_bars, fn bar ->
      {updated_map, _cumulative_percentage} =
        Enum.reduce(bar.job_assignments, {[], 0.0}, fn map, {acc, cumulative_percentage} ->
          percentage_of_bar = map.length_to_use / bar.bar_length * 100.0
          left_offset =
          updated_assignments =
            Map.put(map, :percentage_of_bar, percentage_of_bar)
            |> Map.put(:left_offset, cumulative_percentage)
          {acc ++ [updated_assignments], cumulative_percentage + percentage_of_bar}
        end)
      Map.put(bar, :job_assignments, updated_map)
    end)
  end

  defp create_new_stocked_material_to_order(assigned_bars, length_needed_to_order, material_name) do
    case Enum.find(assigned_bars, fn bar -> bar.in_house == false end) do
      nil -> Material.create_stocked_material(%{material: material_name, bar_length: "#{length_needed_to_order}", in_house: false}) |> elem(1)
      bar -> Map.put(bar, :bar_length, (bar.bar_length + length_needed_to_order) |> Float.round(2)) #add length to existing bar
    end
  end

  defp assign_to_slugs(materials, %{length: length_needed, make_qty: make_qty, job: job_id}) do
    Enum.reduce_while(materials, {[], make_qty}, fn material, {acc, remaining_qty} ->
      #if slug is withing .25" of length needed, assign to slug
      if material.slug_length >= length_needed and material.slug_length <= (length_needed + 0.25) do
        assignments = Map.get(material, :job_assignments, [])
        slugs_left =
          case assignments do
            [] -> 0
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
    end)
  end

  defp assign_to_bars(materials, %{job: job, sawed_length: sawed_length, remaining_qty: remaining_qty}) do
    Enum.reduce_while(materials, {[], remaining_qty}, fn material, {acc, remaining_qty} ->
      if remaining_qty == 0 do
        {:halt, {acc, remaining_qty}} # Stop if no more quantity is needed
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

          {:cont, {[updated_material | acc], remaining_qty}}
        else
          {:cont, {[material | acc], remaining_qty}} # Move on to the next material
        end
      end
    end)
  end



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
