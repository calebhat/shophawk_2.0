defmodule Shophawk.Shop.Csvimport do
  alias Shophawk.Shop.Runlist
  alias Shophawk.Shop


  def update_operations do
    operations = #Takes 25 seconds to merge 43K operations
      jobs_to_update() #creates list of all jobs #'s that have a change somewhere
      |> runlist_ops("C:/phoenixapps/csv_files/yearlyRunlistOps.csv") #create map of all operations with a job listed in above function
      |> jobs_merge("C:/phoenixapps/csv_files/yearlyJobs.csv") #Merge job data with each operation
      |> mat_merge("C:/phoenixapps/csv_files/yearlyMat.csv") #Merge material data with each operation
      |> data_collection_merge("C:/phoenixapps/csv_files/operationtime.csv") #merge data collection
      |> uservalues_merge("C:/phoenixapps/csv_files/yearlyUserValues.csv") #Merge dots data with each operation
      |> Enum.map(fn map ->
        list = #for each map in the list, run it through changeset casting/validations. converts everything to correct datatype
          %Runlist{}
          |> Runlist.changeset(map)
        #have to manually add timestamps for insert all operation. Time must be in NavieDateTime for Ecto.
          list.changes #The changeset results in a list of data, extracts needed map from changeset.
          |> Map.put(:inserted_at, NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
          |> Map.put(:updated_at,  NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
        end)
    existing_records = #get structs of all operations needed for update
      Enum.map(operations, &(&1.job_operation))
      |> Enum.uniq #makes list of operation ID's to check for
      |> Shop.find_matching_operations #create list of structs that already exist in DB

      Enum.each(operations, fn op ->
        case Enum.find(existing_records, &(&1.job_operation == op.job_operation)) do
          nil -> #if the record does not exist, create a new one for it
            Shop.create_runlist(op)
          record ->   #if the record exists, update it with the new values
            Shop.update_runlist(record, op)
          end
      end)
  end

  def jobs_to_update() do
    job_list = #make a list of jobs that changed
      File.stream!("C:/phoenixapps/csv_files/Jobs.csv")
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.filter(fn
        ["\uFEFFJob", _ | _] -> false #filter out header line
        ["---" | _] -> false
        [_, "NULL" | _] -> false
        [_] -> false #lines with only one entry
        [job | _] -> true end)
      |> Enum.reduce( [], fn [job | _], acc -> [job | acc]  end)

    material_job_list = #make a list of jobs that material changed
      File.stream!("C:/phoenixapps/csv_files/material.csv")
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.filter(fn
        ["\uFEFFJob", _ | _] -> false #filter out header line
        ["---" | _] -> false
        [_, "NULL" | _] -> false
        [_] -> false #lines with only one entry
        [job | _] -> true end)
        |> Enum.reduce( [], fn [job | _], acc -> [job | acc]  end)

    operations_job_list = #Get list of jobs that have at least one operation updated
      File.stream!("C:/phoenixapps/csv_files/RunlistOps.csv")
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.filter(fn
        [_, "Job_Operation" | _] -> false #filter out header line
        ["---" | _] -> false
        [_, "NULL" | _] -> false
        [_] -> false #lines with only one entry
        [job | _] -> true end)
      |> Enum.reduce( [], fn [job | _], acc -> [job | acc] end)

      combined_list =
        job_list ++ material_job_list ++ operations_job_list
        |> Enum.uniq()
  end

  def import_operations() do #imports ALL operations from the past 13 months into the database, !will make duplicates!
    operations = #Takes 25 seconds to merge 43K operations
      runlist_ops("C:/phoenixapps/csv_files/yearlyRunlistOps.csv") #create map of all operations from the past year
      |> jobs_merge("C:/phoenixapps/csv_files/yearlyJobs.csv") #Merge job data with each operation
      |> mat_merge("C:/phoenixapps/csv_files/yearlyMat.csv") #Merge material data with each operation
      |> data_collection_merge("C:/phoenixapps/csv_files/yearlyoperationtime.csv")
      |> uservalues_merge("C:/phoenixapps/csv_files/yearlyUserValues.csv") #Merge dots data with each operation
      |> Enum.map(fn map ->
        list = #for each map in the list, run it through changeset casting/validations. converts everything to correct datatype
          %Runlist{}
          |> Runlist.changeset(map)
         #have to manually add timestamps for insert all operation. Time must be in NavieDateTime for Ecto.
          list.changes #The changeset results in a list of data, extracts needed map from changeset.
          |> Map.put(:inserted_at, NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
          |> Map.put(:updated_at,  NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second))
        end)
    Shop.import_all(operations) #imports all findings to the database at one time.
    operations
  end

  def runlist_ops(jobs_to_update \\ [], file) do
    operations =
    File.stream!(file)
    |> Stream.map(&String.trim(&1))
    |> Stream.map(&String.split(&1, "`"))
    |> Stream.filter(fn
      [_, "Job_Operation" | _] -> false #filter out header line
      ["---" | _] -> false
      [_, "NULL" | _] -> false
      [_] -> false #lines with only one entry
      [job | _] -> jobs_to_update |> Enum.empty?() || Enum.member?(jobs_to_update, job) #if the "jobs_to_update" list is empty, it allows any job to pass, if it's not empty, it checks if each job is on the list before passing it through
    end)
    |> Enum.reduce( [],
    fn
    [
      job,
      job_operation,
      wc_vendor,
      operation_service,
      sched_start,
      sched_end,
      sequence,
      status,
      est_total_hrs | _], acc ->
      new_map =
        %{job: job,
        job_operation: job_operation,
        wc_vendor: wc_vendor,
        operation_service: operation_service,
        sched_start: sched_start,
        sched_end: sched_end,
        sequence: sequence,
        status: status,
        est_total_hrs: est_total_hrs
        }
      [new_map | acc] end)
  end

  def jobs_merge(operations, file) do
    #empty map to make sure all fields are included in the map for later stuct
    empty_map =
      %{
      customer: nil,
      order_date: nil,
      part_number: nil,
      job_status: nil,
      rev: nil,
      description: nil,
      order_quantity: nil,
      extra_quantity: nil,
      pick_quantity: nil,
      make_quantity: nil,
      open_operations: nil,
      shipped_quantity: nil,
      customer_po: nil,
      customer_po_line: nil,
      job_sched_end: nil,
      job_sched_start: nil,
      released_date: nil,
      note_text: nil,
      user_value: nil
      }
    new_list =
      File.stream!(file)
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.filter(fn
        ["\uFEFFJob", _ | _] -> false #filter out header line
        ["---" | _] -> false
        [_, "NULL" | _] -> false
        [_] -> false #lines with only one entry
        [job | _] -> true end)
      |> Enum.reduce( [],
      fn
      [
        job,
        customer,
        order_date,
        part_number,
        job_status,
        rev,
        description,
        order_quantity,
        extra_quantity,
        pick_quantity,
        make_quantity,
        open_operations,
        shipped_quantity,
        customer_po,
        customer_po_line,
        job_sched_end,
        job_sched_start,
        released_date,
        note_text,
        user_value | _], acc ->
          new_map =
            %{job: job,
            customer: customer,
            order_date: order_date,
            part_number: part_number,
            job_status: job_status,
            rev: rev,
            description: description,
            order_quantity: order_quantity,
            extra_quantity: extra_quantity,
            pick_quantity: pick_quantity,
            make_quantity: make_quantity,
            open_operations: open_operations,
            shipped_quantity: shipped_quantity,
            customer_po: customer_po,
            customer_po_line: customer_po_line,
            job_sched_end: job_sched_end,
            job_sched_start: job_sched_start,
            released_date: released_date,
            note_text: note_text,
            user_value: user_value
            }
        [new_map | acc]  end)

        merged_list = Enum.map(operations, fn %{job: job} = map1 ->
          #find the corresponding map in new_list based on job value
          map2 = Enum.find(Enum.reverse(new_list), &(&1.job == job))

          if map2 do
            Map.merge(map1, map2)
          else
            Map.merge(map1, empty_map)
          end
        end)
  end

  def mat_merge(operations, file) do
    empty_map = #used in case no match is found in material csv
      %{job: nil,
      material: nil,
      mat_vendor: nil,
      mat_description: nil,
      mat_pick_or_buy: nil,
      mat_status: nil
    }
    keys_to_exclude = [:job]
    new_list =
      File.stream!(file)
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.filter(fn
        ["\uFEFFJob", _ | _] -> false #filter out header line
        ["---" | _] -> false
        [_, "NULL" | _] -> false
        [_] -> false #lines with only one entry
        [job | _] -> true end)
      |> Enum.reduce( [],
      fn
      [
        job,
        material,
        mat_vendor,
        mat_description,
        mat_pick_or_buy,
        mat_status | _], acc ->
          new_map =
            %{job: job,
            material: material,
            mat_vendor: mat_vendor,
            mat_description: mat_description,
            mat_pick_or_buy: mat_pick_or_buy,
            mat_status: mat_status
            }
        [new_map | acc]  end)
        Enum.map(operations, fn %{job: job} = map1 ->
          matching_maps = Enum.reverse(new_list) |> Enum.filter(&(&1.job == job))
          case Enum.count(matching_maps) do #case if multiple maps found in the list, ie multiple materials
            0 -> Map.merge(map1, Map.take(empty_map, Map.keys(empty_map) -- [:job]))
            1 ->
              map2 = Enum.at(matching_maps, 0)
              Map.merge(map1, Map.take(map2, Map.keys(map2) -- [:job])) #merges all except job to keep job in place (overwrites the job to nil if there no material ie. pick jobs)
            _ ->
              #map2 = Map.merge(map1, map2)
              map2 = Enum.reduce(matching_maps, %{}, fn map, acc ->
                Map.merge(acc, Map.take(map, Map.keys(map) -- [:job]), fn _, value1, value2 ->
                  "#{value1} | #{value2}"
                end)
              end)
              Map.merge(map1, map2)
          end
        end)
  end

  def data_collection_merge(operations, file) do
    empty_map = #used in case no match is found in material csv
      %{employee: nil,
        work_date: nil,
        act_setup_hrs: nil,
        act_run_hrs: nil,
        act_run_qty: nil,
        act_scrap_qty: nil,
        data_collection_note_text: nil
    }
    new_list =
      File.stream!(file)
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.filter(fn
        ["\uFEFFJob_Operation", _ | _] -> false #filter out header line
        ["-------------" | _] -> false
        [_, "NULL" | _] -> false
        [_] -> false #lines with only one entry
        [job_operation | _] -> true end)
      |> Enum.reduce( [],
      fn
      [ job_operation,
        employee,
        work_date,
        act_setup_hrs,
        act_run_hrs,
        act_run_qty,
        act_scrap_qty,
        data_collection_note_text | _], acc ->
          new_map =
            %{job_operation: job_operation,
            employee: employee,
            work_date: work_date,
            act_setup_hrs: act_setup_hrs,
            act_run_hrs: act_run_hrs,
            act_run_qty: act_run_qty,
            act_scrap_qty: act_scrap_qty,
            data_collection_note_text: data_collection_note_text
            }
        [new_map | acc]  end)
        Enum.map(operations, fn %{job_operation: job_operation} = map1 ->
          matching_maps = Enum.reverse(new_list) |> Enum.filter(&(&1.job_operation == job_operation)) #gets matching job_operation's
          case Enum.count(matching_maps) do #case if multiple maps found in the list, ie multiple materials
            0 -> Map.merge(map1, Map.take(empty_map, Map.keys(empty_map) -- [:job_operation]))
            1 ->
              map2 = Enum.at(matching_maps, 0)
              Map.merge(map1, Map.take(map2, Map.keys(map2) -- [:job_operation])) #merges all except job to keep job in place (overwrites the job to nil if there no material ie. pick jobs)
            _ ->
              map2 = Enum.reduce(matching_maps, %{}, fn map, acc ->
                Map.merge(acc, Map.take(map, Map.keys(map) -- [:job_operation]), fn _, value1, value2 ->
                  "#{value1} | #{value2}"
                end)
              end)
              Map.merge(map1, map2)
          end
        end)
  end

  def uservalues_merge(operations, file) do
    empty_map = %{user_value: nil, dots: nil} #used in case no match is found in material csv
    new_list =
      File.stream!(file)
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, "`"))
      |> Stream.filter(fn
        ["\uFEFFUser_Values", _ | _] -> false #filter out header line
        [_, "-----" | _] -> false
        [_] -> false #lines with only one entry
        [user_values | _] -> true end)
      |> Enum.reduce( [],
        fn [user_value, dots | _], acc ->
          new_map = %{user_value: user_value, dots: dots}
          [new_map | acc]  end)
          Enum.map(operations, fn %{user_value: user_value} = map1 ->
            map2 = Enum.find(new_list, &(&1.user_value == user_value))
            if map2 do
              Map.merge(map1, map2)
            else
              Map.merge(map1, empty_map)
            end
        end)
  end


  #convert all the csv's to list of maps, combine them all with the below functions, then convert them into Runlist%{} struct at the end
  #feed to changeset to validate, check if it exists in DB, then update/save


end
