defmodule Shophawk.MaterialFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shophawk.Material` context.
  """

  @doc """
  Generate a stocked_material.
  """
  def stocked_material_fixture(attrs \\ %{}) do
    {:ok, stocked_material} =
      attrs
      |> Enum.into(%{
        bars: "some bars",
        material: "some material",
        slugs: "some slugs"
      })
      |> Shophawk.Material.create_stocked_material()

    stocked_material
  end
end
