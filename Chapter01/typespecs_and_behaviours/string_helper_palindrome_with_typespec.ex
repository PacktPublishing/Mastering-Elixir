defmodule StringHelper do
  @spec palindrome?(String.t) :: boolean

  def palindrome?(term) do
    String.reverse(term) == term
  end
end
