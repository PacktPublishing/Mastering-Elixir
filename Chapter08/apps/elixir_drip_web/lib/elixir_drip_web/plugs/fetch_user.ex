defmodule ElixirDripWeb.Plugs.FetchUser do
  import Plug.Conn

  alias ElixirDrip.Accounts

  def init(options), do: options

  def call(conn, _options) do
    user_id = get_session(conn, :user_id)
    find_user(conn, user_id)
  end

  defp find_user(conn, nil), do: conn
  defp find_user(conn, user_id) do
    user = Accounts.find_user(user_id)
    assign_current_user(conn, user)
  end

  defp assign_current_user(conn, nil), do: conn
  defp assign_current_user(conn, user) do
    token = generate_token(conn, user.id)

    conn
    |> assign(:user_id, user.id)
    |> assign(:user_token, token)
    |> assign(:current_user, user)
  end

  defp generate_token(conn, user_id) do
    Phoenix.Token.sign(conn, "user socket auth", user_id)
  end
end
