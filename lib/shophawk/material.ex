defmodule Shophawk.Material do
  @moduledoc """
  The Material context.
  """

  import Ecto.Query, warn: false
  alias Shophawk.Repo

  alias Shophawk.Material.StockedMaterial

  @doc """
  Returns the list of stockedmaterials.

  ## Examples

      iex> list_stockedmaterials()
      [%StockedMaterial{}, ...]

  """
  def list_stockedmaterials do
    Repo.all(StockedMaterial)
  end

  def list_material_not_used do
    Repo.all(from r in StockedMaterial, where: r.bar_used == false)
  end

  def list_stockedmaterials_last_12_month_entries() do
    from_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -365, :day)

    StockedMaterial
    |> where([m], is_nil(m.purchase_price) != true)
    |> where([m], m.inserted_at >= ^from_date)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_stockedmaterials_last_12_month_entries(material) do
    from_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -365, :day)

    StockedMaterial
    |> where([m], m.material == ^material)
    |> where([m], is_nil(m.purchase_price) != true)
    |> where([m], m.inserted_at >= ^from_date)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_material_needed_to_order do
    Repo.all(from r in StockedMaterial, where: r.bar_used == false and r.in_house == false and r.ordered == false and r.being_quoted == false)
  end

  def list_material_being_quoted do
    Repo.all(from r in StockedMaterial, where: r.bar_used == false and r.in_house == false and r.ordered == false and r.being_quoted == true)
  end

  def list_material_needed_to_order_and_material_being_quoted do
    Repo.all(
      from r in StockedMaterial,
      where: r.bar_used == false and r.in_house == false and r.ordered == false and r.being_quoted == false,
      or_where: r.being_quoted == true and r.bar_used == false and r.in_house == false and r.ordered == false
    )
  end

  def list_material_on_order do
    Repo.all(from r in StockedMaterial, where: r.bar_used == false and r.in_house == false and r.ordered == true and r.being_quoted == false)
  end

  def list_stocked_material_by_material(material), do: Repo.all(from r in StockedMaterial, where: r.material == ^material and r.bar_used != true)



  @doc """
  Gets a single stocked_material.

  Raises `Ecto.NoResultsError` if the Stocked material does not exist.

  ## Examples

      iex> get_stocked_material!(123)
      %StockedMaterial{}

      iex> get_stocked_material!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stocked_material!(id), do: Repo.get!(StockedMaterial, id)


  @doc """
  Creates a stocked_material.

  ## Examples

      iex> create_stocked_material(%{field: value})
      {:ok, %StockedMaterial{}}

      iex> create_stocked_material(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stocked_material(attrs \\ %{}) do
    %StockedMaterial{}
    |> StockedMaterial.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stocked_material.

  ## Examples

      iex> update_stocked_material(stocked_material, %{field: new_value})
      {:ok, %StockedMaterial{}}

      iex> update_stocked_material(stocked_material, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stocked_material(%StockedMaterial{} = stocked_material, attrs) do
    stocked_material
    |> StockedMaterial.changeset(attrs)
    |> Repo.update()
  end

  def update_stocked_material(%StockedMaterial{} = stocked_material, attrs, :waiting_on_quote) do
    stocked_material
    |> StockedMaterial.material_waiting_on_quote_changeset(attrs)
    |> Repo.update()
  end

  def update_stocked_material(%StockedMaterial{} = stocked_material, attrs, :receive) do
    stocked_material
    |> StockedMaterial.changeset_material_receiving(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stocked_material.

  ## Examples

      iex> delete_stocked_material(stocked_material)
      {:ok, %StockedMaterial{}}

      iex> delete_stocked_material(stocked_material)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stocked_material(%StockedMaterial{} = stocked_material) do
    Repo.delete(stocked_material)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stocked_material changes.

  ## Examples

      iex> change_stocked_material(stocked_material)
      %Ecto.Changeset{data: %StockedMaterial{}}

  """
  def change_stocked_material(%StockedMaterial{} = stocked_material, attrs \\ %{}) do
    StockedMaterial.changeset(stocked_material, attrs)
  end

  def change_stocked_material(%StockedMaterial{} = stocked_material, attrs, :waiting_on_quote) do
    StockedMaterial.material_waiting_on_quote_changeset(stocked_material, attrs)
  end

  def change_stocked_material(%StockedMaterial{} = stocked_material, attrs, :receive) do
    StockedMaterial.changeset_material_receiving(stocked_material, attrs)
  end


end
