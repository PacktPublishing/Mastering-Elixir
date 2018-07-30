defmodule ElixirDrip.Storage.Pipeline.Starter do
  @moduledoc false

  use     GenStage
  require Logger
  alias   ElixirDrip.Storage.Workers.QueueWorker

  # @queue_polling 5000
  @queue_polling 30 * 1000

  def start_link(name, type) do
    GenStage.start_link(__MODULE__, type, name: name)
  end

  def init(type) do
    Logger.debug("#{inspect(self())}: #{type} Pipeline Starter started.")

    {
      :producer,
      %{queue: QueueWorker.queue_name(type), type: type, pending: 0}
    }
  end

  def handle_info(:try_again, %{queue: queue, pending: demand} = state) do
    send_events_from_queue(queue, demand, state)
  end

  def handle_demand(demand, %{queue: queue, pending: pending} = state) when demand > 0 do
    Logger.debug("#{inspect(self())}: Starter(#{inspect(queue)}) received demand of #{demand}, pending = #{pending}.")
    total_demand = demand + pending

    send_events_from_queue(queue, total_demand, state)
  end

  defp send_events_from_queue(queue, how_many, %{type: type} = state) do
    tasks = queue
            |> QueueWorker.dequeue(how_many)
            |> Enum.map(&Map.put(&1, :type, type))

    if length(tasks) > 0 do
      Logger.debug("#{inspect(self())}: Starter, will emit #{length(tasks)} tasks, :#{type} events now.")
    end

    if length(tasks) < how_many do
      Process.send_after(self(), :try_again, @queue_polling)
    end

    {:noreply, tasks, %{state | pending: how_many - length(tasks)}}
  end
end
