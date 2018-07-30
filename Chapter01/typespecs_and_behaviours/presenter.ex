defmodule Presenter do
  @callback present(String.t) :: atom
end
