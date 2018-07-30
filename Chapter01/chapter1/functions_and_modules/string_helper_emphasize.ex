defmodule StringHelper do
  def palindrome?(term) do
    String.reverse(term) == term
  end

  def emphasize(phrase) do
    emphasize(phrase, 3)
  end

  def emphasize(phrase, number_of_marks) do
    upcased_phrase = String.upcase(phrase)
    exclamation_marks = String.duplicate("!", number_of_marks)
    "#{upcased_phrase}#{exclamation_marks}"
  end
end
