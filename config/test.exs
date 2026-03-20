import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :sys_fc, SysFc.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "sys_fc_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sys_fc, SysFcWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Z0vwMTU5JEbrxEecr8skYeyDua2ep5kfmkhXsrvArLg+f9yoWZWFO/fBuQyQlfy9",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :sys_fc, :jwt_secret, "test_jwt_secret_key_for_testing_only_32_chars!!"
