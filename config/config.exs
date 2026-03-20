# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :sys_fc,
  ecto_repos: [SysFc.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configure the endpoint
config :sys_fc, SysFcWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: SysFcWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SysFc.PubSub,
  live_view: [signing_salt: "mS96S810"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# JWT secret — sobrescrito por ambiente (dev.exs, test.exs, runtime.exs)
config :sys_fc, :jwt_secret, "CHANGE_ME_IN_PRODUCTION"
config :sys_fc, :jwt_expiry_seconds, 60 * 60 * 24 * 7  # 7 dias

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
