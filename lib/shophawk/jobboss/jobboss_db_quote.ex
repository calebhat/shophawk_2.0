defmodule Shophawk.Jobboss_db_quote do
  import Ecto.Query, warn: false
  import Shophawk.Jobboss_db
  alias DateTime
  #alias Shophawk.Jb_job_operation
  #alias Shophawk.Jb_job_qty
  #alias Shophawk.Jb_material_req
  #alias Shophawk.Jb_job_operation_time
  #alias Shophawk.Jb_material

  alias Shophawk.Jb_material_location
  alias Shophawk.Jb_RFQ
  alias Shophawk.Jb_Quote
  alias Shophawk.Jb_Quote_qty
  alias Shophawk.Jb_Quote_operation
  alias Shophawk.Jb_Quote_req


  def load_quote(part_number) do
    #part_number = "341034"
    #quotes =
      get_quotes_by_part_number(part_number)
      |> Enum.map(fn q ->
        quantities = get_quote_qty_by_quote_id(q.quote)
        operations = get_quote_operations_by_quote_id(q.quote)
        requirements = get_quote_requirements_by_quote_id(q.quote)
        top_level_quote = get_rfq(q.rfq) |> IO.inspect

        Map.put(q, :quantities, quantities)
        |> Map.put(:operations, operations)
        |> Map.put(:requirements, requirements)
        |> Map.put(:id, q.quote)
        |> Map.put(:customer, top_level_quote.customer)
        |> Map.put(:quote_date, top_level_quote.quote_date)
      end)

    #|> IO.inspect


    #get_rfq("78853") #works
    #|> IO.inspect

    #quotes = get_quotes_by_rfq("78853") #works
    #list_of_quotes = Enum.map(quotes, fn q -> q.quote end)
    #Enum.map(list_of_quotes, fn q ->
    #  populate_quote(q)
    #end)

  end

  def get_quotes_by_part_number(part_number) do
    Jb_Quote
    |> where([j], j.part_number == ^part_number)
    |> Shophawk.Repo_jb.all()
    |> Enum.map(fn q ->
      Map.from_struct(q)
      |> Map.drop([:__meta__])
      #|> rename_key(:customer_po_ln, :customer_po_line) #example to change key name
      |> sanitize_map()
    end)
  end

  def get_quote_qty_by_quote_id(quote_id) do
    Jb_Quote_qty.get_by_quote_id(quote_id)
    |> Enum.map(fn q ->
      Map.from_struct(q)
      |> Map.drop([:__meta__, :quoted_unit_price])
      |> rename_key(:quoted_unit_price_float, :quoted_unit_price)
      |> sanitize_map()
    end)
    |> Enum.sort_by(&(&1).quote_qty, :asc)
  end

  #WIP
  def get_quote_operations_by_quote_id(quote_id) do
    Jb_Quote_operation
    |> where([j], j.quote == ^quote_id)
    |> Shophawk.Repo_jb.all()
    |> Enum.map(fn q ->
      Map.from_struct(q)
      |> Map.drop([:__meta__,])
      |> sanitize_map()
    end)
    |> Enum.sort_by(&(&1.sequence), :asc)
  end

  def get_quote_requirements_by_quote_id(quote_id) do
    Jb_Quote_req
    |> where([j], j.quote == ^quote_id)
    |> Shophawk.Repo_jb.all()
    |> Enum.map(fn q ->
      Map.from_struct(q)
      |> Map.drop([:__meta__,])
      |> sanitize_map()
    end)
    |> Enum.sort_by(&(&1).material, :asc)
  end

  def get_rfq(rfq) do
    Jb_RFQ
    |> where([j], j.rfq == ^rfq)
    |> Shophawk.Repo_jb.one()
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> sanitize_map()
  end




  def get_quotes_by_rfq(rfq) do
    Jb_Quote
    |> where([j], j.rfq == ^rfq)
    |> Shophawk.Repo_jb.all()
    |> Enum.map(fn q ->
      Map.from_struct(q)
      |> Map.drop([:__meta__])
      #|> rename_key(:customer_po_ln, :customer_po_line)
      |> sanitize_map()
    end)
  end

  def load_material_stock(part_number) do
    query =
      from r in Jb_material_location,
      where: r.material == ^part_number
    failsafed_query(query)
    |> Enum.map(fn op ->
      Map.from_struct(op)
      |> Map.drop([:__meta__])
    end)
  end

  #defp populate_quote(q) do
  #  q
  #end

end
