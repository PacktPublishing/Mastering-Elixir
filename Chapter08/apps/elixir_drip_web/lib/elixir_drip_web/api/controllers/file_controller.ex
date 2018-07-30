defmodule ElixirDripWeb.Api.FileController do
  use ElixirDripWeb, :controller

  alias ElixirDrip.Storage

  plug ElixirDripWeb.Plugs.Auth, :json

  def index(conn, %{"path" => path}) do
    user = conn.assigns.current_user
    with {:ok, media} <- Storage.media_by_folder(user.id, path) do
      render(conn, files: media.files, folders: media.folders)
    else
      {:error, :invalid_path} ->
        render(conn, ElixirDripWeb.ErrorView, "400.json", message: "The path provided is invalid.")
    end
  end

  def index(conn, _params), do: render(conn, ElixirDripWeb.ErrorView, "400.json", message: "Missing 'path' query parameter")
end
