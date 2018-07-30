defmodule ElixirDripWeb.UserSocketTest do
  use ElixirDripWeb.ChannelCase, async: true

  @subject ElixirDripWeb.UserSocket

  describe "with a valid token" do
    test "it connects to the socket" do
      token = Phoenix.Token.sign(@endpoint, "user socket auth", "13")

      assert {:ok, socket} = connect(@subject, %{"token" => token})
      assert socket.assigns.user_id == "13"
    end
  end

  describe "with an invalid token" do
    test "it doesn't connect to the socket" do
      assert :error == connect(@subject, %{"token" => "010101"})
    end
  end

  describe "without providing a token" do
    test "it doesn't connect to the socket" do
      assert :error == connect(@subject, %{})
    end
  end
end
