defmodule ElixirDrip.Instrumenter do
  use Prometheus

  @histograms %{
    "storage_store" => "Time histogram for the Storage.store/4 function"
  }

  @counters %{
    "cache_worker_hit" => "Counter for each download served by the CacheWorker instead of relying on the Cloud provider"
  }

  @default_buckets :prometheus_http.microseconds_duration_buckets()

  def setup do
    @histograms
    |> Enum.map(&__MODULE__.histogram_config(&1, @default_buckets))
    |> Enum.each(&Histogram.new(&1))

    @counters
    |> Enum.map(&__MODULE__.counter_config(&1))
    |> Enum.each(&Counter.new(&1))
  end

  @counters
  |> Enum.map(&elem(&1, 0))
  |> Enum.map(&String.to_atom(&1))
  |> Enum.map(fn counter ->
    def count(unquote(counter)), do: count(unquote(counter), 1)
    def count(unquote(counter), count), do: Counter.count([name: __MODULE__.counter_name(unquote(counter))], count)
  end)

  @histograms
  |> Enum.map(&elem(&1, 0))
  |> Enum.map(&String.to_atom(&1))
  |> Enum.map(fn histogram ->
    def observe(unquote(histogram), value), do: Histogram.observe([name: __MODULE__.histogram_name(unquote(histogram))], value)

    def observe_duration(unquote(histogram), body), do: Histogram.observe_duration([name: __MODULE__.histogram_name(unquote(histogram))], body.())
  end)

  def counter_config({name, help}), do: [name: counter_name(name), help: help]
  def histogram_config({name, help}, buckets), do: [name: histogram_name(name), help: help, buckets: buckets]

  def counter_name(name),
    do: "elixir_drip_" <> to_string(name) <> "_count" |> String.to_atom()
  def histogram_name(name),
    do: "elixir_drip_" <> to_string(name) <> "_microseconds" |> String.to_atom()
end
