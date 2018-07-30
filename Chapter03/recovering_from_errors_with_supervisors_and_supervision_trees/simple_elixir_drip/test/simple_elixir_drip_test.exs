defmodule SimpleElixirDripTest do
  use ExUnit.Case
  doctest SimpleElixirDrip

  test "greets the world" do
    assert SimpleElixirDrip.hello() == :world
  end
end
