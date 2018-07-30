defmodule ElixirDripWeb.Api.FileView do
  use ElixirDripWeb, :view

  def render("index.json", %{files: files, folders: folders}) do
    %{
      response: %{
        files: render_many(files, __MODULE__, "file.json"),
        folders: render_many(folders, __MODULE__, "folder.json", as: :folder)
      }
    }
  end

  def render("file.json", %{file: file}) do
    %{id: file.id, name: file.name, full_path: file.full_path, size: file.size}
  end

  def render("folder.json", %{folder: folder}) do
    %{name: folder.name, size: folder.size, files: folder.files}
  end
end
