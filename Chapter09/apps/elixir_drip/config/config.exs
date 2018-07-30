use Mix.Config

config :elixir_drip, ecto_repos: [ElixirDrip.Repo]

config :elixir_drip, storage_provider: ElixirDrip.Storage.Providers.GoogleCloudStorageLive

config :arc,
  storage: Arc.Storage.GCS,
  bucket: "elixir-drip-andre-development",
  storage_dir: "v1"

config :goth,
  config_module: ElixirDrip.Config.GcsCredentials

config :distillery,
  # bcrypt_elixir depends on this, only in build time
  # doesn't make sense to include it in the release
  no_warn_missing: [:elixir_make]

import_config "#{Mix.env()}.exs"
