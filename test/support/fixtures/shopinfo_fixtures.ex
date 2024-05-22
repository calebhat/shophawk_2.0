defmodule Shophawk.ShopinfoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shophawk.Shopinfo` context.
  """

  @doc """
  Generate a slideshow.
  """
  def slideshow_fixture(attrs \\ %{}) do
    {:ok, slideshow} =
      attrs
      |> Enum.into(%{
        announcement1: "some announcement1",
        announcemnet3: "some announcemnet3",
        annountment2: "some annountment2",
        photo: "some photo",
        quote: "some quote",
        workhours: "some workhours"
      })
      |> Shophawk.Shopinfo.create_slideshow()

    slideshow
  end

  @doc """
  Generate a timeoff.
  """
  def timeoff_fixture(attrs \\ %{}) do
    {:ok, timeoff} =
      attrs
      |> Enum.into(%{
        employee: "some employee",
        enddate: ~D[2024-04-30],
        startdate: ~D[2024-04-30]
      })
      |> Shophawk.Shopinfo.create_timeoff()

    timeoff
  end
end
