defmodule Shophawk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
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
      ScheduledTasks
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
