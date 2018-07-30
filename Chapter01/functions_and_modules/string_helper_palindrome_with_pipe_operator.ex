defmodule StringHelper do
  defguard is_string(term) when is_bitstring(term)

  def palindrome?(term) do
    formatted_term = term
    |> String.trim()
    |> String.downcase()
    formatted_term |> String.reverse() == formatted_term
  end
  def palindrome?(_term), do: {:error, :unsupported_type}

  def emphasize(phrase, number_of_marks \\ 3)
  def emphasize(_phrase, 0) do
    "This isn't the module you're looking for"
  end
  def emphasize(phrase, number_of_marks) do
    upcased_phrase = String.upcase(phrase)
    exclamation_marks = String.duplicate("!", number_of_marks)
    "#{upcased_phrase}#{exclamation_marks}"
  end
end
