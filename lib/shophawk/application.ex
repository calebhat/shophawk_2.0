defmodule Shophawk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    children = [
      #Create Caches needed for app
      Supervisor.child_spec({Cachex, [name: :runlist]}, id: :cachex_runlist),
      Supervisor.child_spec({Cachex, [name: :temporary_runlist_jobs_for_history, limit: 5000]}, id: :cachex_runlist_for_history),
      Supervisor.child_spec({Cachex, [name: :job_attachments]}, id: :cachex_job_attachments),
      Supervisor.child_spec({Cachex, [name: :runlist_loads]}, id: :cachex_runlist_loads),
      Supervisor.child_spec({Cachex, [name: :slideshow]}, id: :cachex_slideshow),
      Supervisor.child_spec({Cachex, [name: :employees]}, id: :cachex_employees),
      Supervisor.child_spec({Cachex, [name: :material_list]}, id: :cachex_material_list),
      Supervisor.child_spec({Cachex, [name: :delivery_list]}, id: :cachex_delivery_list),

      # Start the Telemetry supervisor
      ShophawkWeb.Telemetry,
      # Start the Ecto repository
      Shophawk.Repo,
      Shophawk.Repo_jb,

      # Start the PubSub system
      {Phoenix.PubSub, name: Shophawk.PubSub},
      # Start Finch
      {Finch, name: Shophawk.Finch},
      # Start the Endpoint (http/https)
      ShophawkWeb.Endpoint,
      # Start a worker by calling: Shophawk.Worker.start_link(arg)
      # {Shophawk.Worker, arg}

      #Started app repeating functions
      ScheduledTasks, #run initial task startup and ets initialization
      Shophawk.MaterialCache,
      Shophawk.Scheduler #to start quantum scheduling for tasks
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Shophawk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShophawkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
