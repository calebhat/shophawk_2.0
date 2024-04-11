defmodule ShophawkWeb.ToolLiveTest do
  use ShophawkWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shophawk.InventoryFixtures

  @create_attrs %{status: "some status", description: "some description", location: "some location", balance: 42, part_number: "some part_number", minimum: 42, vendor: "some vendor", tool_info: "some tool_info", number_of_checkouts: 42, department: "some department"}
  @update_attrs %{status: "some updated status", description: "some updated description", location: "some updated location", balance: 43, part_number: "some updated part_number", minimum: 43, vendor: "some updated vendor", tool_info: "some updated tool_info", number_of_checkouts: 43, department: "some updated department"}
  @invalid_attrs %{status: nil, description: nil, location: nil, balance: nil, part_number: nil, minimum: nil, vendor: nil, tool_info: nil, number_of_checkouts: nil, department: nil}

  defp create_tool(_) do
    tool = tool_fixture()
    %{tool: tool}
  end

  describe "Index" do
    setup [:create_tool]

    test "lists all tools", %{conn: conn, tool: tool} do
      {:ok, _index_live, html} = live(conn, ~p"/tools")

      assert html =~ "Listing Tools"
      assert html =~ tool.status
    end

    test "saves new tool", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tools")

      assert index_live |> element("a", "New Tool") |> render_click() =~
               "New Tool"

      assert_patch(index_live, ~p"/tools/new")

      assert index_live
             |> form("#tool-form", tool: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tool-form", tool: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tools")

      html = render(index_live)
      assert html =~ "Tool created successfully"
      assert html =~ "some status"
    end

    test "updates tool in listing", %{conn: conn, tool: tool} do
      {:ok, index_live, _html} = live(conn, ~p"/tools")

      assert index_live |> element("#tools-#{tool.id} a", "Edit") |> render_click() =~
               "Edit Tool"

      assert_patch(index_live, ~p"/tools/#{tool}/edit")

      assert index_live
             |> form("#tool-form", tool: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tool-form", tool: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tools")

      html = render(index_live)
      assert html =~ "Tool updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes tool in listing", %{conn: conn, tool: tool} do
      {:ok, index_live, _html} = live(conn, ~p"/tools")

      assert index_live |> element("#tools-#{tool.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#tools-#{tool.id}")
    end
  end

  describe "Show" do
    setup [:create_tool]

    test "displays tool", %{conn: conn, tool: tool} do
      {:ok, _show_live, html} = live(conn, ~p"/tools/#{tool}")

      assert html =~ "Show Tool"
      assert html =~ tool.status
    end

    test "updates tool within modal", %{conn: conn, tool: tool} do
      {:ok, show_live, _html} = live(conn, ~p"/tools/#{tool}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Tool"

      assert_patch(show_live, ~p"/tools/#{tool}/show/edit")

      assert show_live
             |> form("#tool-form", tool: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#tool-form", tool: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/tools/#{tool}")

      html = render(show_live)
      assert html =~ "Tool updated successfully"
      assert html =~ "some updated status"
    end
  end
end
