defmodule ElixirDrip.Storage.Workers.AgentCacheWorker do
  use     Agent
  require Logger
  alias   ElixirDrip.Storage.Workers.CacheWorker

  def start_link(media_id, content) do
    Agent.start_link(fn ->
      %{hits: 0, content: content}
    end, name: CacheWorker.name_for(media_id))
  end

  def handle_info(message, state) do
    Logger.debug("#{inspect(self())} Just got an OOB message: #{message}")

    {:noreply, state}
  end

  def get_media(pid) do
    Agent.get_and_update(pid,
                         fn (%{hits: hits, content: content} = state) ->
                           Logger.debug("#{inspect(self())}: Received :get_media and served #{byte_size(content)} bytes #{hits+1} times.")
                           {state.content, %{state | hits: hits+1}}
                         end)
  end
end
