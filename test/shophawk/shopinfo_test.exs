defmodule Shophawk.ShopinfoTest do
  use Shophawk.DataCase

  alias Shophawk.Shopinfo

  describe "slideshow" do
    alias Shophawk.Shopinfo.Slideshow

    import Shophawk.ShopinfoFixtures

    @invalid_attrs %{quote: nil, workhours: nil, announcement1: nil, annountment2: nil, announcemnet3: nil, photo: nil}

    test "list_slideshow/0 returns all slideshow" do
      slideshow = slideshow_fixture()
      assert Shopinfo.list_slideshow() == [slideshow]
    end

    test "get_slideshow!/1 returns the slideshow with given id" do
      slideshow = slideshow_fixture()
      assert Shopinfo.get_slideshow!(slideshow.id) == slideshow
    end

    test "create_slideshow/1 with valid data creates a slideshow" do
      valid_attrs = %{quote: "some quote", workhours: "some workhours", announcement1: "some announcement1", annountment2: "some annountment2", announcemnet3: "some announcemnet3", photo: "some photo"}

      assert {:ok, %Slideshow{} = slideshow} = Shopinfo.create_slideshow(valid_attrs)
      assert slideshow.quote == "some quote"
      assert slideshow.workhours == "some workhours"
      assert slideshow.announcement1 == "some announcement1"
      assert slideshow.annountment2 == "some annountment2"
      assert slideshow.announcemnet3 == "some announcemnet3"
      assert slideshow.photo == "some photo"
    end

    test "create_slideshow/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shopinfo.create_slideshow(@invalid_attrs)
    end

    test "update_slideshow/2 with valid data updates the slideshow" do
      slideshow = slideshow_fixture()
      update_attrs = %{quote: "some updated quote", workhours: "some updated workhours", announcement1: "some updated announcement1", annountment2: "some updated annountment2", announcemnet3: "some updated announcemnet3", photo: "some updated photo"}

      assert {:ok, %Slideshow{} = slideshow} = Shopinfo.update_slideshow(slideshow, update_attrs)
      assert slideshow.quote == "some updated quote"
      assert slideshow.workhours == "some updated workhours"
      assert slideshow.announcement1 == "some updated announcement1"
      assert slideshow.annountment2 == "some updated annountment2"
      assert slideshow.announcemnet3 == "some updated announcemnet3"
      assert slideshow.photo == "some updated photo"
    end

    test "update_slideshow/2 with invalid data returns error changeset" do
      slideshow = slideshow_fixture()
      assert {:error, %Ecto.Changeset{}} = Shopinfo.update_slideshow(slideshow, @invalid_attrs)
      assert slideshow == Shopinfo.get_slideshow!(slideshow.id)
    end

    test "delete_slideshow/1 deletes the slideshow" do
      slideshow = slideshow_fixture()
      assert {:ok, %Slideshow{}} = Shopinfo.delete_slideshow(slideshow)
      assert_raise Ecto.NoResultsError, fn -> Shopinfo.get_slideshow!(slideshow.id) end
    end

    test "change_slideshow/1 returns a slideshow changeset" do
      slideshow = slideshow_fixture()
      assert %Ecto.Changeset{} = Shopinfo.change_slideshow(slideshow)
    end
  end

  describe "timeoff" do
    alias Shophawk.Shopinfo.Timeoff

    import Shophawk.ShopinfoFixtures

    @invalid_attrs %{employee: nil, startdate: nil, enddate: nil}

    test "list_timeoff/0 returns all timeoff" do
      timeoff = timeoff_fixture()
      assert Shopinfo.list_timeoff() == [timeoff]
    end

    test "get_timeoff!/1 returns the timeoff with given id" do
      timeoff = timeoff_fixture()
      assert Shopinfo.get_timeoff!(timeoff.id) == timeoff
    end

    test "create_timeoff/1 with valid data creates a timeoff" do
      valid_attrs = %{employee: "some employee", startdate: ~D[2024-04-30], enddate: ~D[2024-04-30]}

      assert {:ok, %Timeoff{} = timeoff} = Shopinfo.create_timeoff(valid_attrs)
      assert timeoff.employee == "some employee"
      assert timeoff.startdate == ~D[2024-04-30]
      assert timeoff.enddate == ~D[2024-04-30]
    end

    test "create_timeoff/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shopinfo.create_timeoff(@invalid_attrs)
    end

    test "update_timeoff/2 with valid data updates the timeoff" do
      timeoff = timeoff_fixture()
      update_attrs = %{employee: "some updated employee", startdate: ~D[2024-05-01], enddate: ~D[2024-05-01]}

      assert {:ok, %Timeoff{} = timeoff} = Shopinfo.update_timeoff(timeoff, update_attrs)
      assert timeoff.employee == "some updated employee"
      assert timeoff.startdate == ~D[2024-05-01]
      assert timeoff.enddate == ~D[2024-05-01]
    end

    test "update_timeoff/2 with invalid data returns error changeset" do
      timeoff = timeoff_fixture()
      assert {:error, %Ecto.Changeset{}} = Shopinfo.update_timeoff(timeoff, @invalid_attrs)
      assert timeoff == Shopinfo.get_timeoff!(timeoff.id)
    end

    test "delete_timeoff/1 deletes the timeoff" do
      timeoff = timeoff_fixture()
      assert {:ok, %Timeoff{}} = Shopinfo.delete_timeoff(timeoff)
      assert_raise Ecto.NoResultsError, fn -> Shopinfo.get_timeoff!(timeoff.id) end
    end

    test "change_timeoff/1 returns a timeoff changeset" do
      timeoff = timeoff_fixture()
      assert %Ecto.Changeset{} = Shopinfo.change_timeoff(timeoff)
    end
  end
end
