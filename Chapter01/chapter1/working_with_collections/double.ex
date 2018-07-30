defmodule Recursion do
  def double([]), do: []
  def double([head | tail]) do
    [head * 2 | double(tail)]
  end
end
