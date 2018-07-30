defmodule ElixirDrip.Pipeliner.Producer do
  import ElixirDrip.Pipeliner

  @callback prepare_state(list(any)) :: any

  defmacro __using__(opts) do
    args = get_or_default(opts, :args, [])

    optional_args = create_args(__MODULE__, args)
    required_args = create_args(__MODULE__, [:name])

    function_args = optional_args ++ required_args

    quote do
      use GenStage
      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)
      @behaviour GenStage

      def start_link(unquote_splicing(function_args)) do
        GenStage.start_link(__MODULE__, unquote(optional_args), name: name)
      end

      @impl GenStage
      def init([unquote_splicing(optional_args)]) do
        args = prepare_state(unquote(optional_args))

        {:producer, args}
      end

      def prepare_state(args), do: args

      defoverridable unquote(__MODULE__)
    end
  end

  defp create_args(_, []), do: []
  defp create_args(module, arg_names),
    do: Enum.map(arg_names, &Macro.var(&1, module))
end
