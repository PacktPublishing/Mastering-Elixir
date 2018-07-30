defmodule ElixirDrip.Storage.Pipeline.Common do
  @moduledoc false

  def stage_name(stage, direction) do
    direction = direction
           |> Atom.to_string()
           |> String.capitalize()

    Module.concat(stage, direction)
  end
end
