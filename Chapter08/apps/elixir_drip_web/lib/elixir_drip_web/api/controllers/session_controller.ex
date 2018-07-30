defmodule ElixirDripWeb.Api.SessionController do
  use ElixirDripWeb, :controller

  alias ElixirDrip.Accounts
  alias ElixirDripWeb.Plugs.Auth

  def create(conn, %{"username" => username, "password" => password}) do
    with {:ok, user} <- Accounts.login_user_with_pw(username, password) do
      conn
      |> Auth.login(user)
      |> render("login.json", user: user)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ElixirDripWeb.ErrorView, "401.json", message: "Invalid username/password combination.")
        |> halt()
    end
  end

  def delete(conn, _params) do
    conn
    |> Auth.logout()
    |> render("logout.json")
  end
end
