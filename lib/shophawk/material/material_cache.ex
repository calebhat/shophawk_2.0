defmodule Shophawk.MaterialCache do
  alias Shophawk.Jobboss_db
  alias Shophawk.Material
  import Number.Currency
  #Used for all loading of ETS Caches related to the Material

  def create_material_cache() do
    #Create bare bones list for material cache and save to cache
    {material_list, jobboss_material_info} = create_barebones_material_list()
    :ets.insert(:material_list, {:data, material_list})

    #load all data needed
    mat_reqs = Jobboss_db.load_material_requirements()
    year_history = Jobboss_db.load_year_history_of_material_requirements()
    all_material_not_used = Material.list_material_not_used
    all_material_purchased_in_past_12_months = Material.list_stockedmaterials_last_12_month_entries()
    jb_material_on_hand_qty =
      Enum.map(jobboss_material_info, fn mat -> mat.material end)
      |> Jobboss_db.load_all_jb_material_on_hand()
    all_jb_material_info =
      Enum.map(jb_material_on_hand_qty, fn mat ->
        jb_info = Enum.find(jobboss_material_info, fn mat_info -> mat_info.material == mat.material_name end)
        case jb_info do
          nil -> Map.put(mat, :lbs_per_inch, 0.0) |> Map.put(:cost_uofm, 0.0) |> Map.put(:standard_cost, 0.0)
          found_info -> Map.put(mat, :lbs_per_inch, Float.round(found_info.is_weight_factor, 2)) |> Map.put(:cost_uofm, found_info.cost_uofm) |> Map.put(:standard_cost, found_info.standard_cost)
        end
      end)



    #Reduce through material, save info, and assign jobs
    updated_material_list =
      Enum.map(material_list, fn mat ->
        #material_name = List.first(mat.sizes).material_name
        #matching_mat_reqs = Enum.reduce(mat_reqs, [], fn req, acc -> if String.ends_with?(req.material, material_name), do: [req | acc], else: acc end)
        #This is not correct here
        #mat = Map.put(mat, :mat_reqs_count, Enum.count(matching_mat_reqs))

        sizes =
          Enum.map(mat.sizes, fn s ->
            material_name = s.material_name

            #Load all matching data for material and size
            matching_size_reqs = Enum.filter(mat_reqs, fn req -> req.material == s.material_name end)

            matching_material = Enum.filter(all_material_not_used, fn floor_mat -> floor_mat.material == material_name end)

            matching_material_on_floor_or_being_quoted_or_on_order = Enum.filter(matching_material, fn mat -> mat.in_house == true || mat.being_quoted == true || mat.ordered ==  true end)
            matching_material_to_order = Enum.reject(matching_material, fn mat -> mat.in_house == true || mat.being_quoted == true || mat.ordered == true end)


            matching_jobboss_material_info =
              case Enum.find(all_jb_material_info, fn info -> info.material_name == material_name end) do
                nil ->
                  %{material_name: material_name,
                  location_id: "",
                  on_hand_qty: 0.0,
                  lbs_per_inch: 0.0,
                  past_years_usage: 0.0,
                  purchase_price: 0.0,
                  sell_price: 0.0,
                  cost_per_inch: number_to_currency(0.0),
                  cost_uofm: 0.0,
                  standard_cost: 0.0
                  }
                found_info ->
                  matching_material_on_floor = Enum.filter(matching_material, fn mat -> mat.in_house == true && mat.being_quoted == false && mat.ordered ==  false end)
                  total_material_on_hand = Enum.reduce(matching_material_on_floor, 0.0, fn m, acc ->
                    case m.bar_length do
                      nil -> acc
                      length -> length + acc
                    end
                  end) / 12

                  material_year_history = Enum.filter(year_history, fn m -> m.material == found_info.material_name end) |> Enum.reduce(0.0, fn m, acc -> m.act_qty + acc end)

                  year_Purchases_history = Enum.filter(all_material_purchased_in_past_12_months, fn mat -> mat.material == found_info.material_name end)
                  mat_tuple_list = Enum.map(year_Purchases_history, fn bar -> {bar.original_bar_length, bar.purchase_price} end)
                  total_inches_used = Enum.reduce(mat_tuple_list, 0.0, fn {feet_used, _price}, acc ->
                    case feet_used do
                      nil -> acc
                      value -> acc + value
                    end
                  end)
                  total_weighted_price = Enum.reduce(mat_tuple_list, 0, fn {feet_used, price}, acc -> acc + (feet_used * price) end)
                  average_price = if total_inches_used > 0.0, do: total_weighted_price / total_inches_used, else: 0.0
                  sell_price = if average_price > 0.0, do: Float.ceil(average_price * 1.2 * 4) / 4, else: 0.0

                  %{material_name: found_info.material_name,
                  location_id: found_info.location_id,
                  on_hand_qty: Float.round(total_material_on_hand, 2),
                  lbs_per_inch: found_info.lbs_per_inch,
                  past_years_usage: Float.round(material_year_history, 2),
                  purchase_price: average_price,
                  sell_price: sell_price,
                  cost_per_inch: number_to_currency(sell_price * found_info.lbs_per_inch),
                  cost_uofm: found_info.cost_uofm,
                  standard_cost: number_to_currency(found_info.standard_cost)
                  }
              end


            populate_single_material_size(s, material_name, matching_size_reqs, matching_material_on_floor_or_being_quoted_or_on_order, matching_material_to_order, matching_jobboss_material_info)
          end)

        #add together jobs_using_size for each material
        mat_reqs_count =
          Enum.reduce(sizes, 0, fn size, acc ->
            size.jobs_using_size + acc
          end)

        Map.put(mat, :sizes, sizes)
        |> Map.put(:mat_reqs_count, mat_reqs_count)
      end)

    merged_material_list = merge_materials(updated_material_list)


    :ets.insert(:material_list, {:data, merged_material_list})
    updated_material_list
  end

  def merge_materials(material_list) do
    merge_material(material_list, "4150HT")
    |> merge_material("100-70-03 DI", "DI 100-70-03", ["100-70-03 DI"])
    |> merge_material("1045", "1045", ["1045", "1045 HR", "1045HR", "1045."])
    |> merge_material("1045 G&P", "1045 G&P", ["1045 TG&P", "1045 TP&G", "1045 G&P"])
    |> merge_material("12FT. 1117 CR KNURLED BAR", "Knurled 1117", ["12FT. 1117 CR KNURLED BAR", "12FT 1117CF KNURLED BAR", "12FT.1117 CR KNURLED BAR"])
    |> merge_material("12FT. 1144 CR KNURLED BAR", "Knurled 1144", ["12FT. 1144 CR KNURLED BAR", "12FT. 1545 CR KNURLED BAR", "12FT 1144 CF KNURLED BAR "])
    |> merge_material("17-4PH", "17-4PH", ["17-4", "17-4PH", "17-4PH ", "17-4SS"])
    |> merge_material("304")
    |> merge_material("4140", "4140", ["4140", "4140."])
    |> merge_material("4140CR", "4140CR", ["4140CF", "4140CR"])
    |> merge_material("4140HT C.F.", "4140HT CF", ["4140HT C.F.", "4140HT CR", "4140HTCR"])
    |> merge_material("4140HT G&P", "4140HT G&P", ["4140HT G&P", "4140HT G AND P", "4140HT G & P"])
    |> merge_material("4150HT", "4150HT", ["4150HT", "4150 HT"])
    |> merge_material("416", "416", ["416", "416SS"])
    |> merge_material("416HT", "416HT", ["416HT", "416SSHT", " 416 HT", "416SSHT (C.F.)"])
    |> merge_material("4340", "4340", ["4340", "4340."])
    |> merge_material("440SS", "440SS", ["440SS", "440C", "440"])
    |> merge_material("630BRNZ", "630BRNZ", ["630BRNZ", "6300BRNZ", "630 NI/AL BRNZ"])
    |> merge_material("660BRNZ", "660BRNZ", ["660BRNZ", "660 BRZ", "660BRZ"])
    |> merge_material("6061")
    |> merge_material("7075")
    |> merge_material("8620", "8620", ["8620", "8620 CR", "8620 CF", "8620CR", "8620CD"])
    |> merge_material("903 TIN BRONZE", "903 TIN BRNZ", ["903 TIN BRONZE", "903"])
    |> merge_material("932BRNZ", "932BRNZ", ["932BRNZ", "932"])
    |> merge_material("954 BRNZ", "954 BRNZ", ["954 BRNZ", "954", "954BRNZ", "954BRZ"])

    #Plastics
    |> merge_material("ACETRON GP (NATURAL)", "ACETRON GP (NATURAL)", ["ACETRON GP (NATURAL)", "ACETRON GP"])
    |> merge_material("ACETAL (BLACK)", "ACETAL (BLACK)", ["ACETAL (BLACK)", "ACETAL BLK"])
    |> merge_material("ACETRON GP (BLACK)", "ACETRON GP (BLACK)", ["ACETRON GP (BLACK)", "ACETRON GP BLACK"])
    |> merge_material("DELRIN 150 (BLACK)", "DELRIN 150 (BLACK)", ["DELRIN 150 (BLACK)", "DELRIN (BLACK)"])
    |> merge_material("DELRIN 150 (NATURAL)", "DELRIN 150 (NATURAL)", ["DELRIN 150 (NATURAL)", "DELRIN 150"])
    |> merge_material("GSM", "GSM", ["GSM", "GSM "])
    |> merge_material("GSM (BLUE)", "GSM (BLUE)", ["GSM (BLUE)", "GSM BLUE"])
    |> merge_material("NYOIL", "NYOIL", ["NYOIL", "NYLOIL"])
    |> merge_material("MC901", "MC901 (BLUE)", ["MC901", "MC901 (BLUE)"])
    |> merge_material("TEFLON-15% G.F., 5% M.D.", "TEFLON-15% G.F., 5% M.D.", ["TEFLON-15% G.F., 5% M.D.", "TEFLON - 15% G.F., 5% M.D."])
    |> merge_material("SP", "SP", ["SP", "SP (1144 COLD DRAWN)", "SP (1144)"])
  end

  def merge_material(updated_material_list, mat_to_keep) do
    good_material = Enum.find(updated_material_list, fn mat -> mat.material == mat_to_keep end)
    case good_material do
      nil -> updated_material_list
      _ ->
        grouped_material_list =
          Enum.reduce(updated_material_list, [], fn mat, acc ->
            if String.contains?(mat.material, mat_to_keep) do
              acc ++ [mat.material]
            else
              acc
            end
          end)

        sizes_to_merge =
          Enum.reduce(updated_material_list, [], fn mat, acc ->
            if Enum.member?(grouped_material_list, mat.material) do
              acc ++ mat.sizes
            else
              acc
            end
          end)
          |> Enum.sort_by(fn mat -> mat.size end)

        updated_material =
          Map.put(good_material, :sizes, sizes_to_merge)
          |> Map.put(:mat_reqs_count, Enum.reduce(sizes_to_merge, 0, fn size, acc -> size.jobs_using_size + acc end))

        #remove all occurences of material
        filtered_material_list = Enum.reject(updated_material_list, fn mat -> Enum.member?(grouped_material_list, mat.material) end)
        filtered_material_list ++ [updated_material]
      end
  end

  def merge_material(updated_material_list, mat_to_keep, name_to_use, list_of_materials) do
    good_material = Enum.find(updated_material_list, fn mat -> mat.material == mat_to_keep end)

    case good_material do
      nil -> updated_material_list
      _ ->
        sizes_to_merge =
          Enum.reduce(updated_material_list, [], fn mat, acc ->
            if Enum.member?(list_of_materials, mat.material) do
              acc ++ mat.sizes
            else
              acc
            end
          end)
          |> Enum.sort_by(fn mat -> mat.size end)

        updated_material =
          Map.put(good_material, :material, name_to_use)
          |> Map.put(:sizes, sizes_to_merge)
          |> Map.put(:mat_reqs_count, Enum.reduce(sizes_to_merge, 0, fn size, acc -> size.jobs_using_size + acc end))

        #remove all occurences of material
        filtered_material_list = Enum.reject(updated_material_list, fn mat -> Enum.member?(list_of_materials, mat.material) end)

        filtered_material_list ++ [updated_material]
    end

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
                      lbs_per_inch: nil,
                      purchase_price: nil,
                      sell_price: nil,
                      need_to_order_amt: nil,
                      assigned_material_info: nil,
                      cost_uofm: nil
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
                      purchase_price: nil,
                      sell_price: nil,
                      lbs_per_inch: nil,
                      need_to_order_amt: nil,
                      assigned_material_info: nil,
                      cost_uofm: nil
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

    [size, _material_name] = String.split(s.material_name, "X", parts: 2)

    jobs_to_assign =
      Enum.map(mat_reqs, fn job ->
        %{job: job.job, length: Float.round((job.part_length + 0.05), 2), make_qty: job.make_quantity, cutoff: job.cutoff, mat: material, size: size}
      end)
      |> Enum.sort_by(&(&1.make_qty), :desc)

    {assigned_material_info, need_to_order_amt} = assign_jobs_to_material(jobs_to_assign, material_on_floor, material)

    #remove any empty job_assignments
    assigned_material_info =
      Enum.reduce(assigned_material_info, [], fn bar, acc -> if bar.job_assignments != [], do: [bar.job_assignments | acc], else: acc end)
      |> List.flatten
    matching_jobs = Enum.map(mat_reqs, fn mat ->
      %{job: mat.job, qty: mat.est_qty, part_length: mat.part_length, make_qty: mat.make_quantity, due_date: mat.due_date, uofm: mat.uofm}
    end) |> Enum.sort_by(&(&1.qty), :asc)


    _bar_with_assignments =
      %{
      size: convert_string_to_float(size),
      jobs_using_size: Enum.count(mat_reqs),
      matching_jobs: matching_jobs,
      material_name: material_info.material_name,
      location_id: material_info.location_id,
      on_hand_qty: material_info.on_hand_qty,
      lbs_per_inch: material_info.lbs_per_inch,
      past_years_usage: material_info.past_years_usage,
      purchase_price: material_info.purchase_price,
      sell_price: material_info.sell_price,
      cost_per_inch: material_info.cost_per_inch,
      cost_uofm: material_info.cost_uofm,
      need_to_order_amt: need_to_order_amt,
      assigned_material_info: assigned_material_info
      }
  end

  #Updates one size and saves updated material_list in cache
  def update_single_material_size_in_cache(material_name) do
    [{:data, material_list}] = :ets.lookup(:material_list, :data)
    #material_not_used = Material.list_material_not_used
    updated_material_list =
      Enum.map(material_list, fn mat ->
        sizes =
          Enum.map(mat.sizes, fn s ->
            case s.material_name == material_name do
              true ->
                matching_size_reqs = Jobboss_db.load_single_material_requirements(material_name)

                matching_material = Material.list_material_not_used_by_material(material_name)
                matching_material_on_floor_or_being_quoted_or_on_order = Enum.filter(matching_material, fn mat -> mat.in_house == true || mat.being_quoted == true || mat.ordered ==  true end)
                matching_material_to_order = Enum.reject(matching_material, fn mat -> mat.in_house == true || mat.being_quoted == true || mat.ordered == true end)

                matching_material_on_floor = Enum.filter(matching_material, fn mat -> mat.in_house == true && mat.being_quoted == false && mat.ordered ==  false end)
                total_material_on_hand = Enum.reduce(matching_material_on_floor, 0.0, fn m, acc ->
                  case m.bar_length do
                    nil -> acc
                    length -> length + acc
                  end
                end) / 12
                year_history = Material.list_stockedmaterials_last_12_month_entries(s.material_name)
                mat_tuple_list = Enum.map(year_history, fn bar -> {bar.original_bar_length, bar.purchase_price} end)
                total_inches_used = Enum.reduce(mat_tuple_list, 0.0, fn {feet_used, _price}, acc -> acc + feet_used end)
                total_weighted_price = Enum.reduce(mat_tuple_list, 0, fn {feet_used, price}, acc -> acc + (feet_used * price) end)
                average_price = if total_inches_used > 0.0, do: total_weighted_price / total_inches_used, else: 0.0
                sell_price = if average_price > 0.0, do: Float.ceil(average_price * 1.2 * 4) / 4, else: 0.0

                material_info =
                  %{material_name: s.material_name,
                  location_id: s.location_id,
                  on_hand_qty: Float.round(total_material_on_hand, 2),
                  lbs_per_inch: s.lbs_per_inch,
                  past_years_usage: s.past_years_usage,
                  purchase_price: average_price,
                  sell_price: sell_price,
                  cost_per_inch: number_to_currency(sell_price * s.lbs_per_inch),
                  cost_uofm: s.cost_uofm
                }
                #updated_matching_jobboss_material_info =
                #  case matching_jobboss_material_info do
                #    nil -> %{material_name: material_name, location_id: ""}
                #    found_info -> %{material_name: found_info.material_name, location_id: found_info.location_id}
                #  end

                populate_single_material_size(s, material_name, matching_size_reqs, matching_material_on_floor_or_being_quoted_or_on_order, matching_material_to_order, material_info)
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
      |> Float.round(2)
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
      length_needed_to_order = Enum.reduce(jobs, 0.0, fn job, acc -> ((job.length + job.cutoff + 0.11) * job.make_qty) + acc end)
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
          #8 here

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
                Map.put(map, :percentage_of_bar, Float.round(percentage_of_bar, 2))
                |> Map.put(:left_offset, Float.round(cumulative_percentage, 2))
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

            # Calculate how many parts can be made from this slug
            parts_from_this_slug = (material.slug_length / (length_needed + 0.2)) |> Float.floor()
            slug_qty_to_use = min(remaining_qty, parts_from_this_slug * slugs_left)

            # Calculate remaining quantity after using slugs
            remaining_qty = remaining_qty - slug_qty_to_use
            length_to_use = slug_qty_to_use * length_needed

            updated_assignments = [
              %{
                material_id: material.id,
                job: job_id,
                slug_qty: slug_qty_to_use,
                length_to_use: length_to_use,
                parts_from_bar: parts_from_this_slug
              } | assignments
            ]

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
