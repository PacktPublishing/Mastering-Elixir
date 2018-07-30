defmodule ElixirDrip.Storage.Workers.CacheWorker do
  use     GenServer
  require Logger

  @expire_time 60_000

  def start_link(media_id, content) do
    GenServer.start_link(__MODULE__, content, name: name_for(media_id))
  end

  def name_for(media_id), do: {:global, {:cache, media_id}}

  def init(content) do
    timer = Process.send_after(self(), :expire, @expire_time)
    Logger.debug("#{inspect(self())}: CacheWorker started.  Will expire in #{Process.read_timer(timer)} milliseconds.")

    {:ok, %{hits: 0, content: content, timer: timer}}
  end

  def handle_info(:expire, %{hits: hits} = state) do
    Logger.debug("#{inspect(self())}: Terminating process... Served the cached content #{hits} times.")
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    super(msg, state)
  end

  def get_media(pid), do: GenServer.call(pid, :get_media)

  def handle_call(:get_media, _from, %{hits: hits, content: content, timer: timer} = state) do
    Logger.debug("#{inspect(self())}: Received :get_media and served #{byte_size(content)} bytes #{hits+1} times.")

    new_timer = refresh_timer(timer)

    {:reply, {:ok, content}, %{state | hits: hits + 1, timer: new_timer}}
  end

  def refresh(pid), do: GenServer.cast(pid, :refresh)

  def handle_cast(:refresh, %{timer: timer} = state),
    do: {:noreply, %{state | timer: refresh_timer(timer)}}

  defp refresh_timer(timer) do
    Process.cancel_timer(timer)
    new_timer = Process.send_after(self(), :expire, @expire_time)
    expires_in = Process.read_timer(new_timer)

    Logger.debug("#{inspect(self())}: Canceled the previous expiration timer. Will now expire in #{expires_in} milliseconds.")

    new_timer
  end
end
