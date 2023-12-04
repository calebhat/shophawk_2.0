defmodule Shophawk.InventoryTest do
  use Shophawk.DataCase

  alias Shophawk.Inventory

  describe "tools" do
    alias Shophawk.Inventory.Tool

    import Shophawk.InventoryFixtures

    @invalid_attrs %{status: nil, description: nil, location: nil, balance: nil, part_number: nil, minimum: nil, vendor: nil, tool_info: nil, number_of_checkouts: nil, department: nil}

    test "list_tools/0 returns all tools" do
      tool = tool_fixture()
      assert Inventory.list_tools() == [tool]
    end

    test "get_tool!/1 returns the tool with given id" do
      tool = tool_fixture()
      assert Inventory.get_tool!(tool.id) == tool
    end

    test "create_tool/1 with valid data creates a tool" do
      valid_attrs = %{status: "some status", description: "some description", location: "some location", balance: 42, part_number: "some part_number", minimum: 42, vendor: "some vendor", tool_info: "some tool_info", number_of_checkouts: 42, department: "some department"}

      assert {:ok, %Tool{} = tool} = Inventory.create_tool(valid_attrs)
      assert tool.status == "some status"
      assert tool.description == "some description"
      assert tool.location == "some location"
      assert tool.balance == 42
      assert tool.part_number == "some part_number"
      assert tool.minimum == 42
      assert tool.vendor == "some vendor"
      assert tool.tool_info == "some tool_info"
      assert tool.number_of_checkouts == 42
      assert tool.department == "some department"
    end

    test "create_tool/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_tool(@invalid_attrs)
    end

    test "update_tool/2 with valid data updates the tool" do
      tool = tool_fixture()
      update_attrs = %{status: "some updated status", description: "some updated description", location: "some updated location", balance: 43, part_number: "some updated part_number", minimum: 43, vendor: "some updated vendor", tool_info: "some updated tool_info", number_of_checkouts: 43, department: "some updated department"}

      assert {:ok, %Tool{} = tool} = Inventory.update_tool(tool, update_attrs)
      assert tool.status == "some updated status"
      assert tool.description == "some updated description"
      assert tool.location == "some updated location"
      assert tool.balance == 43
      assert tool.part_number == "some updated part_number"
      assert tool.minimum == 43
      assert tool.vendor == "some updated vendor"
      assert tool.tool_info == "some updated tool_info"
      assert tool.number_of_checkouts == 43
      assert tool.department == "some updated department"
    end

    test "update_tool/2 with invalid data returns error changeset" do
      tool = tool_fixture()
      assert {:error, %Ecto.Changeset{}} = Inventory.update_tool(tool, @invalid_attrs)
      assert tool == Inventory.get_tool!(tool.id)
    end

    test "delete_tool/1 deletes the tool" do
      tool = tool_fixture()
      assert {:ok, %Tool{}} = Inventory.delete_tool(tool)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_tool!(tool.id) end
    end

    test "change_tool/1 returns a tool changeset" do
      tool = tool_fixture()
      assert %Ecto.Changeset{} = Inventory.change_tool(tool)
    end
  end
end
