defmodule Shophawk.Repo do
  use Ecto.Repo,
    otp_app: :shophawk,
    adapter: Ecto.Adapters.Postgres
end
