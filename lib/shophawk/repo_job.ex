defmodule Shophawk.Repo_jb do
  use Ecto.Repo,
    otp_app: :shophawk,
    adapter: Ecto.Adapters.Tds
end
