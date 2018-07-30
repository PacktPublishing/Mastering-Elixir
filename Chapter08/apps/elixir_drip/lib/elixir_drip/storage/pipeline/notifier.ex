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

  defp notify_step(%{media: %{id: id}, user_id: user_id, type: :download}) do
    ElixirDripWeb.Notifications.notify(:download, id, user_id)
  end

  defp notify_step(%{media: %{file_name: file_name}, user_id: user_id, type: :upload}) do
    ElixirDripWeb.Notifications.notify(:upload, file_name, user_id)
  end
end
