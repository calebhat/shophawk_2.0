defmodule Shophawk.MSSQL do
  @moduledoc """
  Module for interacting with MSSQL directly using TDS.
  """

  alias Tds.Connection

  def query(sql_query) do
    opts = [
      hostname: "gearserver",
      instance: "SQLEXPRESS",
      username: "sa",
      password: "job1!boss",
      database: "PRODUCTION"
    ]

    {:ok, pid} = Tds.start_link(opts)
    IO.inspect(Tds.query(pid, sql_query, []))
    #case Tds.query(pid, sql_query, []) do
    #  {:ok, result} ->
    #    {:ok, result}

    #  {:error, reason} ->
    #    {:error, reason}
    #end
  end

end
