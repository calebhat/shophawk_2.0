defmodule Shophawk.Dashboard do
  @moduledoc """
  The Inventory context.
  """
  import Ecto.Query, warn: false
  alias Shophawk.Repo
  alias DateTime
  alias Shophawk.Dashboard.Monthlysales
  alias Shophawk.Dashboard.Revenue


  def list_revenue do
    Repo.all(from t in Revenue,  where: t.week > ^Date.add(Date.utc_today, -3650), order_by: [desc: t.week])
  end

  def list_revenue(date) do
    Repo.all(from t in Revenue,
    where: t.week >= ^date)
  end

  def list_monthly_sales do
    Repo.all(from t in Monthlysales,  where: t.date > ^Date.add(Date.utc_today, -3650), order_by: [desc: t.date])
  end

  def list_monthly_sales(date) do
    Repo.all(from t in Monthlysales,
    where: t.date == ^date)
  end

  def get_revenue!(id) do
    Repo.get!(Revenue, id)
  end

  #field :total_revenue, :float
  #field :six_week_revenue, :float
  #field :total_jobs, :integer
  def create_revenue(attrs \\ %{}) do
    %Revenue{}
    |> Revenue.changeset(attrs)
    |> Repo.insert()
  end

  #field :date, :naive_datetime
  #field :amount, :float
  def create_monthly_sales(attrs \\ %{}) do
    %Monthlysales{}
    |> Monthlysales.changeset(attrs)
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
  def update_revenue(%Revenue{} = tool, attrs) do
    tool
    |> Revenue.changeset(attrs)
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
  def delete_revenue(%Revenue{} = tool) do
    Repo.delete(tool)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tool changes.

  ## Examples

      iex> change_tool(tool)
      %Ecto.Changeset{data: %Tool{}}

  """
  def change_tool(%Revenue{} = tool, attrs \\ %{}) do
    Tool.changeset(tool, attrs)
  end

  def search(search) do
    query =
      from t in Revenue,
      where: fragment("lower(?) LIKE lower(?)", t.part_number, ^"%#{search}%")

    Repo.all(query)
  end

  def needs_restock?() do
    query =
      from t in Revenue,
      where: t.status == "needs restock"
    Repo.all(query)
  end

  def ordered?() do
    query =
      from t in Revenue,
      where: t.status == "ordered"
    Repo.all(query)
  end

  def in_cart?() do
    query =
      from t in Revenue,
      where: t.status == "in cart"
    Repo.all(query)
  end

end
