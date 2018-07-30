defmodule ElixirDrip.Storage.Supervisors.Upload.Pipeline do
  use   Supervisor
  require Logger
  alias ElixirDrip.Storage.Pipeline.Encryption

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    Logger.debug("#{inspect(self())} Starting the Upload Pipeline Supervisor module...")

    Supervisor.init([Encryption], strategy: :one_for_one)
  end
end
