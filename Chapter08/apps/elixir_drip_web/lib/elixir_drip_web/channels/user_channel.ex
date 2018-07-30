defmodule ElixirDripWeb.UserChannel do
  use ElixirDripWeb, :channel
  alias ElixirDripWeb.{Presence, Endpoint}
  alias ElixirDrip.{Accounts, Storage}

  def join("users:lobby", _auth_message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def join("users:" <> _user_id, _auth_message, socket) do
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))

    user = Accounts.find_user(socket.assigns.user_id)

    {:ok, _} =
      Presence.track(socket, socket.assigns.user_id, %{
        username: user.username
      })

    {:noreply, socket}
  end

  def handle_in("share", %{"username" => username, "file_id" => file_id}, socket) do
    sharee = Accounts.get_user_by_username(username)
    case sharee do
      nil -> broadcast_sharee_not_found(socket, username)
      _ -> share_file(socket, socket.assigns.user_id, file_id, sharee)
    end

    {:noreply, socket}
  end

  defp share_file(socket, owner_id, file_id, sharee) do
    case Storage.share(owner_id, file_id, sharee.id) do
      {:ok, _media_owners} ->
        broadcast_to_owner(socket, sharee.username)
        broadcast_to_sharee(sharee.id, socket.assigns.user_id)
      {:error, _reason} ->
        broadcast_error_to_owner(socket, sharee.username)
    end
  end

  defp broadcast_to_owner(socket, sharee_username) do
    broadcast(socket, "share", %{message: "Successfully shared the file with #{sharee_username}."})
  end

  defp broadcast_to_sharee(sharee_user_id, owner_user_id) do
    owner = Accounts.find_user(owner_user_id)
    Endpoint.broadcast("users:#{sharee_user_id}", "share", %{message: "#{owner.username} has just shared a file with you!"})
  end

  defp broadcast_sharee_not_found(socket, username) do
    broadcast(socket, "share", %{message: "Couldn't find a user with #{username} username."})
  end

  defp broadcast_error_to_owner(socket, username) do
    broadcast(socket, "share", %{message: "Couldn't share the file with #{username}."})
  end
end
