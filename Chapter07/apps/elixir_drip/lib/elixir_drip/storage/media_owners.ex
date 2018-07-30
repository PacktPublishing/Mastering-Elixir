defmodule ElixirDrip.Storage.MediaOwners do
  use Ecto.Schema

  alias ElixirDrip.Storage.{
    Media,
    Owner
  }

  schema "media_owners" do
    belongs_to :media, Media, foreign_key: :media_id, type: ElixirDrip.Ecto.Ksuid
    belongs_to :owner, Owner, foreign_key: :user_id, type: ElixirDrip.Ecto.Ksuid
    timestamps()
  end
end
