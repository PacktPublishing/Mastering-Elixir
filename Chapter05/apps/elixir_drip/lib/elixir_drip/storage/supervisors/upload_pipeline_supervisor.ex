defmodule ElixirDrip.Storage.Supervisors.Upload.Pipeline do
  @moduledoc """
  A pipeline supervisor that will spawn and supervise all the GenStage processes that compose the upload pipeline.

  Steps:
  Upload enqueued
  |> Encryption
  |> RemoteStorage
  |> Notifier
  """

  use   Supervisor
  alias ElixirDrip.Storage.Pipeline.{
    Common,
    Starter,
    Encryption,
    RemoteStorage,
    Notifier
  }

  @direction :upload
  @starter_name Common.stage_name(Starter, @direction)
  @encryption_name Common.stage_name(Encryption, @direction)
  @storage_name Common.stage_name(RemoteStorage, @direction)
  @notifier_name Common.stage_name(Notifier, @direction)

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    encryption_subscription = [subscribe_to: [{@starter_name, min_demand: 1, max_demand: 10}]]
    remote_storage_subscription = [subscribe_to: [{@encryption_name, min_demand: 1, max_demand: 10}]]
    notifier_subscription = [subscribe_to: [{@storage_name, min_demand: 1, max_demand: 10}]]

    Supervisor.init([
      worker(Starter, [@starter_name, @direction],
             restart: :permanent),

      worker(Encryption, [@encryption_name, encryption_subscription],
             restart: :permanent),

      worker(RemoteStorage, [@storage_name, remote_storage_subscription],
             restart: :permanent),

      worker(Notifier, [@notifier_name, notifier_subscription],
             restart: :permanent)
    ],
    strategy: :rest_for_one,
    name: __MODULE__
    )
  end
end
