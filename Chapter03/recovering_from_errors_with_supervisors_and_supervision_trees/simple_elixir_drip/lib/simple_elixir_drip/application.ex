defmodule SimpleElixirDrip.Application do
  @moduledoc false

  use Application
  require Logger

  alias SimpleElixirDrip.Storage.Supervisors.CacheSupervisor
  alias SimpleElixirDrip.Storage.Supervisors.Upload.Pipeline, as: UploadPipeline

  def start(_type, _args) do
    Logger.debug("Starting the SimpleElixirDrip Supervisor...")
    Supervisor.start_link(
      [
        CacheSupervisor,
        UploadPipeline,
      ],
      strategy: :one_for_one,
      name: ElixirDrip.Supervisor
    )
  end
end
