defmodule Shophawk.Jobboss_db_material do
  import Ecto.Query, warn: false
  import Shophawk.Jobboss_db
  alias DateTime
  alias Shophawk.Jb_job_operation
  alias Shophawk.Jb_job_qty
  alias Shophawk.Jb_material_req
  alias Shophawk.Jb_job_operation_time
  alias Shophawk.Jb_material
  alias Shophawk.Jb_material_location

  #not used?
  def load_jb_material_information(material_name) do #NOT USED????
    query =
      from r in Jb_material,
      where: r.material == ^material_name,
      where: r.pick_buy_indicator == "P",
      where: r.stocked_uofm == "ft",
      where: r.status == "Active"
    material =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
      end)
      |> List.first

      merge_material_location(material)
  end

  #not used?
  def merge_material_location(material) do
    query =
      from r in Jb_material_location,
      where: r.material == ^material.material
    material_location =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
      end)
      |> List.first
    case material_location do
      nil -> Map.merge(material, %Shophawk.Jb_material_location{} |> Map.from_struct() |> Map.drop([:__meta__, :material, :location_id]) )
      _ -> Map.merge(material, material_location)
    end
  end

  def load_all_jb_material_on_hand(material_list) do
    query =
      from r in Jb_material_location,
      where: r.material in ^material_list
    material =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
      end)
    #rename materail key:
    Enum.map(material, fn mat ->
      Map.put(mat, :material_name, mat.material)
      |> Map.delete(:material)
    end)
  end

  def update_material(size_info, on_hand_qty) do
    material = size_info.material_name
    location_id = size_info.location_id
    purchase_price = size_info.purchase_price
    sell_price = size_info.sell_price
    location_id = if location_id == nil, do: "", else: location_id
    if is_nil(material) == false and location_id != "" do
      on_hand_qty = on_hand_qty / 12 #Convert to Feet for Jobboss
      query =
        Shophawk.Jb_material_location
        |> where([r], r.location_id == ^location_id)
        |> where([r], r.material == ^material)
        |> update([r], set: [on_hand_qty: ^on_hand_qty])
      Shophawk.Repo_jb.update_all(query, [])

      rounded_purchase_price = Float.round(purchase_price, 2)
      rounded_sell_price = Float.round(sell_price, 2)
      if rounded_sell_price > 0.0 do
        query =
          Shophawk.Jb_material
          |> where([r], r.material == ^material)
          |> update([r], set: [standard_cost: ^rounded_purchase_price])
          |> update([r], set: [selling_price: ^rounded_sell_price])
        Shophawk.Repo_jb.update_all(query, [])
      end
      true
    else
      false
    end
  end

  def load_materials_and_sizes() do #doesn't load into cache right now
    query =
      from r in Jb_material,
      where: r.pick_buy_indicator == "P",
      where: r.stocked_uofm == "ft",
      where: r.shape in ["Round", "Rectangle", "Tubing"],
      where: r.status == "Active"
    failsafed_query(query)
    |> Enum.map(fn op ->
      Map.from_struct(op)
      |> Map.drop([:__meta__])
    end)
    |> Enum.reject(fn mat -> String.contains?(mat.material, ["GROB", "MC907", "NGSM", "NMSM", "NNSM", "TEST", "ATN"]) end)
  end

  def load_material_requirements do
    query =
      from r in Jb_material_req,
      where: r.status in ["O", "S"],
      where: r.pick_buy_indicator == "P",
      where: r.uofm == "ft",
      where: not is_nil(r.due_date)
    mat_reqs =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.update!(:cutoff, &(Float.round(&1, 2)))
        |> Map.update!(:part_length, &(Float.round(&1, 2)))
        |> Map.put(:est_qty, Float.round((op.est_qty - op.act_qty), 2))
        |> sanitize_map()
      end)
      job_numbers = Enum.map(mat_reqs, fn mat -> mat.job end) |> Enum.uniq
      query = from r in Jb_job_qty, where: r.job in ^job_numbers
      jobs = #grab make_qty and merge
        failsafed_query(query)
        |> Enum.map(fn op ->
          Map.from_struct(op)
          |> Map.drop([:__meta__])
        end)
      Enum.map(mat_reqs, fn mat ->
        case Enum.find(jobs, fn job -> job.job == mat.job end) do
          nil -> mat
          found_job -> Map.merge(mat, found_job)
        end
      end)
  end

  def load_year_history_of_material_requirements do
    one_year_ago = NaiveDateTime.utc_now() |> NaiveDateTime.beginning_of_day() |> NaiveDateTime.shift(year: -1)
    query =
      from r in Jb_material_req,
      where: r.pick_buy_indicator == "P",
      where: r.uofm == "ft",
      where: not is_nil(r.due_date),
      where: r.due_date >= ^one_year_ago
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([[:__meta__, :cutoff, :part_length, :vendor, :description, :pick_buy_indicator, :status, :uofm, :last_updated, :due_date, :est_qty]])
        |> Map.update!(:act_qty, &(Float.round(&1, 2)))
        |> sanitize_map()
      end)
  end

  def load_job_operation_time_by_employee(employee_initial, startdate, enddate) do
    startdate = NaiveDateTime.new(startdate, ~T[00:00:00]) |> elem(1)
    enddate = NaiveDateTime.new(enddate, ~T[00:00:00]) |> elem(1)
    query =
      from r in Jb_job_operation_time,
      where: r.employee == ^employee_initial,
      where: r.work_date <= ^enddate and r.work_date >= ^startdate
      failsafed_query(query) |> Enum.map(fn op -> Map.from_struct(op) |> Map.drop([:__meta__]) end)
  end

  def load_job_operations(operation_numbers) do
    query = from r in Jb_job_operation, where: r.job_operation in ^operation_numbers
    failsafed_query(query)
    |> Enum.map(fn op ->
      Map.from_struct(op)
      |> Map.drop([:__meta__])
      |> rename_key(:note_text, :operation_note_text)
    end)
  end

  def load_single_material_requirements(material) do
    query =
      from r in Jb_material_req,
      where: r.status in ["O", "S"],
      where: r.pick_buy_indicator == "P",
      where: r.uofm == "ft",
      where: not is_nil(r.due_date),
      where: r.material == ^material
    mat_reqs =
      failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> Map.update!(:cutoff, &(Float.round(&1, 2)))
        |> Map.update!(:part_length, &(Float.round(&1, 2)))
        |> Map.put(:est_qty, Float.round((op.est_qty - op.act_qty), 2))
        |> sanitize_map()
      end)
      job_numbers = Enum.map(mat_reqs, fn mat -> mat.job end) |> Enum.uniq
      query = from r in Jb_job_qty, where: r.job in ^job_numbers
      jobs = #grab make_qty and merge
        failsafed_query(query)
        |> Enum.map(fn op ->
          Map.from_struct(op)
          |> Map.drop([:__meta__])
        end)
      Enum.map(mat_reqs, fn mat ->
        case Enum.find(jobs, fn job -> job.job == mat.job end) do
          nil -> mat
          found_job -> Map.merge(mat, found_job)
        end
      end)
  end

end
