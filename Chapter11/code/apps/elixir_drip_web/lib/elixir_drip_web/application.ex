defmodule ElixirDripWeb.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(ElixirDripWeb.Endpoint, []),
      supervisor(ElixirDripWeb.Presence, []),
      worker(ElixirDripWeb.Notifications, [])
      # Start your own worker by calling: ElixirDripWeb.Worker.start_link(arg1, arg2, arg3)
      # worker(ElixirDripWeb.Worker, [arg1, arg2, arg3]),
    ]

    ElixirDripWeb.EndpointInstrumenter.setup()
    ElixirDripWeb.PlugInstrumenter.setup()
    ElixirDripWeb.MetricsExporter.setup()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirDripWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElixirDripWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
