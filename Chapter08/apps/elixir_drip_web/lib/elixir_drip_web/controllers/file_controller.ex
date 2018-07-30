defmodule ElixirDripWeb.FileController do
  use ElixirDripWeb, :controller

  alias ElixirDrip.Storage

  plug ElixirDripWeb.Plugs.Auth, :html when action in [:index]

  action_fallback(ElixirDripWeb.FallbackController)

  def index(conn, %{"path" => path}) do
    user = conn.assigns.current_user

    with {:ok, media} <- Storage.media_by_folder(user.id, path) do
      render(conn, "index.html", files: media.files, folders: media.folders, current_path: path)
    else
      {:error, :invalid_path} ->
        conn
        |> put_flash(:error, "The path provided is invalid.")
        |> redirect(to: file_path(conn, :index, "path": "$"))
      _ ->
        conn
        |> put_flash(:error, "Unexpected error.")
        |> redirect(to: file_path(conn, :index, "path": "$"))
    end
  end

  # def index(conn, %{"path" => path}) do
  #   user = conn.assigns.current_user

  #   with {:ok, media} <- Storage.media_by_folder(user.id, path) do
  #     render(conn, "index.html", files: media.files, folders: media.folders, current_path: path)
  #   end
  # end
  def index(conn, _params), do: redirect(conn, to: file_path(conn, :index, "path": "$"))

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, file} <- Storage.get_file_info(user.id, id) do
      render(conn, file: file)
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "File not found.")
        |> redirect(to: file_path(conn, :index, "path": "$"))
      _ ->
        conn
        |> put_flash(:error, "Unexpected error.")
        |> redirect(to: file_path(conn, :index, "path": "$"))
    end
  end
  # def show(conn, %{"id" => id}) do
  #   user = conn.assigns.current_user

  #   with {:ok, file} <- Storage.get_file_info(user.id, id) do
  #     render(conn, file: file)
  #   end
  # end

  def new(conn, %{"path" => path}) do
    render(conn, changeset: Storage.Media.create_changeset(%Storage.Media{}), path: path)
  end

  def new(conn, _params) do
    render(conn, changeset: Storage.Media.create_changeset(%Storage.Media{}), path: "$")
  end

  def create(conn, %{"file" => file_params}) do
    user = conn.assigns.current_user

    file_content =
      file_params
      |> Map.get("file")
      |> Map.get(:path)
      |> File.read!()

    with {:ok, :upload_enqueued, _changeset} <- Storage.store(user.id,  file_params["file_name"], file_params["full_path"], file_content) do
        conn
        |> put_flash(:info, "Your file upload is enqueued. A confirmation will appear shortly.")
        |> redirect(to: file_path(conn, :index, "path": file_params["full_path"]))
    else
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Unable to upload file. Please check the errors below.")
        |> render(:new, changeset: changeset, path: file_params["full_path"])
    end
  end

  def download(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    case Storage.retrieve_content(user.id, id) do
      {:ok, media, content} ->
        conn
        |> send_download({:binary, content}, filename: media.file_name)
      {:error, :media_not_found} ->
        conn
        |> put_flash(:error, "File not found.")
        |> redirect(to: file_path(conn, :index, "path": "$"))
      {:error, :content_not_found} ->
        conn
        |> put_flash(:error, "Download link has expired. Please trigger another download.")
        |> redirect(to: file_path(conn, :index, "path": "$"))
    end
  end

  def enqueue_download(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    case Storage.retrieve(user.id, id) do
      {:ok, :download_enqueued, file} ->
        conn
        |> put_flash(:info, "Download of \"#{file.name}\" is enqueued! The download link will be available soon.")
        |> redirect(to: file_path(conn, :index, "path": file.full_path))
    end
  end
end
