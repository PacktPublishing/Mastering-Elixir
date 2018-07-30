use Mix.Config

config :elixir_drip, storage_provider: ElixirDrip.Storage.Providers.GoogleCloudStorageMock

# Configure your database
config :elixir_drip, ElixirDrip.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  database: System.get_env("DB_NAME"),
  hostname: System.get_env("DB_HOST"),
  port: System.get_env("DB_PORT"),
  pool: Ecto.Adapters.SQL.Sandbox

config :stream_data, max_runs: 500
