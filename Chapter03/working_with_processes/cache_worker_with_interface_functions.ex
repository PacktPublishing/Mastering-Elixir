defmodule CacheWorker do
  require Logger

  @expire_time 60_000

  def init(content) do
    spawn(fn ->
      timer = Process.send_after(self(), :expire, @expire_time)
      Logger.debug("#{inspect(self())}: CacheWorker started.  Will expire in #{Process.read_timer(timer)} milliseconds.")
      loop(%{hits: 0, content: content, timer: timer})
    end)
  end

  def get_content(server_pid) do
    send(server_pid, {:get_content, self()})

    receive do
      {:response, content} -> content
    after
      5000 -> {:error, :timeout}
    end
  end

  def refresh(server_pid) do
    send(server_pid, :refresh)
  end

  defp loop(state) do
    new_state = receive do
      {:get_content, caller} -> get_content(state, caller)
      :refresh -> refresh_timer(state)
      :expire -> terminate(state)
      message -> unexpected_message(state, message)
    end

    loop(new_state)
  end

  defp get_content(%{content: content, hits: hits} = state, caller) do
    Logger.debug("Serving request for get_content. Content is #{content}")
    send(caller, {:response, content})
    new_state = refresh_timer(state)

    %{new_state | hits: hits + 1}
  end

  defp refresh_timer(%{timer: timer} = state) do
    Process.cancel_timer(timer)
    new_timer = Process.send_after(self(), :expire, @expire_time)
    expires_in = Process.read_timer(new_timer)
    Logger.debug("#{inspect(self())}: Canceled the previous expiration timer. Will now expire in #{expires_in} milliseconds.")

    %{state | timer: new_timer}
  end

  defp terminate(%{hits: hits}) do
    Logger.debug("#{inspect(self())}: Terminating process... Served the cached content #{hits} times.")
    Process.exit(self(), :normal)
  end

  defp unexpected_message(state, message) do
    Logger.warn("#{inspect(self())}: Received unexpected message: #{inspect(message)}")
    state
  end
end
