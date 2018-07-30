defmodule ElixirDrip.Storage.Pipeline.Notifier do
  @moduledoc false

  require Logger

  @dummy_state []

  use ElixirDrip.Pipeliner.Consumer, type: :consumer

  @impl ElixirDrip.Pipeliner.Consumer
  def prepare_state([]) do
    Logger.debug("#{inspect(self())}: Streamlined Pipeline Notifier started.")

    @dummy_state
  end

  @impl GenStage
  def handle_events(tasks, _from, _state) do
    Enum.each(tasks, &notify_step(&1))

    {:noreply, [], @dummy_state}
  end

  defp notify_step(%{media: media, content: content, type: :upload}) do
    # TODO: Invoke the notifier instead!
    Logger.debug("#{inspect(self())}: NOTIFICATION! Uploaded media #{media.id} to #{media.storage_key} with size: #{byte_size(content)} bytes.")
  end

  defp notify_step(%{media: %{id: id}, content: content, type: :download}) do
    # TODO: Invoke the notifier instead!
    Logger.debug("#{inspect(self())}: NOTIFICATION! Downloaded media #{id}, content: #{inspect(content)}, size: #{byte_size(content)} bytes.")
  end
end

