defmodule ShophawkWeb.DashboardLive.Index do
  use ShophawkWeb, :live_view
  alias Shophawk.Jobboss_db
  import Number.Currency

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      #socket = load_checkbook(socket)
      #{:ok, socket}
      {:ok, socket |> assign(:checkbook_entries, [])
      |> assign(:current_balance, "Loading...")
      |> assign(:open_invoices, %{})
      }
    else
      {:ok, socket
      |> assign(:checkbook_entries, [])
      |> assign(:current_balance, "Loading...")
      |> assign(:open_invoices, %{})
      }
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Dashboard")
  end

  def load_checkbook(socket) do
    bank_statements =
      Jobboss_db.bank_statements
      |> Enum.reverse

    last_statement = List.first(bank_statements)
    ending_balance = last_statement.ending_balance


    {:ok, days_to_load} = NaiveDateTime.new(Date.add(last_statement.statement_date, -30), ~T[00:00:00.000])

    checkbook_entries = #journal entries from 30 days before last bank statement
      Jobboss_db.journal_entry(days_to_load, NaiveDateTime.utc_now())
      |> Enum.map(fn entry -> if entry.reference == "9999", do: Map.put(entry, :reference, "9999 - ACH Check"), else: entry end)
      |> Enum.reverse

    current_balance =
      Enum.filter(checkbook_entries, fn entry -> Date.after?(entry.transaction_date, last_statement.statement_date) end)
      |> Enum.reduce(ending_balance, fn entry, acc ->
        acc + entry.amount
      end)
      |> Float.round(2)
      |> number_to_currency

      socket
      |> assign(:current_balance, current_balance)
      |> assign(:checkbook_entries, checkbook_entries)
  end

  def get_open_invoices(socket) do
    open_invoices = Jobboss_db.open_invoices
    socket = assign(socket, :open_invoices, open_invoices)
  end

  defp change_bg_color_if_late(is_late, column, actual_column) do
    if is_late == true and column == actual_column do
      "bg-pink-900 text-stone-100"
    else
      ""
    end
  end

  def handle_event("test_click", _params, socket) do

    socket = get_open_invoices(socket)

    {:noreply, socket}
  end

end
