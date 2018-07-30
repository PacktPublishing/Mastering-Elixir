defmodule ElixirDripWeb.Router do
  use ElixirDripWeb, :router

  alias ElixirDripWeb.Plugs.FetchUser

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(FetchUser)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(FetchUser)
  end

  scope "/", ElixirDripWeb do
    pipe_through(:browser)

    resources("/files", FileController, only: [:index, :new, :create, :show])
    get("/files/:id/download", FileController, :download)
    post("/files/:id/download", FileController, :enqueue_download)

    resources("/users", UserController, only: [:new, :create])

    resources("/sessions", SessionController, only: [:new, :create])
    delete("/sessions", SessionController, :delete)

    get("/", PageController, :index)
  end

  scope "/api", ElixirDripWeb.Api, as: :api do
    pipe_through(:api)

    get("/files", FileController, :index)

    post("/sessions", SessionController, :create)
    delete("/sessions", SessionController, :delete)
  end
end
