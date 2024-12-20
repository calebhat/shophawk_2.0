defmodule Shophawk.Inventory do
  @moduledoc """
  The Inventory context.
  """

  import Ecto.Query, warn: false
  alias Shophawk.Repo
  alias Shophawk.Inventory.Tool

  @doc """
  Returns the list of tools.

  ## Examples

      iex> list_tools()
      [%Tool{}, ...]

  """
  def list_tools do
    Repo.all(from t in Tool, order_by: [desc: t.number_of_checkouts])
  end

  @doc """
  Gets a single tool.

  Raises `Ecto.NoResultsError` if the Tool does not exist.

  ## Examples

      iex> get_tool!(123)
      %Tool{}

      iex> get_tool!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tool!(id) do
    Repo.get!(Tool, id)
  end

  @doc """
  Creates a tool.

  ## Examples

      iex> create_tool(%{field: value})
      {:ok, %Tool{}}

      iex> create_tool(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tool(attrs \\ %{}) do
    %Tool{}
    |> Tool.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tool.

  ## Examples

      iex> update_tool(tool, %{field: new_value})
      {:ok, %Tool{}}

      iex> update_tool(tool, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tool(%Tool{} = tool, attrs) do
    tool
    |> Tool.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tool.

  ## Examples

      iex> delete_tool(tool)
      {:ok, %Tool{}}

      iex> delete_tool(tool)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tool(%Tool{} = tool) do
    Repo.delete(tool)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tool changes.

  ## Examples

      iex> change_tool(tool)
      %Ecto.Changeset{data: %Tool{}}

  """
  def change_tool(%Tool{} = tool, attrs \\ %{}) do
    Tool.changeset(tool, attrs)
  end

  def search(search) do
    query =
      from t in Tool,
      where: fragment("lower(?) LIKE lower(?)", t.part_number, ^"%#{search}%")

    Repo.all(query)
  end

  def all_not_stocked?() do
    query =
      from t in Tool,
      where: t.status != "stocked"
    Repo.all(query)
  end

  def needs_restock?() do
    query =
      from t in Tool,
      where: t.status == "needs_restock"
    Repo.all(query)
  end

  def ordered?() do
    query =
      from t in Tool,
      where: t.status == "ordered"
    Repo.all(query)
  end

  def in_cart?() do
    query =
      from t in Tool,
      where: t.status == "in_cart"
    Repo.all(query)
  end

end
