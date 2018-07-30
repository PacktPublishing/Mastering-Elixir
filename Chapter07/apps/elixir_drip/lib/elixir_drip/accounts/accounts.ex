defmodule ElixirDrip.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias ElixirDrip.Repo
  alias ElixirDrip.Accounts.User

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_username(username) do
    User
    |> Repo.get_by(username: username)
  end

  def verify_user_password(%User{} = user, password) do
    Comeonin.Bcrypt.checkpw(password, user.hashed_password)
  end
end
