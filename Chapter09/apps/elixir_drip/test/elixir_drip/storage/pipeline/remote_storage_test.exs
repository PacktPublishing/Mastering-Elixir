defmodule ElixirDrip.Storage.Pipeline.RemoteStorageTest do
  use ExUnit.Case, async: true
  import Mox

  alias ElixirDrip.Storage.Providers.GoogleCloudStorageMock

  @subject ElixirDrip.Storage.Pipeline.RemoteStorage

  setup :verify_on_exit!

  test "on upload it calls the GoogleCloudStorage client with the right arguments" do
    expect(GoogleCloudStorageMock, :upload, fn "test_key", "test_content" -> {:ok, :uploaded} end)

    task = %{type: :upload, media: %{id: "test_id", storage_key: "test_key"}, content: "test_content"}
    @subject.handle_events([task], nil, nil)
  end
end
