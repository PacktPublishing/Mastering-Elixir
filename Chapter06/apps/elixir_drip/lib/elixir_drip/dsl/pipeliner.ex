defmodule ElixirDrip.Pipeliner do
  import Supervisor.Spec

  @pipeliner_default_count 1
  @pipeliner_default_min_demand 1
  @pipeliner_default_max_demand 10

  defmacro __using__(opts) do
    name = get_or_default(opts, :name, random_name(:pipeliner))
    default_count = get_or_default(opts, :count, @pipeliner_default_count)
    default_min_demand = get_or_default(opts, :min_demand, @pipeliner_default_min_demand)
    default_max_demand = get_or_default(opts, :max_demand, @pipeliner_default_max_demand)

    IO.puts "Building Pipeliner: #{name}"
    quote do
      use Supervisor
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :default_count, [])
      Module.register_attribute(__MODULE__, :default_min_demand, [])
      Module.register_attribute(__MODULE__, :default_max_demand, [])
      @default_count unquote(default_count)
      @default_min_demand unquote(default_min_demand)
      @default_max_demand unquote(default_max_demand)

      Module.register_attribute(__MODULE__, :pipeline_steps, accumulate: true)

      def start_link() do
        Supervisor.start_link(__MODULE__, [], name: unquote(name))
      end

      @before_compile unquote(__MODULE__)

      def init(_) do
        worker_specs_to_start = get_pipeline_steps()
                                |> pipeline_specs()

        Supervisor.init(
          worker_specs_to_start,
          strategy: :rest_for_one,
          name: __MODULE__
        )
      end
    end
  end

  defmacro __before_compile__(_environment) do
    quote do
      def get_pipeline_steps() do
        Enum.reverse(@pipeline_steps)
      end
    end
  end

  defmacro start(producer, opts \\ []) do
    quote bind_quoted: [producer: producer, opts: opts] do
      options_and_args = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      @pipeline_steps [producer: producer] ++ options_and_args
      IO.puts "START: #{producer}, #{inspect(options_and_args)}"
    end
  end

  defmacro step(producer_consumer, opts \\ []) do
    quote bind_quoted: [producer_consumer: producer_consumer, opts: opts] do
      options_and_args = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      @pipeline_steps [producer_consumer: producer_consumer] ++ options_and_args
      IO.puts "STEP: #{producer_consumer}, #{inspect(options_and_args)}"
    end
  end

  defmacro finish(consumer, opts \\ []) do
    quote bind_quoted: [consumer: consumer, opts: opts] do
      options_and_args = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      @pipeline_steps [consumer: consumer] ++ options_and_args
      IO.puts "CONSUMER: #{consumer}, #{inspect(options_and_args)}"
    end
  end

  def pipeline_specs(steps) do
    steps
    |> Enum.reduce([], fn step, worker_specs ->
      step = case Enum.empty?(worker_specs) do
        true -> step
        _    ->
          {names_to_subscribe, _} = Enum.at(worker_specs, -1)
          Enum.concat(step, names_to_subscribe: names_to_subscribe)
      end
      worker_specs ++ [get_worker_specs(step)]
    end)
    |> Enum.unzip()
    |> elem(1)
    |> List.flatten()
  end

  def get_worker_specs(producer: producer, args: args, options: options) do
    {count, _options} = Keyword.pop(options, :count)

    1..count
    |> Enum.map(fn _ ->
      name = random_name(producer)
      {name, worker(producer, args ++ [name], id: Atom.to_string(name))}
    end)
    |> Enum.unzip()
  end

  def get_worker_specs(producer_consumer: producer_consumer,
                       args: args, options: options,
                       names_to_subscribe: names_to_subscribe),
    do: get_worker_specs_with_subscriptions(producer_consumer,
                         args: args, options: options,
                         names_to_subscribe: names_to_subscribe)

  def get_worker_specs(consumer: consumer,
                       args: args, options: options,
                       names_to_subscribe: names_to_subscribe),
    do: get_worker_specs_with_subscriptions(consumer,
                         args: args, options: options,
                         names_to_subscribe: names_to_subscribe)

  defp get_worker_specs_with_subscriptions(consumer,
                       args: args, options: options,
                       names_to_subscribe: names_to_subscribe) do

    {count, options} = Keyword.pop(options, :count)

    subscriptions = names_to_subscribe
                    |> Enum.map(fn to_subscribe ->
                      {to_subscribe, options}
                    end)

    1..count
    |> Enum.map(fn _ ->
      name = random_name(consumer)
      args = args ++ [name, subscriptions]

      {name, worker(consumer, args, id: Atom.to_string(name))}
    end)
    |> Enum.unzip()
  end

  def get_options_and_args(opts, default_count, default_min_demand, default_max_demand) do
    options_and_args = fill_options_and_args(opts, default_count, default_min_demand, default_max_demand)

    options = Keyword.drop(options_and_args, [:args])
    [
      args: options_and_args[:args],
      options: options
    ]
  end

  def fill_options_and_args(options, default_count, default_min_demand, default_max_demand) do
    [{:args, []},
     {:count, default_count},
     {:min_demand, default_min_demand},
     {:max_demand, default_max_demand}]
     |> Enum.reduce([], fn {key, default}, result ->
       Keyword.put(result, key, get_or_default(options, key, default))
     end)
  end

  def get_or_default(options, _key, default \\ nil)
  def get_or_default([], _key, default), do: default
  def get_or_default(options, key, default) do
    case options[key] do
      nil   -> default
      value -> value
    end
  end

  defp random_name(name), do: Module.concat(name, random_suffix())
  defp random_suffix, do: "P" <> (:crypto.strong_rand_bytes(4) |> Base.encode16())
end
