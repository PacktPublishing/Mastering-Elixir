defmodule Presenter do
  @callback present(String.t) :: atom
  @optional_callbacks present: 1
end
