defmodule ElixirDripWeb.FileControllerTest do
  use ElixirDripWeb.ConnCase, async: true

  describe "when the user is authenticated" do
    setup [:create_user, :login_user, :create_media]

    test "GET /files lists the files for the current user", %{conn: conn, media: media} do
      response = get(conn, "/files?path=$")

      assert html_response(response, 200) =~ "test.txt"
      assert html_response(response, 200) =~ "/files/#{media.id}/download"
    end
  end

  describe "when the user is NOT authenticated" do
    setup [:create_user, :create_media]

    test "GET /files redirects the user to '/'", %{conn: conn} do
      response = get(conn, "/files?path=$")

      assert html_response(response, 302) =~ "You are being <a href=\"/\">redirected</a>"
    end
  end

  defp create_user(_context) do
    {:ok, user} =
      ElixirDrip.Accounts.create_user(%{
        username: "test",
        password: "12345678",
        email: "test@test.com"
      })

    {:ok, user: user}
  end

  defp login_user(%{conn: conn, user: user}) do
    conn = Plug.Test.init_test_session(conn, user_id: user.id)
    {:ok, conn: conn}
  end

  defp create_media(%{user: user}) do
    {:ok, :upload_enqueued, media} =
      ElixirDrip.Storage.store(user.id, "test.txt", "$", "some cool content")

    {:ok, media: media}
  end
end
