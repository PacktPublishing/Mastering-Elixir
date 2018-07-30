defmodule ElixirDrip.Storage.Macros do
  defmacro remaining_path(pwd_size, full_path) do
    quote do
      fragment("right(?, ?)", unquote(full_path), unquote(pwd_size))
    end
  end

  defmacro is_folder(remaining_path) do
    quote do
      fragment("length(?) > 0", unquote(remaining_path))
    end
  end
end
