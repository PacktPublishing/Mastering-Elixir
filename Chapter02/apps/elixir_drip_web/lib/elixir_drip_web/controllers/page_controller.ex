defmodule ElixirDripWeb.PageController do
  use ElixirDripWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
