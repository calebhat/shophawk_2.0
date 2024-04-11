defmodule Shophawk.ShopTest do
  use Shophawk.DataCase

  alias Shophawk.Shop

  describe "runlists" do
    alias Shophawk.Shop.Runlist

    import Shophawk.ShopFixtures

    @invalid_attrs %{material: nil, released_date: nil, customer_po_line: nil, extra_quantity: nil, est_total_hrs: nil, sched_end: nil, customer_po: nil, vendor: nil, operation_service: nil, make_quantity: nil, employee: nil, note_text: nil, order_quantity: nil, job: nil, mat_vendor: nil, material_waiting: nil, shipped_quantity: nil, part_number: nil, order_date: nil, customer: nil, sequence: nil, currentop: nil, rev: nil, status: nil, job_operation: nil, job_sched_start: nil, pick_quantity: nil, wc_vendor: nil, job_sched_end: nil, open_operations: nil, complete_operations: nil, sched_start: nil, description: nil, mat_description: nil, dots: nil}

    test "list_runlists/0 returns all runlists" do
      runlist = runlist_fixture()
      assert Shop.list_runlists() == [runlist]
    end

    test "get_runlist!/1 returns the runlist with given id" do
      runlist = runlist_fixture()
      assert Shop.get_runlist!(runlist.id) == runlist
    end

    test "create_runlist/1 with valid data creates a runlist" do
      valid_attrs = %{material: "some material", released_date: ~D[2023-11-12], customer_po_line: 42, extra_quantity: 42, est_total_hrs: 42, sched_end: ~D[2023-11-12], customer_po: "some customer_po", vendor: "some vendor", operation_service: "some operation_service", make_quantity: 42, employee: "some employee", note_text: "some note_text", order_quantity: 42, job: "some job", mat_vendor: "some mat_vendor", material_waiting: true, shipped_quantity: 42, part_number: "some part_number", order_date: ~D[2023-11-12], customer: "some customer", sequence: 42, currentop: "some currentop", rev: "some rev", status: "some status", job_operation: 42, job_sched_start: ~D[2023-11-12], pick_quantity: 42, wc_vendor: "some wc_vendor", job_sched_end: ~D[2023-11-12], open_operations: 42, complete_operations: 42, sched_start: ~D[2023-11-12], description: "some description", mat_description: "some mat_description", dots: 42}

      assert {:ok, %Runlist{} = runlist} = Shop.create_runlist(valid_attrs)
      assert runlist.dots == 42
      assert runlist.mat_description == "some mat_description"
      assert runlist.description == "some description"
      assert runlist.sched_start == ~D[2023-11-12]
      assert runlist.complete_operations == 42
      assert runlist.open_operations == 42
      assert runlist.job_sched_end == ~D[2023-11-12]
      assert runlist.wc_vendor == "some wc_vendor"
      assert runlist.pick_quantity == 42
      assert runlist.job_sched_start == ~D[2023-11-12]
      assert runlist.job_operation == 42
      assert runlist.status == "some status"
      assert runlist.rev == "some rev"
      assert runlist.currentop == "some currentop"
      assert runlist.sequence == 42
      assert runlist.customer == "some customer"
      assert runlist.order_date == ~D[2023-11-12]
      assert runlist.part_number == "some part_number"
      assert runlist.shipped_quantity == 42
      assert runlist.material_waiting == true
      assert runlist.mat_vendor == "some mat_vendor"
      assert runlist.job == "some job"
      assert runlist.order_quantity == 42
      assert runlist.note_text == "some note_text"
      assert runlist.employee == "some employee"
      assert runlist.make_quantity == 42
      assert runlist.operation_service == "some operation_service"
      assert runlist.vendor == "some vendor"
      assert runlist.customer_po == "some customer_po"
      assert runlist.sched_end == ~D[2023-11-12]
      assert runlist.est_total_hrs == 42
      assert runlist.extra_quantity == 42
      assert runlist.customer_po_line == 42
      assert runlist.released_date == ~D[2023-11-12]
      assert runlist.material == "some material"
    end

    test "create_runlist/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shop.create_runlist(@invalid_attrs)
    end

    test "update_runlist/2 with valid data updates the runlist" do
      runlist = runlist_fixture()
      update_attrs = %{material: "some updated material", released_date: ~D[2023-11-13], customer_po_line: 43, extra_quantity: 43, est_total_hrs: 43, sched_end: ~D[2023-11-13], customer_po: "some updated customer_po", vendor: "some updated vendor", operation_service: "some updated operation_service", make_quantity: 43, employee: "some updated employee", note_text: "some updated note_text", order_quantity: 43, job: "some updated job", mat_vendor: "some updated mat_vendor", material_waiting: false, shipped_quantity: 43, part_number: "some updated part_number", order_date: ~D[2023-11-13], customer: "some updated customer", sequence: 43, currentop: "some updated currentop", rev: "some updated rev", status: "some updated status", job_operation: 43, job_sched_start: ~D[2023-11-13], pick_quantity: 43, wc_vendor: "some updated wc_vendor", job_sched_end: ~D[2023-11-13], open_operations: 43, complete_operations: 43, sched_start: ~D[2023-11-13], description: "some updated description", mat_description: "some updated mat_description", dots: 43}

      assert {:ok, %Runlist{} = runlist} = Shop.update_runlist(runlist, update_attrs)
      assert runlist.dots == 43
      assert runlist.mat_description == "some updated mat_description"
      assert runlist.description == "some updated description"
      assert runlist.sched_start == ~D[2023-11-13]
      assert runlist.complete_operations == 43
      assert runlist.open_operations == 43
      assert runlist.job_sched_end == ~D[2023-11-13]
      assert runlist.wc_vendor == "some updated wc_vendor"
      assert runlist.pick_quantity == 43
      assert runlist.job_sched_start == ~D[2023-11-13]
      assert runlist.job_operation == 43
      assert runlist.status == "some updated status"
      assert runlist.rev == "some updated rev"
      assert runlist.currentop == "some updated currentop"
      assert runlist.sequence == 43
      assert runlist.customer == "some updated customer"
      assert runlist.order_date == ~D[2023-11-13]
      assert runlist.part_number == "some updated part_number"
      assert runlist.shipped_quantity == 43
      assert runlist.material_waiting == false
      assert runlist.mat_vendor == "some updated mat_vendor"
      assert runlist.job == "some updated job"
      assert runlist.order_quantity == 43
      assert runlist.note_text == "some updated note_text"
      assert runlist.employee == "some updated employee"
      assert runlist.make_quantity == 43
      assert runlist.operation_service == "some updated operation_service"
      assert runlist.vendor == "some updated vendor"
      assert runlist.customer_po == "some updated customer_po"
      assert runlist.sched_end == ~D[2023-11-13]
      assert runlist.est_total_hrs == 43
      assert runlist.extra_quantity == 43
      assert runlist.customer_po_line == 43
      assert runlist.released_date == ~D[2023-11-13]
      assert runlist.material == "some updated material"
    end

    test "update_runlist/2 with invalid data returns error changeset" do
      runlist = runlist_fixture()
      assert {:error, %Ecto.Changeset{}} = Shop.update_runlist(runlist, @invalid_attrs)
      assert runlist == Shop.get_runlist!(runlist.id)
    end

    test "delete_runlist/1 deletes the runlist" do
      runlist = runlist_fixture()
      assert {:ok, %Runlist{}} = Shop.delete_runlist(runlist)
      assert_raise Ecto.NoResultsError, fn -> Shop.get_runlist!(runlist.id) end
    end

    test "change_runlist/1 returns a runlist changeset" do
      runlist = runlist_fixture()
      assert %Ecto.Changeset{} = Shop.change_runlist(runlist)
    end
  end

  describe "departments" do
    alias Shophawk.Shop.Department

    import Shophawk.ShopFixtures

    @invalid_attrs %{department: nil, capacity: nil, machine_count: nil, show_jobs_started: nil}

    test "list_departments/0 returns all departments" do
      department = department_fixture()
      assert Shop.list_departments() == [department]
    end

    test "get_department!/1 returns the department with given id" do
      department = department_fixture()
      assert Shop.get_department!(department.id) == department
    end

    test "create_department/1 with valid data creates a department" do
      valid_attrs = %{department: "some department", capacity: 120.5, machine_count: 120.5, show_jobs_started: true}

      assert {:ok, %Department{} = department} = Shop.create_department(valid_attrs)
      assert department.department == "some department"
      assert department.capacity == 120.5
      assert department.machine_count == 120.5
      assert department.show_jobs_started == true
    end

    test "create_department/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shop.create_department(@invalid_attrs)
    end

    test "update_department/2 with valid data updates the department" do
      department = department_fixture()
      update_attrs = %{department: "some updated department", capacity: 456.7, machine_count: 456.7, show_jobs_started: false}

      assert {:ok, %Department{} = department} = Shop.update_department(department, update_attrs)
      assert department.department == "some updated department"
      assert department.capacity == 456.7
      assert department.machine_count == 456.7
      assert department.show_jobs_started == false
    end

    test "update_department/2 with invalid data returns error changeset" do
      department = department_fixture()
      assert {:error, %Ecto.Changeset{}} = Shop.update_department(department, @invalid_attrs)
      assert department == Shop.get_department!(department.id)
    end

    test "delete_department/1 deletes the department" do
      department = department_fixture()
      assert {:ok, %Department{}} = Shop.delete_department(department)
      assert_raise Ecto.NoResultsError, fn -> Shop.get_department!(department.id) end
    end

    test "change_department/1 returns a department changeset" do
      department = department_fixture()
      assert %Ecto.Changeset{} = Shop.change_department(department)
    end
  end
end
