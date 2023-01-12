defmodule ElixirDrip.Storage.Workers.FlexibleSearchCacheWorker do
  @moduledoc false

  use     GenServer
  require Logger

  @search_cache :search_cache
  @expiration_secs 60

  def start_link(storage \\ :ets) do
    GenServer.start_link(__MODULE__, storage, name: __MODULE__)
  end

  def init(storage) do
    Logger.debug("#{inspect(self())}: FlexibleSearchCacheWorker started with #{storage}.")
    search_cache = case storage do
      :ets -> :ets.new(@search_cache, [:named_table, :set, :protected])
      :dets ->
        {:ok, name} = :dets.open_file(@search_cache, [type: :set])
        name
    end

    {:ok, {storage, search_cache}}
  end

  def end_worker do
    GenServer.call(__MODULE__, :stop)
  end

  def search_result_for(media_id, search_expression) do
    GenServer.call(__MODULE__, {:search_result_for, media_id, search_expression})
  end

  def all_search_results_for(media_id) do
    GenServer.call(__MODULE__, {:all_search_results_for, media_id})
  end

  def expired_search_results(expiration_secs \\ @expiration_secs) do
    GenServer.call(__MODULE__, {:expired_search_results, expiration_secs})
  end

  def cache_search_result(media_id, search_expression, result) do
    GenServer.call(__MODULE__, {:put, media_id, search_expression, result})
  end

  def delete_cache_search(media_id, search_expression) do
    GenServer.call(__MODULE__, {:delete, [{media_id, search_expression}]})
  end

  def delete_cache_search(keys) when is_list(keys) and length(keys) > 0 do
    GenServer.call(__MODULE__, {:delete, keys})
  end

  def terminate(_reason, {storage, search_cache}) do
    Logger.debug("#{inspect(self())}: FlexibleSearchCacheWorker ending now with #{storage}.")

    case storage do
      :dets ->
        storage.close(search_cache)
      _ ->
        :noop
    end
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_call({:expired_search_results, expiration_secs}, _from, {storage, search_cache}) do
    query = expired_search_results_query(expiration_secs)

    result = storage.select(search_cache, query)

    {:reply, {:ok, result}, {storage, search_cache}}
  end

  def handle_call({:all_search_results_for, media_id}, _from, {storage, search_cache}) do
    result = case storage.match_object(search_cache, {{media_id, :"_"}, :"_"}) do
      [] ->
        nil
      all_objects ->
        all_objects
        |> Enum.map(fn {key, value} ->
          {elem(key, 1), elem(value, 1)}
        end)
    end

    {:reply, {:ok, result}, {storage, search_cache}}
  end

  def handle_call({:search_result_for, media_id, search_expression}, _from, {storage, search_cache}) do
    result = case storage.lookup(search_cache, {media_id, search_expression}) do
      [] ->
        nil
      [{_key, {_created_at, search_result}}] ->
        search_result
    end

    {:reply, {:ok, result}, {storage, search_cache}}
  end

  def handle_call({:put, media_id, search_expression, result}, _from, {storage, search_cache}) do
    created_at = :os.system_time(:seconds)
    result = storage.insert_new(search_cache, {{media_id, search_expression}, {created_at, result}})

    {:reply, {:ok, result}, {storage, search_cache}}
  end

  def handle_call({:delete, keys}, _from, {storage, search_cache}) when is_list(keys) do
    result = storage
             |> delete(keys)
             |> Enum.reduce(true, fn r, acc -> r && acc end)

    {:reply, {:ok, result}, {storage, search_cache}}
  end

  defp delete(_storage, []), do: []
  defp delete(storage, [key|rest]),
    do: [delete(storage, key)] ++ delete(storage, rest)
  defp delete(storage, key), do: storage.delete(@search_cache, key)

  defp expired_search_results_query(expiration_secs) do
    expiration_time = :os.system_time(:seconds) - expiration_secs

    # :ets.fun2ms(
    #   fn {key, {created_at, result}} when created_at < expiration_time ->
    #     key
    #   end)

    [
      {
        {:"$1", {:"$2", :"_"}},
        [{:<, :"$2", {:const, expiration_time}}],
        [:"$1"]
      }
    ]
  end

end
