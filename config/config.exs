# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :shophawk,
  ecto_repos: [Shophawk.Repo, Shophawk.Repo_jb]

# Configures the endpoint
config :shophawk, ShophawkWeb.Endpoint,
  url: [host: "192.168.2.15"],
  render_errors: [
    formats: [html: ShophawkWeb.ErrorHTML, json: ShophawkWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Shophawk.PubSub,
  live_view: [signing_salt: "/LeNx+dk"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :shophawk, Shophawk.Mailer, adapter: Swoosh.Adapters.Local

jobs =
  [
    #Runs every 5 minutes
    #{"*/5 * * * *", {ScheduledTasks, :update_all_runlist_loads, []}},
    # Run once a day
    {"@daily", {ScheduledTasks, :load_current_week_birthdays, []}},

    # Save weekly dates once a day (around 24 hours)
    {"@daily", {ScheduledTasks, :save_weekly_dates, []}},

    #1am on the 1st of every month
    {"@daily", {ShophawkWeb.DashboardLive.Index, :save_last_months_sales, []}},

    #1am on monday of every week
    {"@daily", {ShophawkWeb.DashboardLive.Index, :save_this_weeks_revenue, []}},

    #broadcast deliveries updates
    {"*/10 * * * *", {ShophawkWeb.DeliveriesLive.Index, :load_active_deliveries, []}}

  ]

jobs =
  if System.get_env("MIX_ENV") == "prod" do
    jobs ++ [{"*/5 * * * *", {ScheduledTasks, :update_all_runlist_loads, []}}]
  else
    jobs
  end


config :shophawk, Shophawk.Scheduler, jobs: jobs

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
