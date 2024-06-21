defmodule Shophawk.Jobboss do
  alias Shophawk.Repo
  import Ecto.Query, warn: false

  alias Shophawk.Jb_job

  def get_job(job) do
    query =
      from r in Jb_job,
      where: r.job == ^job

    Shophawk.Repo_jb.all(query)
  end


end
