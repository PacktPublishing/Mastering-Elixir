defmodule ElixirDripWeb.UserChannelTest do
  use ElixirDripWeb.ChannelCase

  setup [:create_users, :create_media, :connect_to_socket]

  test "join users:lobby pushes a 'presence_state' event to the joiner", %{socket: socket} do
    {:ok, _reply, _socket} = subscribe_and_join(socket, "users:lobby")

    assert_push "presence_state", %{}
  end

  test "join users:<id> broadcasts 'share' events to owner and sharee", %{socket: socket, user: user, sharee: sharee, media: media} do
    {:ok, _reply, socket} = subscribe_and_join(socket, "users:#{user.id}")
    ElixirDripWeb.Endpoint.subscribe(self(), "users:#{sharee.id}")

    push(socket, "share", %{"username" => "other_user", "file_id" => media.id})

    assert_broadcast "share", %{message: "Successfully shared the file with other_user."}
    assert_receive %Phoenix.Socket.Broadcast{
      payload: %{message: "test has just shared a file with you!"}
    }
  end

  defp create_users(_context) do
    {:ok, user} =
      ElixirDrip.Accounts.create_user(%{
        username: "test",
        password: "12345678",
        email: "test@test.com"
      })

    {:ok, sharee} =
      ElixirDrip.Accounts.create_user(%{
        username: "other_user",
        password: "12345678",
        email: "sharee@test.com"
      })

    {:ok, user: user, sharee: sharee}
  end

  defp create_media(%{user: user}) do
    {:ok, :upload_enqueued, media} = ElixirDrip.Storage.store(user.id, "test.txt", "$", "some cool content")
    {:ok, media: media}
  end

  defp connect_to_socket(%{user: user}) do
    token = Phoenix.Token.sign(@endpoint, "user socket auth", user.id)
    {:ok, socket} = connect(ElixirDripWeb.UserSocket, %{"token" => token})
    {:ok, socket: socket}
  end
end
