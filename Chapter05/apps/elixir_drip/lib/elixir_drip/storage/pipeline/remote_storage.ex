defmodule ElixirDrip.Storage.Pipeline.RemoteStorage do
  @moduledoc false

  use     GenStage
  require Logger
  alias   ElixirDrip.Storage
  alias   Storage.Provider
  alias   Storage.Supervisors.CacheSupervisor, as: Cache

  @dummy_state []

  def start_link(name, subscription_options),
    do: GenStage.start_link(__MODULE__, subscription_options, name: name)

  def init(subscription_options) do
    Logger.debug("#{inspect(self())}: Pipeline RemoteStorage started. Options: #{inspect(subscription_options)}")

    {:producer_consumer, @dummy_state, subscription_options}
  end

  def handle_events(tasks, _from, _state) do
    processed = Enum.map(tasks, &remote_storage_step(&1))

    {:noreply, processed, @dummy_state}
  end

  defp remote_storage_step(%{media: %{id: id, storage_key: storage_key} = media, content: content, type: :upload} = task) do
    Process.sleep(2000)

    Logger.debug("#{inspect(self())}: Uploading media #{id} to #{storage_key}, size: #{byte_size(content)} bytes.")

    {:ok, :uploaded} = Provider.upload(storage_key, content)

    %{task | media: Storage.set_upload_timestamp(media)}
  end

  defp remote_storage_step(%{media: %{id: id, storage_key: storage_key}, type: :download} = task) do
    Process.sleep(2000)

    result = case Cache.get(id) do
      nil ->
        {:ok, content} = Provider.download(storage_key)

        Logger.debug("#{inspect(self())}: Just downloaded media #{id}, content: #{inspect(content)}, size: #{byte_size(content)} bytes.")

        %{content: content}

      {:ok, content} ->
        Logger.debug("#{inspect(self())}: Got media #{id} from cache, content: #{inspect(content)}, size: #{byte_size(content)} bytes.")


        %{content: content, status: :original}
    end

    Map.merge(task, result)
  end
end

