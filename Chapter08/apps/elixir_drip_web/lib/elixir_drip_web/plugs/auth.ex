defmodule ElixirDripWeb.Plugs.Auth do
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2, render: 4]
  import ElixirDripWeb.Router.Helpers, only: [page_path: 2]

  def init(format), do: format

  def call(conn, format) do
    case conn.assigns[:current_user] do
      nil -> logged_out(conn, format)
      _ -> conn
    end
  end

  def login(conn, user) do
    conn
    |> put_session(:user_id, user.id)
    |> assign(:current_user, user)
    |> configure_session(renew: true)
  end

  def logout(conn), do: configure_session(conn, drop: true)

  defp logged_out(conn, :html) do
    conn
    |> put_flash(:error, "You need to be logged in to view this content.")
    |> halt()
    |> redirect(to: page_path(conn, :index))
  end

  defp logged_out(conn, :json) do
    conn
    |> put_status(:unauthorized)
    |> halt()
    |> render(ElixirDripWeb.ErrorView, "401.json", message: "Unauthenticated user.")
  end
end
