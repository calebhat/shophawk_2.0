defmodule Shophawk.MaterialCache do
  use GenServer
  alias Shophawk.Jobboss_db_material
  alias Shophawk.Material
  import Number.Currency


  @topic "materials:updates"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_refresh()
    {:ok, state}
  end

  def handle_info(:refresh_cache, state) do
    material_list = create_material_cache()

    # Broadcast the updated material list
    ShophawkWeb.Endpoint.broadcast(@topic, "material_update", material_list)

    if System.get_env("MIX_ENV") == "prod" do
      schedule_refresh()
    end
    {:noreply, state}
  end

  defp schedule_refresh() do
    Process.send_after(self(), :refresh_cache, :timer.minutes(2))
  end

  def create_material_cache() do
    #Create bare bones list for material cache and save to cache
    {material_list, jobboss_material_info} = create_barebones_material_list()

    #load all data needed
    mat_reqs = Jobboss_db_material.load_material_requirements()
    year_history = Jobboss_db_material.load_year_history_of_material_requirements()
    all_material_not_used = Material.list_material_not_used
    all_material_purchased_in_past_12_months = Material.list_stockedmaterials_last_12_month_entries()
    jb_material_on_hand_qty =
      Enum.map(jobboss_material_info, fn mat -> mat.material end)
      |> Jobboss_db_material.load_all_jb_material_on_hand()
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
                  standard_cost: 0.0,
                  shape: ""
                  }
                found_info ->
                  matching_material_on_floor = Enum.filter(matching_material, fn mat -> mat.in_house == true && mat.being_quoted == false && mat.ordered ==  false end)
                  total_material_on_hand = Enum.reduce(matching_material_on_floor, 0.0, fn m, acc ->
                    case m.bar_length do
                      nil -> acc
                      length -> length + acc
                    end
                  end) / 12

                  material_year_history = Enum.filter(year_history, fn m ->
                    m.material == found_info.material_name end) |> Enum.reduce(0.0, fn m, acc -> m.act_qty + acc
                  end)

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
                  purchase_price: Float.round(average_price, 2),
                  sell_price: Float.round(sell_price, 2),
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

    merged_material_list =
      merge_materials(updated_material_list)
      |> Enum.map(fn material ->
        Map.put(material, :sizes, sort_mixed_list(material.sizes))
      end)


    Cachex.put(:material_list, :data, merged_material_list)
    merged_material_list
  end

  def merge_materials(material_list) do #combines similar named materials from Jobboss
    merge_material(material_list, ["4150HT"])
    |> merge_material("100-70-03 DI", "DI 100-70-03", ["100-70-03 DI"])
    |> merge_material("1045", "1045", ["1045", "1045 HR", "1045HR", "1045."])
    |> merge_material("1045 G&P", "1045 G&P", ["1045 TG&P", "1045 TP&G", "1045 G&P"])
    |> merge_material("12FT. 1117 CR KNURLED BAR", "Knurled 1117", ["12FT. 1117 CR KNURLED BAR", "12FT 1117CF KNURLED BAR", "12FT.1117 CR KNURLED BAR"])
    |> merge_material("12FT. 1144 CR KNURLED BAR", "Knurled 1144", ["12FT. 1144 CR KNURLED BAR", "12FT. 1545 CR KNURLED BAR", "12FT 1144 CF KNURLED BAR "])
    |> merge_material("17-4PH", "17-4PH", ["17-4", "17-4PH", "17-4PH ", "17-4SS"])
    |> merge_material(["304"])
    |> merge_material("4140", "4140", ["4140", "4140."])
    |> merge_material("4140CR", "4140CR", ["4140CF", "4140CR"])
    |> merge_material("4140HT C.F.", "4140HT CF", ["4140HT C.F.", "4140HT CR", "4140HTCR"])
    |> merge_material("4140HT G&P", "4140HT G&P", ["4140HT G&P", "4140HT G AND P", "4140HT G & P"])
    |> merge_material("4150HT", "4150HT", ["4150HT", "4150 HT"])
    |> merge_material("416", "416", ["416", "416SS"])
    |> merge_material("416HT", "416HT", ["416HT", "416SSHT", " 416 HT", " 416 HT ", "416SSHT (C.F.)"])
    |> merge_material("4340", "4340", ["4340", "4340."])
    |> merge_material("440SS", "440SS", ["440SS", "440C", "440"])
    |> merge_material("630BRNZ", "630BRNZ", ["630BRNZ", "6300BRNZ", "630 NI/AL BRNZ"])
    |> merge_material("660BRNZ", "660BRNZ", ["660BRNZ", "660 BRZ", "660BRZ"])
    |> merge_material("6061", "6061", ["6061", "6061 AL", "6061.", "6061AL"])
    |> merge_material("7075", "7075", ["7075", "7075 (T-6)", "7075.", " 7075"])
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

    #Tubing
    #|> merge_material("316 Tubing", "GSM", ["GSM", "GSM "])
  end

  def merge_material(material_list, mat_to_keep) do
    good_material = Enum.find(material_list, fn mat -> mat.material == mat_to_keep end)
    case good_material do
      nil -> material_list
      _ ->
        grouped_material_list =
          Enum.reduce(material_list, [], fn mat, acc ->
            if Enum.member?(mat_to_keep, mat.material) do
              acc ++ [mat.material]
            else
              acc
            end
          end)

        sizes_to_merge =
          Enum.reduce(material_list, [], fn mat, acc ->
            if Enum.member?(grouped_material_list, mat.material) do
              acc ++ mat.sizes
            else
              acc
            end
          end)

        updated_material =
          Map.put(good_material, :sizes, sizes_to_merge)
          |> Map.put(:mat_reqs_count, Enum.reduce(sizes_to_merge, 0, fn size, acc -> size.jobs_using_size + acc end))

        #remove all occurences of material
        filtered_material_list = Enum.reject(material_list, fn mat -> Enum.member?(grouped_material_list, mat.material) end)
        filtered_material_list ++ [updated_material]
      end
  end

  def merge_material(material_list, mat_to_keep, name_to_use, list_of_materials) do
    #IO.inspect(material_list)
    case Map.has_key?(List.first(material_list), :sizes) do
      true -> #normal material merge operation
        good_material = Enum.find(material_list, fn mat -> mat.material == mat_to_keep end)

        case good_material do
          nil -> material_list
          _ ->
            sizes_to_merge =
              Enum.reduce(material_list, [], fn mat, acc ->
                if Enum.member?(list_of_materials, mat.material) do
                  acc ++ mat.sizes
                else
                  acc
                end
              end)

            updated_material =
              Map.put(good_material, :material, name_to_use)
              |> Map.put(:sizes, sizes_to_merge)
              |> Map.put(:mat_reqs_count, Enum.reduce(sizes_to_merge, 0, fn size, acc -> size.jobs_using_size + acc end))

            #remove all occurences of material
            filtered_material_list = Enum.reject(material_list, fn mat -> Enum.member?(list_of_materials, mat.material) end)

            filtered_material_list ++ [updated_material]
        end
      false -> #material name change for liveview routing navigation
        if List.first(material_list).material in list_of_materials do
          [Map.put(List.first(material_list), :material, name_to_use)]
        else
          material_list
        end
    end
  end

  def create_barebones_material_list() do
    jobboss_material_info = Shophawk.Jobboss_db_material.load_materials_and_sizes()
    #round_stock = jobboss_material_info
      #Enum.filter(jobboss_material_info, fn m -> m.shape == "Round" end)

    material_list =
      Enum.reduce(jobboss_material_info, [], fn mat, acc ->
        case mat.shape do
          "Round" ->
            case String.split(mat.material, "X", parts: 2) do
              [_] -> acc
              [size, material] ->
                case Enum.find(acc, fn m -> m.material == material and m.shape == mat.shape end) do
                  nil -> # New material/size not in list already
                    [%{
                      material: material,
                      mat_reqs_count: nil,
                      shape: mat.shape,
                      sizes: [
                        %{
                          size: size,
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
                          cost_uofm: nil,
                          shape: mat.shape
                        }
                      ]
                    } | acc]

                  found_material -> # Add new sizes to existing material in list
                    updated_map = Map.update!(found_material, :sizes, fn existing_sizes ->
                      [
                        %{
                          size: size,
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
                          cost_uofm: nil,
                          shape: mat.shape
                        } | existing_sizes
                      ]
                    end)
                    updated_acc = Enum.reject(acc, fn m -> m.material == found_material.material end)
                    [updated_map | updated_acc]
                end

              _ -> acc
            end
          _rectangle_or_tubing ->
            case String.split(mat.material, "X", parts: 3) do
              [_] -> acc
              [size1, size2, material] ->
                material = material <> " " <> mat.shape
                size = size1 <> "X" <> size2
                case Enum.find(acc, fn m -> m.material == material and m.shape == mat.shape end) do
                  nil -> # New material/size not in list already
                    [%{
                      material: material,
                      mat_reqs_count: nil,
                      shape: mat.shape,
                      sizes: [
                        %{
                          size: size,
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
                          cost_uofm: nil,
                          shape: mat.shape
                        }
                      ]
                    } | acc]

                  found_material -> # Add new sizes to existing material in list
                    updated_map = Map.update!(found_material, :sizes, fn existing_sizes ->
                      [
                        %{
                          size: size,
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
                          cost_uofm: nil,
                          shape: mat.shape
                        } | existing_sizes
                      ]
                    end)
                    updated_acc = Enum.reject(acc, fn m -> m.material == found_material.material end)
                    [updated_map | updated_acc]
                end

              _ -> acc
            end
        end
      end)
      |> Enum.map(fn material ->
        Map.put(material, :sizes, sort_mixed_list(material.sizes))
      end)
      |> Enum.uniq_by(&(&1.material))
      |> Enum.sort_by(&(&1.material), :asc)
#Material list is sorted correctly here.
    {material_list, jobboss_material_info}
  end

  def sort_mixed_list(sizes) do
    {floats, strings} =
      Enum.reduce(sizes, {[], []}, fn s, {floats, strings} ->
        size = if String.starts_with?(s.size, "."), do: "0" <> s.size, else: s.size
        case Float.parse(size) do
          {_f, ""} -> {floats ++ [s], strings}
          {_, _s} -> {floats, strings ++ [s]}
        end
      end)

    float_sizes =
      Enum.sort_by(floats, fn f ->
        size = if String.starts_with?(f.size, "."), do: "0" <> f.size, else: f.size
        {float, _} = Float.parse(size)
        float
      end)

    string_sizes =
        Enum.sort_by(strings, fn s ->
        size = if String.starts_with?(s.size, "."), do: "0" <> s.size, else: s.size
        case Float.parse(size) do #sorts by numbers first, then letters
          {n, _remainder} -> {1, n}
          _ -> {2, s}
        end
      end)

    float_sizes ++ string_sizes
  end

  def populate_single_material_size(s, material, mat_reqs, material_on_floor, matching_material_to_order, material_info) do
    #Delete material to order so it's always just one that reset in this function
    Enum.each(matching_material_to_order, fn mat ->
      Material.delete_stocked_material(mat, true)
    end)

    size =
      case s.shape do
        "Round" ->
          [size, _material_name] = String.split(s.material_name, "X", parts: 2)
          size
        _rectangle_or_tubing ->
          [size1, size2, _material] = String.split(s.material_name, "X", parts: 3)
          size1 <> "X" <> size2
      end


    jobs_to_assign =
      Enum.map(mat_reqs, fn job ->

        #find first saw operation, subtract any qty complete
        runlists =
          Cachex.stream!(:active_jobs, Cachex.Query.build(output: :value))
          |> Enum.to_list
          |> Enum.map(fn job_data -> job_data.job_ops end)
          |> List.flatten

        first_saw_operation =
          Enum.filter(runlists, fn r ->
            r.job == job.job
          end)
          |> Enum.sort_by(&(&1.sequence))
          |> Enum.find(&(&1.wc_vendor) == "A-SAW")

        make_qty =
          case first_saw_operation do
            nil -> job.make_quantity
            _ -> job.make_quantity - first_saw_operation.act_run_qty
          end

        %{job: job.job, length: Float.round((job.part_length), 2), make_qty: make_qty, cutoff: job.cutoff, mat: material, size: size}
      end)
      |> Enum.sort_by(&(&1.make_qty), :desc)


    #DON'T DELETE MATERIAL TO ORDER AT THE TOP OF THE FUNCTION, SEND THE VALUES HERE AND UPDATE IF NEEDED?
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
      size: size,
      jobs_using_size: Enum.count(mat_reqs),
      matching_jobs: matching_jobs,
      material_name: material_info.material_name,
      location_id: material_info.location_id,
      on_hand_qty: material_info.on_hand_qty,
      lbs_per_inch: material_info.lbs_per_inch,
      past_years_usage: material_info.past_years_usage,
      purchase_price: Float.round(material_info.purchase_price, 2),
      sell_price: Float.round(material_info.sell_price, 2),
      cost_per_inch: material_info.cost_per_inch,
      cost_uofm: material_info.cost_uofm,
      need_to_order_amt: need_to_order_amt,
      assigned_material_info: assigned_material_info,
      shape: s.shape
      }
  end

  #Updates one size and saves updated material_list in cache
  def update_single_material_size_in_cache(material_name) do
    {:ok, material_list} = Cachex.get(:material_list, :data)
    #material_not_used = Material.list_material_not_used
    updated_material_list =
      Enum.map(material_list, fn mat ->
        sizes =
          Enum.map(mat.sizes, fn s ->
            case s.material_name == material_name do
              true ->
                matching_size_reqs = Jobboss_db_material.load_single_material_requirements(material_name)

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
                  purchase_price: Float.round(average_price, 2),
                  sell_price: Float.round(sell_price, 2),
                  cost_per_inch: number_to_currency(sell_price * s.lbs_per_inch),
                  cost_uofm: s.cost_uofm,
                  shape: s.shape
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

    Cachex.put(:material_list, :data, updated_material_list)
    updated_material_list
  end

  def assign_jobs_to_material(jobs, material_on_floor, material) do
    sorted_jobs = Enum.sort_by(jobs, fn j -> j.length end, :asc)
    if material_on_floor != [] do
      updated_material_on_floor =
        Enum.map(material_on_floor, fn map ->
          case map.bar_length do
            nil -> Map.put(map, :remaining_length_not_assigned, 0.0)
            _ -> Map.put(map, :remaining_length_not_assigned, map.bar_length)
          end
        end)
        |> Enum.sort_by(fn b -> b.remaining_length_not_assigned end, :desc)
      {materials, remaining_jobs} =
        Enum.reduce(sorted_jobs, {updated_material_on_floor, []}, fn job, {materials, remaining_jobs} ->
          sawed_length = Float.round((job.length + job.cutoff + 0.1), 2)
          # Use slugs within .25" of length
          {materials, remaining_qty} = assign_to_slugs(materials, job)

          # Assign to Bars
          {materials, remaining_qty} =
            if remaining_qty > 0 do
              job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: remaining_qty}

              bars_not_in_house = Enum.reject(materials, fn mat -> mat.in_house == true end)
              bars_in_house = Enum.filter(materials, fn mat -> mat.in_house == true end)
              {materials, remaining_qty} = assign_to_bars(bars_in_house, job_that_needs_sawing)
              materials = materials ++ bars_not_in_house
              {materials, remaining_qty}
            else
              {materials, remaining_qty}
            end

            #WHY IS REMAINING QTY 0 BEFORE ASSIGNMENTS ARE DONE???
          #Assign to any long slugs
          {materials, remaining_qty} =
            if remaining_qty > 0 do
              longer_slugs_needed = Map.put(job, :make_qty, remaining_qty)
              last_resort_assign_to_slugs(materials, longer_slugs_needed)
            else
              {materials, remaining_qty}
            end

          #assign to any bars being ordered
          {materials, remaining_qty} =
            if remaining_qty > 0 do
              job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: remaining_qty}

              bars_not_in_house = Enum.reject(materials, fn mat -> mat.in_house == true end)
              bars_in_house = Enum.filter(materials, fn mat -> mat.in_house == true end)
              {materials, remaining_qty} = assign_to_bars(bars_not_in_house, job_that_needs_sawing)
              materials = bars_in_house ++ materials
              {materials, remaining_qty}
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
        ((job.length + job.cutoff + 0.2) * job.make_qty) + acc
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
          sawed_length = Float.round((job.length + job.cutoff + 0.2), 2)
          #add cutoff and blade width for cutting
          job_that_needs_sawing = %{job: job.job, sawed_length: sawed_length, remaining_qty: job.make_qty}

          {assigned_bars, _remaining_qty} = assign_to_bars(material, job_that_needs_sawing)
          assigned_bars
        end)

      materials = assign_percentage_used_to_bars(materials)
      {materials, Float.round(length_needed_to_order, 2)}

    else #if no stocked material assign_to_bars
      length_needed_to_order = Enum.reduce(jobs, 0.0, fn job, acc -> ((job.length + job.cutoff + 0.2) * job.make_qty) + acc end)
      bar_to_order =
        if length_needed_to_order > 0.0 do
          [Material.create_stocked_material(%{material: material, bar_length: "#{length_needed_to_order}", in_house: false, remaining_length_not_assigned: "#{length_needed_to_order}"})
          |> elem(1)]
        else
          []
        end
      assigned_bars =
        Enum.reduce(jobs, bar_to_order, fn job, materials ->
          sawed_length = Float.round((job.length + job.cutoff + 0.2), 2)
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
      if material.slug_length >= (length_needed + 0.1) and material.slug_length <= (length_needed + 0.25) do
        assignments = Map.get(material, :job_assignments, [])
        slugs_available_to_use =
          case assignments do
            [] -> material.number_of_slugs
            list ->
              slugs_used = Enum.reduce(list, 0.0, fn x, acc -> x.slug_qty + acc end)
              material.number_of_slugs - slugs_used
          end
        if slugs_available_to_use > 0 do
          updated_assignments = [%{material_id: material.id, job: job_id, slug_qty: min(remaining_qty, material.number_of_slugs), part_qty: min(remaining_qty, material.number_of_slugs), length_to_use: 0.0, parts_from_bar: 0} | assignments]
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

          updated_assignments = [%{material_id: material.id, job: job, length_to_use: length_to_use, parts_from_bar: parts_from_bar, slug_qty: 0, part_qty: 0} | assignments]
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
      if material.slug_length != nil and length_needed > 0.0 do
        if (material.slug_length + 0.05) >= length_needed do
          #Gets assignments
          assignments = Map.get(material, :job_assignments, [])
          #calcs how many slugs are not used
          slugs_left =
            case assignments do
              [] -> material.number_of_slugs
              list ->
                slugs_used = Enum.reduce(list, 0.0, fn x, acc -> x.slug_qty + acc end)
                material.number_of_slugs - slugs_used
            end

          if slugs_left > 0 do

            parts_from_one_slug =
              cond do
                (material.slug_length + 0.05) / length_needed < 2.0 and (material.slug_length + 0.05) / length_needed >= 1.0 -> 1
                (material.slug_length + 0.05) / length_needed < 1.0 -> 0
                true -> (material.slug_length / (length_needed + 0.2)) |> Float.floor() |> trunc()
              end

            slug_qty_to_use =
              case parts_from_one_slug do
                0 -> 0
                _ ->
                  slugs_needed = Float.ceil((remaining_qty / parts_from_one_slug))
                  min(slugs_needed, slugs_left)
                  |> trunc()
                end

            parts_from_slugs = min((slug_qty_to_use * parts_from_one_slug), remaining_qty)

            updated_assignments =
                [
                  %{
                    material_id: material.id,
                    job: job_id,
                    slug_qty: slug_qty_to_use,
                    part_qty: parts_from_slugs,
                    length_to_use: 0.0,
                    parts_from_bar: parts_from_one_slug
                  } | assignments
                ]

            updated_material = Map.put(material, :job_assignments, updated_assignments)
            remaining_qty = remaining_qty - parts_from_slugs
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
