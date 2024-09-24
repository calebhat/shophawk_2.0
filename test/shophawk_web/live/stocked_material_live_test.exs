defmodule ShophawkWeb.StockedMaterialLiveTest do
  use ShophawkWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shophawk.MaterialFixtures

  @create_attrs %{material: "some material", bars: "some bars", slugs: "some slugs"}
  @update_attrs %{material: "some updated material", bars: "some updated bars", slugs: "some updated slugs"}
  @invalid_attrs %{material: nil, bars: nil, slugs: nil}

  defp create_stocked_material(_) do
    stocked_material = stocked_material_fixture()
    %{stocked_material: stocked_material}
  end

  describe "Index" do
    setup [:create_stocked_material]

    test "lists all stockedmaterials", %{conn: conn, stocked_material: stocked_material} do
      {:ok, _index_live, html} = live(conn, ~p"/stockedmaterials")

      assert html =~ "Listing Stockedmaterials"
      assert html =~ stocked_material.material
    end

    test "saves new stocked_material", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/stockedmaterials")

      assert index_live |> element("a", "New Stocked material") |> render_click() =~
               "New Stocked material"

      assert_patch(index_live, ~p"/stockedmaterials/new")

      assert index_live
             |> form("#stocked_material-form", stocked_material: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#stocked_material-form", stocked_material: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/stockedmaterials")

      html = render(index_live)
      assert html =~ "Stocked material created successfully"
      assert html =~ "some material"
    end

    test "updates stocked_material in listing", %{conn: conn, stocked_material: stocked_material} do
      {:ok, index_live, _html} = live(conn, ~p"/stockedmaterials")

      assert index_live |> element("#stockedmaterials-#{stocked_material.id} a", "Edit") |> render_click() =~
               "Edit Stocked material"

      assert_patch(index_live, ~p"/stockedmaterials/#{stocked_material}/edit")

      assert index_live
             |> form("#stocked_material-form", stocked_material: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#stocked_material-form", stocked_material: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/stockedmaterials")

      html = render(index_live)
      assert html =~ "Stocked material updated successfully"
      assert html =~ "some updated material"
    end

    test "deletes stocked_material in listing", %{conn: conn, stocked_material: stocked_material} do
      {:ok, index_live, _html} = live(conn, ~p"/stockedmaterials")

      assert index_live |> element("#stockedmaterials-#{stocked_material.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#stockedmaterials-#{stocked_material.id}")
    end
  end

  describe "Show" do
    setup [:create_stocked_material]

    test "displays stocked_material", %{conn: conn, stocked_material: stocked_material} do
      {:ok, _show_live, html} = live(conn, ~p"/stockedmaterials/#{stocked_material}")

      assert html =~ "Show Stocked material"
      assert html =~ stocked_material.material
    end

    test "updates stocked_material within modal", %{conn: conn, stocked_material: stocked_material} do
      {:ok, show_live, _html} = live(conn, ~p"/stockedmaterials/#{stocked_material}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Stocked material"

      assert_patch(show_live, ~p"/stockedmaterials/#{stocked_material}/show/edit")

      assert show_live
             |> form("#stocked_material-form", stocked_material: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#stocked_material-form", stocked_material: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/stockedmaterials/#{stocked_material}")

      html = render(show_live)
      assert html =~ "Stocked material updated successfully"
      assert html =~ "some updated material"
    end
  end
end
