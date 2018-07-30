# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :elixir_drip_web,
  namespace: ElixirDripWeb,
  ecto_repos: [ElixirDrip.Repo]

# Configures the endpoint
config :elixir_drip_web, ElixirDripWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ez09L8wb/jXopY7jtFRlbEB8zb0vNAK4gfnUdwgA5kp5DUVZsz3QwxdnMs4f9cbq",
  render_errors: [view: ElixirDripWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ElixirDripWeb.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
