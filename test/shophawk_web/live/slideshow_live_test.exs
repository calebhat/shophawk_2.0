defmodule ShophawkWeb.SlideshowLiveTest do
  use ShophawkWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shophawk.ShopinfoFixtures

  @create_attrs %{quote: "some quote", workhours: "some workhours", announcement1: "some announcement1", annountment2: "some annountment2", announcemnet3: "some announcemnet3", photo: "some photo"}
  @update_attrs %{quote: "some updated quote", workhours: "some updated workhours", announcement1: "some updated announcement1", annountment2: "some updated annountment2", announcemnet3: "some updated announcemnet3", photo: "some updated photo"}
  @invalid_attrs %{quote: nil, workhours: nil, announcement1: nil, annountment2: nil, announcemnet3: nil, photo: nil}

  defp create_slideshow(_) do
    slideshow = slideshow_fixture()
    %{slideshow: slideshow}
  end

  describe "Index" do
    setup [:create_slideshow]

    test "lists all slideshow", %{conn: conn, slideshow: slideshow} do
      {:ok, _index_live, html} = live(conn, ~p"/slideshow")

      assert html =~ "Listing Slideshow"
      assert html =~ slideshow.quote
    end

    test "saves new slideshow", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/slideshow")

      assert index_live |> element("a", "New Slideshow") |> render_click() =~
               "New Slideshow"

      assert_patch(index_live, ~p"/slideshow/new")

      assert index_live
             |> form("#slideshow-form", slideshow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#slideshow-form", slideshow: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/slideshow")

      html = render(index_live)
      assert html =~ "Slideshow created successfully"
      assert html =~ "some quote"
    end

    test "updates slideshow in listing", %{conn: conn, slideshow: slideshow} do
      {:ok, index_live, _html} = live(conn, ~p"/slideshow")

      assert index_live |> element("#slideshow-#{slideshow.id} a", "Edit") |> render_click() =~
               "Edit Slideshow"

      assert_patch(index_live, ~p"/slideshow/#{slideshow}/edit")

      assert index_live
             |> form("#slideshow-form", slideshow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#slideshow-form", slideshow: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/slideshow")

      html = render(index_live)
      assert html =~ "Slideshow updated successfully"
      assert html =~ "some updated quote"
    end

    test "deletes slideshow in listing", %{conn: conn, slideshow: slideshow} do
      {:ok, index_live, _html} = live(conn, ~p"/slideshow")

      assert index_live |> element("#slideshow-#{slideshow.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#slideshow-#{slideshow.id}")
    end
  end

  describe "Show" do
    setup [:create_slideshow]

    test "displays slideshow", %{conn: conn, slideshow: slideshow} do
      {:ok, _show_live, html} = live(conn, ~p"/slideshow/#{slideshow}")

      assert html =~ "Show Slideshow"
      assert html =~ slideshow.quote
    end

    test "updates slideshow within modal", %{conn: conn, slideshow: slideshow} do
      {:ok, show_live, _html} = live(conn, ~p"/slideshow/#{slideshow}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Slideshow"

      assert_patch(show_live, ~p"/slideshow/#{slideshow}/show/edit")

      assert show_live
             |> form("#slideshow-form", slideshow: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#slideshow-form", slideshow: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/slideshow/#{slideshow}")

      html = render(show_live)
      assert html =~ "Slideshow updated successfully"
      assert html =~ "some updated quote"
    end
  end
end
