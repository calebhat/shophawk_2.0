# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Shophawk.Repo.insert!(%Shophawk.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Shophawk.Repo.insert!(%Shophawk.Shopinfo.Slideshow{
  workhours: "06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,06:00,16:00,false,false",
  announcement1: "",
  announcement2: "",
  announcement3: "",
  quote: "",
  photo: ""
})
