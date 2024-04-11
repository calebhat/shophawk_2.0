defmodule Shophawk.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shophawk.Inventory` context.
  """

  @doc """
  Generate a unique tool part_number.
  """
  def unique_tool_part_number, do: "some part_number#{System.unique_integer([:positive])}"

  @doc """
  Generate a tool.
  """
  def tool_fixture(attrs \\ %{}) do
    {:ok, tool} =
      attrs
      |> Enum.into(%{
        balance: 42,
        department: "some department",
        description: "some description",
        location: "some location",
        minimum: 42,
        number_of_checkouts: 42,
        part_number: unique_tool_part_number(),
        status: "some status",
        tool_info: "some tool_info",
        vendor: "some vendor"
      })
      |> Shophawk.Inventory.create_tool()

    tool
  end
end
