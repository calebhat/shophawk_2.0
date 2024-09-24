defmodule Shophawk.MaterialTest do
  use Shophawk.DataCase

  alias Shophawk.Material

  describe "stockedmaterials" do
    alias Shophawk.Material.StockedMaterial

    import Shophawk.MaterialFixtures

    @invalid_attrs %{material: nil, bars: nil, slugs: nil}

    test "list_stockedmaterials/0 returns all stockedmaterials" do
      stocked_material = stocked_material_fixture()
      assert Material.list_stockedmaterials() == [stocked_material]
    end

    test "get_stocked_material!/1 returns the stocked_material with given id" do
      stocked_material = stocked_material_fixture()
      assert Material.get_stocked_material!(stocked_material.id) == stocked_material
    end

    test "create_stocked_material/1 with valid data creates a stocked_material" do
      valid_attrs = %{material: "some material", bars: "some bars", slugs: "some slugs"}

      assert {:ok, %StockedMaterial{} = stocked_material} = Material.create_stocked_material(valid_attrs)
      assert stocked_material.material == "some material"
      assert stocked_material.bars == "some bars"
      assert stocked_material.slugs == "some slugs"
    end

    test "create_stocked_material/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Material.create_stocked_material(@invalid_attrs)
    end

    test "update_stocked_material/2 with valid data updates the stocked_material" do
      stocked_material = stocked_material_fixture()
      update_attrs = %{material: "some updated material", bars: "some updated bars", slugs: "some updated slugs"}

      assert {:ok, %StockedMaterial{} = stocked_material} = Material.update_stocked_material(stocked_material, update_attrs)
      assert stocked_material.material == "some updated material"
      assert stocked_material.bars == "some updated bars"
      assert stocked_material.slugs == "some updated slugs"
    end

    test "update_stocked_material/2 with invalid data returns error changeset" do
      stocked_material = stocked_material_fixture()
      assert {:error, %Ecto.Changeset{}} = Material.update_stocked_material(stocked_material, @invalid_attrs)
      assert stocked_material == Material.get_stocked_material!(stocked_material.id)
    end

    test "delete_stocked_material/1 deletes the stocked_material" do
      stocked_material = stocked_material_fixture()
      assert {:ok, %StockedMaterial{}} = Material.delete_stocked_material(stocked_material)
      assert_raise Ecto.NoResultsError, fn -> Material.get_stocked_material!(stocked_material.id) end
    end

    test "change_stocked_material/1 returns a stocked_material changeset" do
      stocked_material = stocked_material_fixture()
      assert %Ecto.Changeset{} = Material.change_stocked_material(stocked_material)
    end
  end
end
