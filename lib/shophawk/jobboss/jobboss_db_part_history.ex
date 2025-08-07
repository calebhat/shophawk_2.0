defmodule Shophawk.Jobboss_db_parthistory do
  import Ecto.Query, warn: false
  import Shophawk.Jobboss_db
  alias DateTime
  alias Shophawk.Jb_job
  alias Shophawk.Jb_customer

  def jobs_search(params) do
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

    case params["quote"] do
      "" ->
        start_date = parse_date(params["start-date"])
        end_date = parse_date(params["end-date"])

        query =
          Jb_job
          |> maybe_filter(:customer, params["customer"])
          |> maybe_filter(:customer_po, params["customer_po"])
          |> maybe_filter_description(params["description"])
          |> maybe_filter(:job, params["job"])
          |> maybe_filter(:part_number, params["part_number"])
          |> maybe_filter(:status, params["status"])
          |> maybe_filter_date_range(start_date, end_date)
          |> order_by([desc: :order_date])
          |> limit(100)

        failsafed_query(query)
          |> Enum.map(fn op ->
            Map.from_struct(op)
            |> Map.drop([:__meta__])
            |> sanitize_map()
          end)
      _ -> []
    end
    # Convert string dates to NaiveDateTime or nil if empty/invalid

  end

  # Helper to parse date strings to NaiveDateTime or return nil
  def parse_date(""), do: nil
  def parse_date(date_str) do
    case NaiveDateTime.from_iso8601(date_str <> "T00:00:00") do
      {:ok, ndt} -> ndt
      {:error, _} -> nil
    end
  end

  # Helper to add filter for non-empty string values
  def maybe_filter(query, _field, ""), do: query
  def maybe_filter(query, field, value) when is_binary(value) do
    from r in query, where: field(r, ^field) == ^value
  end

  # Helper for multiple wildcard searches on description
  def maybe_filter_description(query, ""), do: query
  def maybe_filter_description(query, value) when is_binary(value) do
    # Remove commas, split on spaces, remove empty terms
    terms = value |> String.replace(",", "") |> String.split(" ", trim: true)
    Enum.reduce(terms, query, fn term, q ->
      from r in q, where: ilike(r.description, ^"%#{sanitize_term(term)}%")
    end)
  end

  # Sanitize term to prevent SQL injection
  def sanitize_term(term) do
    # Only allow alphanumeric and spaces; remove other characters
    String.replace(term, ~r/[^a-zA-Z0-9\s]/, "")
  end

  # Helper to add date range filter if both dates are valid
  defp maybe_filter_date_range(query, nil, _), do: query
  defp maybe_filter_date_range(query, _, nil), do: query
  defp maybe_filter_date_range(query, start_date, end_date) do
    from r in query,
      where: r.order_date >= ^start_date and r.order_date <= ^end_date
  end

  #not used?
  def load_all_customers() do
    query = from r in Jb_customer, where: r.status == "Active"
    failsafed_query(query)
    |> Enum.map(fn op ->
      Map.from_struct(op)
      |> Map.drop([:__meta__])
      |> sanitize_map()
    end)
  end

  def search_customers_by_like_name(query) do
    query_lower = String.downcase(query)
    like_query = "%#{query_lower}%"
    prefix_query = "#{query_lower}%"

    from(c in Jb_customer,
      where: ilike(c.customer, ^like_query),
      #where: c.status == "Active",
      select: c.customer,
      group_by: c.customer, # Ensure unique customer names
      # Score based on match type
      order_by: [
        desc: fragment(
          "CASE WHEN LOWER(customer) = ? THEN 3 WHEN LOWER(customer) LIKE ? THEN 2 ELSE 1 END",
          ^query_lower,
          ^prefix_query
        )
      ],
      limit: 10
    )
    |> failsafed_query(query)
    |> Enum.map(fn c -> convert_binary_to_string(c) end)
  end

  def search_part_number_by_like_name(query) do
    query_lower = String.downcase(query)
    like_query = "%#{query_lower}%"
    prefix_query = "#{query_lower}%"

    from(c in Jb_job,
      where: ilike(c.part_number, ^like_query),
      select: c.part_number,
      group_by: c.part_number, # Ensure unique customer names
      # Score based on match type
      order_by: [
        desc: fragment(
          "CASE WHEN LOWER(part_number) = ? THEN 3 WHEN LOWER(part_number) LIKE ? THEN 2 ELSE 1 END",
          ^query_lower,
          ^prefix_query
        )
      ],
      limit: 20
    )
    |> failsafed_query(query)
    |> Enum.map(fn c -> convert_binary_to_string(c) end)
  end

end
