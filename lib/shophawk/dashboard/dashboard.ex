defmodule Shophawk.Dashboard do
  @moduledoc """
  The Inventory context.
  """
  import Ecto.Query, warn: false
  alias Shophawk.Repo
  alias DateTime
  alias Shophawk.Dashboard.Monthlysales
  alias Shophawk.Dashboard.Revenue
  alias Shophawk.Dashboard.InvoiceComments


  def list_revenue do
    Repo.all(from t in Revenue,  where: t.week > ^Date.add(Date.utc_today, -3650), order_by: [desc: t.week])
  end

  def list_revenue(date) do
    Repo.all(from t in Revenue,
    where: t.week >= ^date)
  end

  def list_monthly_sales do
    starting_date = Date.new!(Date.add(Date.utc_today, -3650).year, 1, 1)
    Repo.all(from t in Monthlysales,  where: t.date >= ^starting_date, order_by: [desc: t.date])
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
    Revenue.changeset(tool, attrs)
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

  ##### invoice functions #####

  def load_invoice_comments(invoice_numbers) do
    Repo.all(from r in InvoiceComments, where: r.invoice in ^invoice_numbers)
  end

  def get_invoice_comment(id) do
    Repo.one(from r in InvoiceComments, where: r.id == ^id)
  end

  def create_invoice_comment(attrs \\ %{}) do
    %InvoiceComments{}
    |> InvoiceComments.changeset(attrs)
    |> Repo.insert()
  end

  def delete_invoice_comment(%InvoiceComments{} = comment) do
    Repo.delete(comment)
  end

  def change_invoice_comment(%InvoiceComments{} = comment, attrs \\ %{}) do
    InvoiceComments.changeset(comment, attrs)
  end

  def update_invoice_comment(%InvoiceComments{} = comment, attrs) do
    comment
    |> InvoiceComments.changeset(attrs)
    |> Repo.update()
  end

end
