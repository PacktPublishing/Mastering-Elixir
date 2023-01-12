defmodule ElixirDrip.Application do
  @moduledoc """
  The ElixirDrip Application Service.

  The elixir_drip system business domain lives in this application.

  Exposes API to clients such as the `ElixirDripWeb` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  alias ElixirDrip.Storage.{
    Supervisors.CacheSupervisor,
    Workers.QueueWorker
  }
  alias ElixirDrip.Storage.Supervisors.Download.Pipeline, as: DownloadPipeline
  alias ElixirDrip.Storage.Supervisors.Upload.Pipeline, as: UploadPipeline

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link(
      [
        supervisor(ElixirDrip.Repo, []),
        supervisor(CacheSupervisor, [], name: CacheSupervisor),
        worker(QueueWorker, [:download], id: :download_queue, restart: :permanent),
        worker(QueueWorker, [:upload], id: :upload_queue, restart: :permanent),
        supervisor(DownloadPipeline, []),
        supervisor(UploadPipeline, []),
      ],
      strategy: :one_for_one,
      name: ElixirDrip.Supervisor
    )
  end
end
