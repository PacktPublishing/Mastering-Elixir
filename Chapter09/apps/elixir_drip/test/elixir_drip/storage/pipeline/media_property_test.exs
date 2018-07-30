defmodule ElixirDrip.Storage.MediaPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @subject ElixirDrip.Storage.Media

  property "is_valid_path?/1 with valid paths returns {:ok, :valid}" do
    check all path <- string(:ascii),
              String.last(path) != "/" do
      assert @subject.is_valid_path?("$" <> path) == {:ok, :valid}
    end
  end

  property "is_valid_path?/1 with invalid paths returns {:error, :invalid_path}" do
    check all path <- string(:ascii),
              String.first(path) != "$" do
      assert @subject.is_valid_path?(path) == {:error, :invalid_path}
    end

    check all path <- string(:ascii) do
      assert @subject.is_valid_path?(path <> "/") == {:error, :invalid_path}
    end
  end
end
