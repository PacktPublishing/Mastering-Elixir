defmodule ElixirDrip.Search.SampleData do
  @moduledoc false

  alias ElixirDrip.Storage.Media

  def users do
    [
      %{id: 1, email: "andre_albuquerque@elixir.pt"},
      %{id: 2, email: "daniel_caixinha@elixir.pt"},
      %{id: 3, email: "jose_valim@elixir.br"},
      %{id: 4, email: "joe_armstrong@erlang.uk"},
      %{id: 5, email: "robert_virding@erlang.se"},
      %{id: 6, email: "mike_williams@erlang.wls"},
      %{id: 7, email: "jose_lusquinos@panda.pt"},
      %{id: 8, email: "atenas@meow.cat"},
      %{id: 9, email: "billy_boy@woof.dog"},
    ]
  end

  def media_set do
    [
      generate_media_for_user(1, 3),
      generate_media_for_user(4, 3),
      generate_media_for_user(6, 3),
      generate_media_for_user(2, 2),
      generate_media_for_user(3, 1),
      generate_media_for_user(5, 4),
    ]
  end

  def set_name_domain(%{email: email} = user) do
    {name, domain} = email
                     |> String.split("@")
                     |> List.to_tuple()

    user
    |> Map.put(:name, name)
    |> Map.put(:domain, domain)
  end

  def set_full_name(%{name: name} = user) do
    full_name = name
                |> String.split("_")
                |> Enum.map(&String.capitalize(&1))
                |> Enum.join(" ")

    Map.put(user, :full_name, full_name)
  end

  def set_country(%{domain: domain} = user) do
    country = domain
              |> String.split(".")
              |> Enum.reverse()
              |> Enum.at(0)
              |> String.upcase()

    Map.put(user, :country, country)
  end

  def set_preferences(%{domain: domain} = user) do
    preferences = domain
                  |> String.split(".")
                  |> Enum.at(0)

    Map.put(user, :preferences, preferences)
  end

  def random_media(how_many, max_users) do
    1..how_many
    |> Enum.map(fn i ->
      user = :rand.uniform(max_users)
      generate_media_for_user(i, user)
    end)
  end

  def generate_media_for_user(id, user_id) do
    possible_extensions = [".bmp", ".jpg", ".png", ".mp3", ".md", ".doc", ".pdf"]

    file_name = 10
                |> :crypto.strong_rand_bytes()
                |> Base.encode32()
                |> String.downcase()

    %Media{
      id: id,
      user_id: user_id,
      file_name: file_name <> random_from(possible_extensions),
      file_size: :rand.uniform(10_000)
    }
  end

  defp random_from([]), do: nil
  defp random_from([item]), do: item
  defp random_from(collection) do
    index = :rand.uniform(length(collection) - 1)
    Enum.at(collection, index)
  end
end
