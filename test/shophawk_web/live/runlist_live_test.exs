defmodule ShophawkWeb.RunlistLiveTest do
  use ShophawkWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shophawk.ShopFixtures

  @create_attrs %{material: "some material", released_date: "2023-11-12", customer_po_line: 42, extra_quantity: 42, est_total_hrs: 42, sched_end: "2023-11-12", customer_po: "some customer_po", vendor: "some vendor", operation_service: "some operation_service", make_quantity: 42, employee: "some employee", note_text: "some note_text", order_quantity: 42, job: "some job", mat_vendor: "some mat_vendor", material_waiting: true, shipped_quantity: 42, part_number: "some part_number", order_date: "2023-11-12", customer: "some customer", sequence: 42, currentop: "some currentop", rev: "some rev", status: "some status", job_operation: 42, job_sched_start: "2023-11-12", pick_quantity: 42, wc_vendor: "some wc_vendor", job_sched_end: "2023-11-12", open_operations: 42, complete_operations: 42, sched_start: "2023-11-12", description: "some description", mat_description: "some mat_description", dots: 42}
  @update_attrs %{material: "some updated material", released_date: "2023-11-13", customer_po_line: 43, extra_quantity: 43, est_total_hrs: 43, sched_end: "2023-11-13", customer_po: "some updated customer_po", vendor: "some updated vendor", operation_service: "some updated operation_service", make_quantity: 43, employee: "some updated employee", note_text: "some updated note_text", order_quantity: 43, job: "some updated job", mat_vendor: "some updated mat_vendor", material_waiting: false, shipped_quantity: 43, part_number: "some updated part_number", order_date: "2023-11-13", customer: "some updated customer", sequence: 43, currentop: "some updated currentop", rev: "some updated rev", status: "some updated status", job_operation: 43, job_sched_start: "2023-11-13", pick_quantity: 43, wc_vendor: "some updated wc_vendor", job_sched_end: "2023-11-13", open_operations: 43, complete_operations: 43, sched_start: "2023-11-13", description: "some updated description", mat_description: "some updated mat_description", dots: 43}
  @invalid_attrs %{material: nil, released_date: nil, customer_po_line: nil, extra_quantity: nil, est_total_hrs: nil, sched_end: nil, customer_po: nil, vendor: nil, operation_service: nil, make_quantity: nil, employee: nil, note_text: nil, order_quantity: nil, job: nil, mat_vendor: nil, material_waiting: false, shipped_quantity: nil, part_number: nil, order_date: nil, customer: nil, sequence: nil, currentop: nil, rev: nil, status: nil, job_operation: nil, job_sched_start: nil, pick_quantity: nil, wc_vendor: nil, job_sched_end: nil, open_operations: nil, complete_operations: nil, sched_start: nil, description: nil, mat_description: nil, dots: nil}

  defp create_runlist(_) do
    runlist = runlist_fixture()
    %{runlist: runlist}
  end

  describe "Index" do
    setup [:create_runlist]

    test "lists all runlists", %{conn: conn, runlist: runlist} do
      {:ok, _index_live, html} = live(conn, ~p"/runlists")

      assert html =~ "Listing Runlists"
      assert html =~ runlist.material
    end

    test "saves new runlist", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/runlists")

      assert index_live |> element("a", "New Runlist") |> render_click() =~
               "New Runlist"

      assert_patch(index_live, ~p"/runlists/new")

      assert index_live
             |> form("#runlist-form", runlist: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#runlist-form", runlist: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/runlists")

      html = render(index_live)
      assert html =~ "Runlist created successfully"
      assert html =~ "some material"
    end

    test "updates runlist in listing", %{conn: conn, runlist: runlist} do
      {:ok, index_live, _html} = live(conn, ~p"/runlists")

      assert index_live |> element("#runlists-#{runlist.id} a", "Edit") |> render_click() =~
               "Edit Runlist"

      assert_patch(index_live, ~p"/runlists/#{runlist}/edit")

      assert index_live
             |> form("#runlist-form", runlist: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#runlist-form", runlist: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/runlists")

      html = render(index_live)
      assert html =~ "Runlist updated successfully"
      assert html =~ "some updated material"
    end

    test "deletes runlist in listing", %{conn: conn, runlist: runlist} do
      {:ok, index_live, _html} = live(conn, ~p"/runlists")

      assert index_live |> element("#runlists-#{runlist.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#runlists-#{runlist.id}")
    end
  end

  describe "Show" do
    setup [:create_runlist]

    test "displays runlist", %{conn: conn, runlist: runlist} do
      {:ok, _show_live, html} = live(conn, ~p"/runlists/#{runlist}")

      assert html =~ "Show Runlist"
      assert html =~ runlist.material
    end

    test "updates runlist within modal", %{conn: conn, runlist: runlist} do
      {:ok, show_live, _html} = live(conn, ~p"/runlists/#{runlist}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Runlist"

      assert_patch(show_live, ~p"/runlists/#{runlist}/show/edit")

      assert show_live
             |> form("#runlist-form", runlist: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#runlist-form", runlist: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/runlists/#{runlist}")

      html = render(show_live)
      assert html =~ "Runlist updated successfully"
      assert html =~ "some updated material"
    end
  end
end
