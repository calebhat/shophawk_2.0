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


  def load_quotes(quotes) do
      #quotes is a list of quote structs from Jobboss_db_quote.get_quotes_by_part_number(part_number)
      quotes
      |> Enum.map(fn q ->
        quantities = get_quote_qty_by_quote_id(q.quote)
        operations = get_quote_operations_by_quote_id(q.quote)
        requirements = get_quote_requirements_by_quote_id(q.quote)
        top_level_quote = get_rfq(q.rfq)
        quote_date =
          case top_level_quote.quote_date do
            nil -> q.status_date
            _ -> top_level_quote.quote_date
          end

        Map.put(q, :quantities, quantities)
        |> Map.put(:operations, operations)
        |> Map.put(:requirements, requirements)
        |> Map.put(:id, q.quote)
        |> Map.put(:customer, top_level_quote.customer)
        |> Map.put(:quote_date, quote_date)
      end)


    #get_rfq("78853") #works

    #quotes = get_quotes_by_rfq("78853") #works
    #list_of_quotes = Enum.map(quotes, fn q -> q.quote end)
    #Enum.map(list_of_quotes, fn q ->
    #  populate_quote(q)
    #end)

  end


  def load_quote(part_number) do #not used I think
    #part_number = "341034"
    #quotes =
      get_quotes_by_part_number(part_number)
      |> Enum.map(fn q ->
        quantities = get_quote_qty_by_quote_id(q.quote)
        operations = get_quote_operations_by_quote_id(q.quote)
        requirements = get_quote_requirements_by_quote_id(q.quote)
        top_level_quote = get_rfq(q.rfq)

        Map.put(q, :quantities, quantities)
        |> Map.put(:operations, operations)
        |> Map.put(:requirements, requirements)
        |> Map.put(:id, q.quote)
        |> Map.put(:customer, top_level_quote.customer)
        |> Map.put(:quote_date, top_level_quote.quote_date)
      end)



    #get_rfq("78853") #works

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
    |> Enum.sort_by(&(&1).status_date, {:desc, Date})
  end

  def quotes_search(params) do
    #params_map =
      #%{
      #  "customer" => "",
      #  "customer_po" => "",
      #  "description" => "",
      #  "end-date" => "2000-01-12",
      #  "job" => "",
      #  "part" => "",
      #  "start-date" => "2025-06-13",
      #  "status" => ""
      #}


      #MAKE CACHEX SYSTEM FOR QUOTES SIMILAR TO JOBS

    # Convert string dates to NaiveDateTime or nil if empty/invalid
    start_date = Shophawk.Jobboss_db_parthistory.parse_date(params["start-date"])
    end_date = Shophawk.Jobboss_db_parthistory.parse_date(params["end-date"])

    query =
      Jb_Quote
      |> maybe_filter_quote_job(params["job"])
      |> Shophawk.Jobboss_db_parthistory.maybe_filter(:part_number, params["part_number"])
      |> Shophawk.Jobboss_db_parthistory.maybe_filter_description(params["description"])
      |> maybe_filter_quote_customer(params["customer"])
      |> maybe_filter_quote(params["quote"])
      #no search for customer_po, too many parts/history
      |> Shophawk.Jobboss_db_parthistory.maybe_filter(:status, params["status"])
      |> maybe_filter_date_range(start_date, end_date)
      |> order_by(desc: :rfq, asc: :line)
      |> limit(100)

    failsafed_query(query)
      |> Enum.map(fn op ->
        Map.from_struct(op)
        |> Map.drop([:__meta__])
        |> sanitize_map()
      end)
      #|> Enum.sort_by(&{(&1).rfq, (&1).line}, :desc)
  end

  defp maybe_filter_quote_customer(query, ""), do: query
  defp maybe_filter_quote_customer(query, value) do
    from(q in query,
    join: r in Jb_RFQ, on: q.rfq == r.rfq,
    where: r.customer == ^value,
    select: q
    )
  end

  defp maybe_filter_quote_job(query, ""), do: query
  defp maybe_filter_quote_job(query, value) do
    from(q in query,
    join: r in Shophawk.Jb_job, on: q.part_number == r.part_number,
    where: r.job == ^value,
    select: q
    )
  end

  defp maybe_filter_quote(query, ""), do: query
  defp maybe_filter_quote(query, value) do
    from r in query,
    where: r.rfq == ^value
  end

  defp maybe_filter_date_range(query, nil, _), do: query
  defp maybe_filter_date_range(query, _, nil), do: query
  defp maybe_filter_date_range(query, start_date, end_date) do
    from r in query,
      where: r.status_date >= ^start_date and r.status_date <= ^end_date
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

  def get_quotes_by_customer(customer) do
    from(q in Jb_Quote,
    join: r in Jb_RFQ, on: q.rfq == r.rfq,
    where: r.customer == ^customer,
    select: q
    )
    |> Shophawk.Repo_jb.all()
    |> Enum.map(fn q ->
      Map.from_struct(q)
      |> Map.drop([:__meta__,])
      |> sanitize_map()
    end)
  end

  def get_quotes_by_job(job) do
    from(q in Jb_Quote,
    join: r in Jb_job, on: q.part_number == r.part_number,
    where: r.job == ^job,
    select: q
    )
    |> Shophawk.Repo_jb.all()
    |> Enum.map(fn q ->
      Map.from_struct(q)
      |> Map.drop([:__meta__,])
      |> sanitize_map()
    end)
  end




  #WIP
  def get_quote_operations_by_quote_id(quote_id) do
    Jb_Quote_operation
    |> where([j], j.quote == ^quote_id)
    |> Shophawk.Repo_jb.all()
    |> Enum.map(fn q ->
      Map.from_struct(q)
      |> Map.drop([:__meta__,])
      |> Map.update(:run_method, "", fn r -> if r == nil, do: "", else: r end)
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
