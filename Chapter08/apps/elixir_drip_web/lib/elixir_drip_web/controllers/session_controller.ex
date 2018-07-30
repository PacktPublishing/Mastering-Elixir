defmodule ElixirDripWeb.SessionController do
  use ElixirDripWeb, :controller

  alias ElixirDrip.Accounts
  alias ElixirDripWeb.Plugs.Auth

  def new(conn, _params), do: render(conn)

  def create(conn, %{"username" => username, "password" => password}) do
    with {:ok, user} <- Accounts.login_user_with_pw(username, password) do
      conn
      |> Auth.login(user)
      |> put_flash(:info, "#{user.username}, you're now logged in. Welcome back!")
      |> redirect(to: file_path(conn, :index))
    else
      :error ->
        conn
        |> put_flash(:error, "Invalid username/password combination.")
        |> render(:new)
    end
  end

  def delete(conn, _params) do
    conn
    |> Auth.logout()
    |> redirect(to: page_path(conn, :index))
  end
end
