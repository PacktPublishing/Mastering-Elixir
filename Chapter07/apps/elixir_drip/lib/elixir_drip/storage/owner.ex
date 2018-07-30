defmodule ElixirDrip.Storage.Owner do
  use Ecto.Schema

  alias ElixirDrip.Storage.{
    Media,
    MediaOwners
  }

  @primary_key {:id, ElixirDrip.Ecto.Ksuid, autogenerate: true}
  schema "users" do
    field :email, :string
    many_to_many :files, Media, join_through: MediaOwners, join_keys: [user_id: :id, media_id: :id]
  end
end
