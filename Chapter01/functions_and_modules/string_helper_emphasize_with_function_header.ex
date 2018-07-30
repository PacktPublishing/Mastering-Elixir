defmodule StringHelper do
  def palindrome?(term) do
    String.reverse(term) == term
  end

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
