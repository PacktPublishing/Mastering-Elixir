defmodule CLIPresenter do
  @behaviour Presenter

  def present(text) do
    IO.puts(text)
  end
end
