ExUnit.start()

Mox.defmock(ElixirDrip.Storage.Providers.GoogleCloudStorageMock, for: ElixirDrip.Behaviours.StorageProvider)

Ecto.Adapters.SQL.Sandbox.mode(ElixirDrip.Repo, :manual)
