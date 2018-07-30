defmodule ElixirDrip.Repo.Migrations.ChangeMediaOwnersOnDeleteMedia do
  use Ecto.Migration

  def change do
    drop constraint(:media_owners, :media_owners_media_id_fkey)

    alter table(:media_owners) do
      modify :media_id, references(:storage_media, type: :string, on_delete: :delete_all)
    end
  end
end
