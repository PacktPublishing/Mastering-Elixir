defmodule Recursion do
  def multiply([]), do: 1
  def multiply([head | tail]) do
    head * multiply(tail)
  end
end
