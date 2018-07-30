defimpl Size, for: BitString do
  def size(string), do: byte_size(string)
end

defimpl Size, for: Map do
  def size(map), do: map_size(map)
end

defimpl Size, for: Tuple do
  def size(tuple), do: tuple_size(tuple)
end

defimpl Size, for: Any do
  def size(_), do: 0
end

defimpl Size, for: File.Stat do
  def size(file_stat), do: file_stat.size
end

defimpl Size, for: Folder do
  def size(folder) do
    folder.files_info
    |> Enum.map(&Size.size(&1))
    |> Enum.sum()
  end
end
