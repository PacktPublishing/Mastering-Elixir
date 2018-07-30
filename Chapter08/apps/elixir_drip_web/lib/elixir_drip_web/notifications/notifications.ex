defmodule ElixirDripWeb.Notifications do
  use GenServer
  import ElixirDripWeb.Router.Helpers, only: [file_path: 3]
  alias ElixirDripWeb.Endpoint

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, []}
  end

  def notify(:upload, file_name, user_id) do
    GenServer.cast(__MODULE__, {:upload, file_name, user_id})
  end

  def notify(:download, id, user_id) do
    GenServer.cast(__MODULE__, {:download, id, user_id})
  end

  def handle_cast({:upload, file_name, user_id}, state) do
    Endpoint.broadcast("users:#{user_id}", "upload", %{message: "The file \"#{file_name}\" was successfully uploaded."})

    {:noreply, state}
  end

  def handle_cast({:download, id, user_id}, state) do
    link = file_path(Endpoint, :show, id) <> "/download"
    Endpoint.broadcast("users:#{user_id}", "download", %{link: link, message: "Your download is ready. Start it by clicking here."})
    {:noreply, state}
  end
end
