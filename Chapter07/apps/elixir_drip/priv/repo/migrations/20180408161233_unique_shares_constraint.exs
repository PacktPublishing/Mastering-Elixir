defmodule ElixirDrip.Repo.Migrations.UniqueSharesConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:media_owners, [:media_id, :user_id], name: :single_share_index)
  end
end
