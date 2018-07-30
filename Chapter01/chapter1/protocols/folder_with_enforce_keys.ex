defmodule Folder do
  @enforce_keys :path
  defstruct name: "new folder", files_info: [], path: nil
end
