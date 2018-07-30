defmodule MeasuredModuleExpanded do
  alias ElixirDrip.Chronometer

  function_definition = {:slow_square, [], [{:\\, [], [{:x, [], nil}, 3]}]}
  body = {:__block__, [], [{{:., [], [{:__aliases__, [], [:Process]}, :sleep]}, [], [2000]}, {:*, [], [{:x, [], nil}, {:x, [], nil}]}]}
  function = :slow_square
  arity = 1

  def(unquote(function_definition)) do
    signature =
      Chronometer.pretty_signature(__MODULE__, unquote(function), unquote(arity))
    Chronometer.run_and_measure(signature, fn -> unquote(body) end)
  end
end
