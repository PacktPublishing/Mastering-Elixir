defmodule SimpleElixirDrip.Storage.Supervisors.Upload.Pipeline do
  use   Supervisor
  require Logger
  alias SimpleElixirDrip.Storage.Pipeline.Encryption

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Logger.debug("#{inspect(self())} Starting the Upload Pipeline Supervisor module...")

    Supervisor.init([Encryption], strategy: :one_for_one)
  end
end
