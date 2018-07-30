defmodule CLIPresenter do
  @behaviour Presenter

  @impl true
  def present(text) do
    IO.puts(text)
  end
end
