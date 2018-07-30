defmodule ElixirDrip.Ecto.Ksuid do
  @moduledoc """
  A module implementing ksuid as an ecto type.

  To enable ksuid as the primary key type for ecto schemas add this annotation
  on top of the schema definition:

      @primary_key {:id, ElixirDrip.Ecto.Ksuid, autogenerate: true}
      schema "my_schema" do
        (...)
      end

  To use it as the type of any other schema field do the following:

      schema "my_schema" do
        (...)
        field :my_ksuid_field, ElixirDrip.Ecto.Ksuid
        (...)
      end

  More info about ksuid may be found [here](https://segment.com/blog/a-brief-history-of-the-uuid/).
  The elixir library used can be found [here](https://github.com/girishramnani/elixir-ksuid).
  """

  @behaviour Ecto.Type

  def type, do: :string

  def cast(ksuid)
    when is_binary(ksuid) and byte_size(ksuid) == 27, do: {:ok, ksuid}
  def cast(_), do: :error

  def cast!(value) do
    case cast(value) do
      {:ok, ksuid} -> ksuid
      :error -> raise Ecto.CastError, type: __MODULE__, value: value
    end
  end

  def load(ksuid), do: {:ok, ksuid}

  def dump(binary) when is_binary(binary), do: {:ok, binary}
  def dump(_), do: :error

  def autogenerate, do: Ksuid.generate()
end
