defmodule Recursion do
  def multiply(list, accum \\ 1)
  def multiply([], accum), do: accum
  def multiply([head | tail], accum) do
    multiply(tail, head * accum)
  end
end
