defmodule ElixirDrip.StorageRepoTest do
  use ExUnit.Case, async: true

  @moduletag :repository

  @subject ElixirDrip.Storage

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ElixirDrip.Repo)
  end

  describe "when the user already uploaded some media" do
    setup [:create_user, :create_media]

    test "finds the media by ID", %{user: user, media: media} do
      {:ok, :download_enqueued, retrieved_media} = @subject.retrieve(user.id, media.id)

      expected_media_id = media.id
      assert %{full_path: "$", id: ^expected_media_id, name: "test.txt"} = retrieved_media
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

  defp create_media(%{user: user}) do
    {:ok, :upload_enqueued, media} = @subject.store(user.id, "test.txt", "$", "some cool content")
    {:ok, media: media}
  end
end
