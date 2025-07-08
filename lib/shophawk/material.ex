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

  def list_stockedmaterials_history do
    StockedMaterial
    |> order_by(desc: :updated_at)
    |> limit(100)
    |> Repo.all()
  end

  def list_stockedmaterials_history(material) do
    StockedMaterial
    |> where([m], m.material == ^material)
    |> order_by(desc: :updated_at)
    |> limit(100)
    |> Repo.all()
  end

  def list_material_not_used do
    Repo.all(from r in StockedMaterial, where: r.bar_used == false)
  end

  def list_material_not_used_by_material(material), do: Repo.all(from r in StockedMaterial, where: r.material == ^material and r.bar_used != true)

  def list_stockedmaterials_last_12_month_entries() do
    from_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -365, :day)

    StockedMaterial
    |> where([m], is_nil(m.purchase_price) != true)
    |> where([m], is_nil(m.original_bar_length) != true)
    |> where([m], m.inserted_at >= ^from_date)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def list_stockedmaterials_last_12_month_entries(material) do
    from_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -365, :day)

    year_history =
      StockedMaterial
      |> where([m], m.material == ^material)
      |> where([m], is_nil(m.purchase_price) != true)
      |> where([m], is_nil(m.original_bar_length) != true)
      |> where([m], m.inserted_at >= ^from_date)
      |> order_by(desc: :inserted_at)
      |> Repo.all()

    case year_history do
      [] ->
        one_bar =
          StockedMaterial
          |> where([m], m.material == ^material)
          |> where([m], not is_nil(m.purchase_price)) # Ensures purchase_price is not nil
          |> where([m], not is_nil(m.original_bar_length)) # Ensures original_bar_length is not nil
          |> order_by(asc: :inserted_at) # Sort by oldest entries first
          |> limit(1) # Limit to a single result
          |> Repo.one() # Fetch the last matching entry based on ordering

        case one_bar do
          nil -> []
          value -> [value]
        end
      _ ->
        year_history
    end


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

  def get_material_to_order_by_name(material), do: Repo.get_by!(StockedMaterial, material: material, being_quoted: false, ordered: false, in_house: false, bar_used: false)
  def get_material_waiting_on_quote_by_name(material), do: Repo.get_by!(StockedMaterial, material: material, being_quoted: true, ordered: false, in_house: false, bar_used: false)


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
    update_or_create_material(stocked_material, attrs, :update)
  end

  def update_stocked_material(%StockedMaterial{} = stocked_material, attrs, :waiting_on_quote) do
    stocked_material
    |> StockedMaterial.material_waiting_on_quote_changeset(attrs)
    |> Repo.update()
  end

  def update_stocked_material(%StockedMaterial{} = stocked_material, attrs, :receive) do
    update_or_create_material(stocked_material, attrs, :receive)
  end

  @doc """
  Deletes a stocked_material.

  ## Examples

      iex> delete_stocked_material(stocked_material)
      {:ok, %StockedMaterial{}}

      iex> delete_stocked_material(stocked_material)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stocked_material(%StockedMaterial{} = stocked_material, bypass_jobboss_save_check \\ false) do
    case bypass_jobboss_save_check do
      true ->
        Repo.delete(stocked_material)
      false ->
        {:ok, material_list} = Cachex.get(:material_list, :data)
        size_info = Enum.find_value(material_list, fn mat ->
          Enum.find(mat.sizes, fn s ->
            s.material_name == stocked_material.material
          end)
        end)

        bars =
          Shophawk.Material.list_material_not_used_by_material(stocked_material.material)
          |> Enum.filter(fn b -> b.in_house == true end)

        bars_without_current_bar_to_delete = Enum.reject(bars, fn b -> b.id == stocked_material.id end)
        on_hand_qty =
          Enum.reduce(bars_without_current_bar_to_delete, 0.0, fn bar, acc ->
            case bar.bar_length do
              nil -> acc
              length -> length + acc
            end
          end)
        if size_info != nil do
          case Shophawk.Jobboss_db.update_material(size_info, on_hand_qty + 0.01) do
            true ->
              Repo.delete(stocked_material)
              true
            _ ->
              false
          end
        else
          false
        end
    end
  end

  def update_or_create_material(stocked_material, attrs, action) do

    {:ok, material_list} = Cachex.get(:material_list, :data)
    size_info = Enum.find_value(material_list, fn mat ->
      Enum.find(mat.sizes, fn s ->
        s.material_name == stocked_material.material
      end)
    end)

    bars =
      Shophawk.Material.list_material_not_used_by_material(stocked_material.material)
      |> Enum.filter(fn b -> b.in_house == true end)

    bars_without_current_bar_to_update =
      case Map.has_key?(stocked_material, :id) do
        true -> Enum.reject(bars, fn b -> b.id == stocked_material.id end)
        _ -> bars
      end

    on_hand_qty =
      Enum.reduce(bars_without_current_bar_to_update, 0.0, fn bar, acc ->
        case bar.bar_length do
          nil -> acc
          length -> length + acc
        end
      end)
    on_hand_qty = if on_hand_qty == nil, do: 0.0, else: on_hand_qty
    on_hand_qty =
      if Map.has_key?(attrs, "bar_length") do
        bar_length =
          case Float.parse(attrs["bar_length"]) do
            {n, ""} -> n
            _ -> nil
          end
        if attrs["bar_length"] != "", do: on_hand_qty + bar_length + 0.01, else: on_hand_qty + 0.01
      else
        on_hand_qty
      end

    if size_info != nil do
      case Shophawk.Jobboss_db.update_material(size_info, on_hand_qty) do
        true ->
          case action do
            :new ->
              %StockedMaterial{}
              |> StockedMaterial.changeset_material_receiving(attrs)
              |> Repo.insert()
            :update ->
              stocked_material
              |> StockedMaterial.changeset(attrs)
              |> Repo.update()
            :receive ->
              stocked_material
              |> StockedMaterial.changeset_material_receiving(attrs)
              |> Repo.update()

          end
        _ ->
          {:jb_error, nil}
      end
    else
      {:error, nil}
    end
  end

  def make_float(string) do
    cond do
      !String.contains?(string, ".") -> String.to_float(string <> ".0")
      true -> String.to_float(string)
    end
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
