defmodule ShophawkWeb.TimeoffLiveTest do
  use ShophawkWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shophawk.ShopinfoFixtures

  @create_attrs %{employee: "some employee", startdate: "2024-04-30", enddate: "2024-04-30"}
  @update_attrs %{employee: "some updated employee", startdate: "2024-05-01", enddate: "2024-05-01"}
  @invalid_attrs %{employee: nil, startdate: nil, enddate: nil}

  defp create_timeoff(_) do
    timeoff = timeoff_fixture()
    %{timeoff: timeoff}
  end

  describe "Index" do
    setup [:create_timeoff]

    test "lists all timeoff", %{conn: conn, timeoff: timeoff} do
      {:ok, _index_live, html} = live(conn, ~p"/timeoff")

      assert html =~ "Listing Timeoff"
      assert html =~ timeoff.employee
    end

    test "saves new timeoff", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/timeoff")

      assert index_live |> element("a", "New Timeoff") |> render_click() =~
               "New Timeoff"

      assert_patch(index_live, ~p"/timeoff/new")

      assert index_live
             |> form("#timeoff-form", timeoff: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#timeoff-form", timeoff: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/timeoff")

      html = render(index_live)
      assert html =~ "Timeoff created successfully"
      assert html =~ "some employee"
    end

    test "updates timeoff in listing", %{conn: conn, timeoff: timeoff} do
      {:ok, index_live, _html} = live(conn, ~p"/timeoff")

      assert index_live |> element("#timeoff-#{timeoff.id} a", "Edit") |> render_click() =~
               "Edit Timeoff"

      assert_patch(index_live, ~p"/timeoff/#{timeoff}/edit")

      assert index_live
             |> form("#timeoff-form", timeoff: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#timeoff-form", timeoff: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/timeoff")

      html = render(index_live)
      assert html =~ "Timeoff updated successfully"
      assert html =~ "some updated employee"
    end

    test "deletes timeoff in listing", %{conn: conn, timeoff: timeoff} do
      {:ok, index_live, _html} = live(conn, ~p"/timeoff")

      assert index_live |> element("#timeoff-#{timeoff.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#timeoff-#{timeoff.id}")
    end
  end

  describe "Show" do
    setup [:create_timeoff]

    test "displays timeoff", %{conn: conn, timeoff: timeoff} do
      {:ok, _show_live, html} = live(conn, ~p"/timeoff/#{timeoff}")

      assert html =~ "Show Timeoff"
      assert html =~ timeoff.employee
    end

    test "updates timeoff within modal", %{conn: conn, timeoff: timeoff} do
      {:ok, show_live, _html} = live(conn, ~p"/timeoff/#{timeoff}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Timeoff"

      assert_patch(show_live, ~p"/timeoff/#{timeoff}/show/edit")

      assert show_live
             |> form("#timeoff-form", timeoff: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#timeoff-form", timeoff: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/timeoff/#{timeoff}")

      html = render(show_live)
      assert html =~ "Timeoff updated successfully"
      assert html =~ "some updated employee"
    end
  end
end
