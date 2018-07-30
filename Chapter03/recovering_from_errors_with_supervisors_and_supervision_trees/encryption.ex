defmodule ElixirDrip.Storage.Pipeline.Encryption do
  require Logger

  def start_link() do
    pid = spawn_link(fn ->
      Logger.debug("#{inspect(self())} Starting the Encryption module...")
      loop()
    end)

    {:ok, pid}
  end

  defp loop() do
    receive do
      message -> IO.puts "#{inspect(self())} Encryption module received a message: #{message}"
    end

    loop()
  end
end
