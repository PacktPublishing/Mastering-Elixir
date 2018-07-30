defmodule ElixirDrip.Storage do
  @moduledoc false

  import ElixirDrip.Storage.Macros
  import Ecto.Query
  alias Ecto.Changeset
  alias ElixirDrip.Repo
  alias ElixirDrip.Storage.Workers.QueueWorker, as: Queue
  alias ElixirDrip.Storage.{
    Media,
    Owner,
    MediaOwners
  }

  @doc """
    It sequentially creates the Media on the DB and
    triggers an Upload request handled by the Upload Pipeline.
  """
  def store(user_id, file_name, full_path, content) do
    file_size = byte_size(content)
    with %Owner{} = owner <- get_owner(user_id),
         %Changeset{} = changeset <- Media.create_initial_changeset(owner.id, file_name, full_path, file_size),
         %Changeset{} = changeset <- Changeset.put_assoc(changeset, :owners, [owner]),
         {:ok, %Media{} = media} <- Repo.insert(changeset)
    do
      upload_task = %{
        media: media,
        content: content,
        type: :upload
      }

      Queue.enqueue(Queue.Upload, upload_task)

      {:ok, :upload_enqueued, media}
    else
      error -> error
    end
  end

  def set_upload_timestamp(%Media{} = media) do
    media
    |> Changeset.cast(%{uploaded_at: DateTime.utc_now()}, [:uploaded_at])
    |> Repo.update!()
  end

  @doc """
    If the media belongs to the user,
    it triggers a Download request
    that will be handled by the Download Pipeline
  """
  def retrieve(user_id, media_id) do
    user_media = user_media_query(user_id)

    media_query = from [_mo, m] in user_media,
      where: m.id == ^media_id

    case Repo.one(media_query) do
      nil   -> {:error, :not_found}
      media -> _retrieve(media)
    end
  end

  def get_all_media(user_id) do
    # we can only do one `select` per query,
    # that's why we don't do any `select` on the
    # user_media_query
    # The alternative would be to use subqueries
    # or to exclude the previous :select field from the query
    user_media_query(user_id)
    |> Repo.all()
  end

  def media_by_folder(user_id, folder_path) do
    with {:ok, :valid} <- Media.is_valid_path?(folder_path) do
      _media_by_folder(user_id, folder_path)
    else
      error -> error
    end
  end

  def share(user_id, media_id, allowed_user_id) do
    with {:ok, :creator} <- is_creator?(user_id, media_id) do
      %MediaOwners{}
      |> Changeset.cast(%{user_id: allowed_user_id, media_id: media_id}, [:user_id, :media_id])
      |> Changeset.unique_constraint(:existing_share, name: :single_share_index)
      |> Changeset.foreign_key_constraint(:user_id)
      |> Changeset.foreign_key_constraint(:media_id)
      |> Repo.insert()
    else
      error -> error
    end
  end

  def move(user_id, media_id, new_path),
    do: _move(user_id, media_id, new_path, nil)

  def rename(user_id, media_id, new_name),
    do: _move(user_id, media_id, nil, new_name)

  def delete(user_id, media_id) do
    with {:ok, :creator} <- is_creator?(user_id, media_id) do
      # Given we have the foreign key with
      # on_delete: :delete_all option
      %Media{id: media_id}
      |> Repo.delete()
    else
      error -> error
    end
  end

  def media_already_exists?(user_id, full_path, file_name) do
    user_media = user_media_query(user_id)

    query = from [_mo, m] in user_media,
      where: m.full_path == ^full_path,
      where: m.file_name == ^file_name

    {query, vars} = Repo.to_sql(:all, query)
    query = "SELECT TRUE WHERE EXISTS (#{query})"

    Repo.query!(query, vars).rows
    |> Enum.empty?()
    |> case do
      true -> {:ok, :nonexistent}
      _    -> {:error, :already_exists}
    end
  end

  def media_already_exists_limit?(user_id, full_path, file_name) do
    user_media = user_media_query(user_id)

    query = from [_mo, m] in user_media,
      where: m.full_path == ^full_path,
      where: m.file_name == ^file_name

    result =
      query
      # resets any query field, except `from`
      # useful for queries with previous selects
      |> exclude(:select)
      |> limit(1)
      |> select(true)
      |> Repo.one()

    case result do
      true -> {:error, :already_exists}
      _    -> {:ok, :nonexistent}
    end
  end

  # TODO: Not working fragment with full SELECT query
  # def media_already_exists_query_nok?(user_id, full_path, file_name) do
  #   user_media = user_media_query(user_id)

  #   query = from [_mo, m] in user_media,
  #     where: m.full_path == ^full_path,
  #     where: m.file_name == ^file_name

  #   zaz = "SELECT * " <> \
  #   "FROM \"storage_media\" m inner join \"media_owners\" mo on m.id = mo.media_id " <> \
  #   "WHERE mo.user_id = '#{user_id}' " <> \
  #   "AND m.full_path = '#{full_path}' " <> \
  #   "AND m.file_name = '#{file_name}'"

  #   to_run = from m in Media,
  #     select: fragment("EXISTS(?)", ^zaz)

  #   result = Repo.one(to_run)
  # end

  def get_media(media_id), do: Repo.get!(Media, media_id)

  def get_media(user_id, media_id) do
    user_media = user_media_query(user_id)

    media_query = from [_mo, m] in user_media,
      where: m.id == ^media_id

    case Repo.one(media_query) do
      nil   -> {:error, :not_found}
      media -> media_to_present(media)
    end
  end

  # debug only
  @doc false
  def list_all_media, do: Repo.all(Media)

  # debug only
  @doc false
  def get_last_media do
    query = from media in Media,
      order_by: [desc: media.id],
      limit: 1

    Repo.one(query)
  end

  def get_top_users_by_usage(sort_field \\ :media_count, sort_order \\ :desc, top \\ 10) do
    schemaless_users_media = from u in "users",
    left_join: m in "storage_media",
    on: u.id == m.user_id,
    group_by: u.id,
    select: %{
      media_count: count(m.id),
      disk_usage: sum(m.file_size),
      username: u.username
    }

    dynamic_schemaless_users_media = from e in subquery(schemaless_users_media),
      order_by: [{^sort_order, field(e, ^sort_field)}],
      limit: ^top

    Repo.all(dynamic_schemaless_users_media)
  end

  def get_owner(id, preloaded \\ false)
  def get_owner(id, false),
    do: Repo.get!(Owner, id)
  def get_owner(id, true),
    do: Repo.get!(Owner, id) |> Repo.preload(:files)

  def get_owners_preload do
    # Still does one more query
    Repo.all(from u in Owner, preload: [:files])
  end

  def get_owners_preload_v2 do
    # one query, but "manual" join
    query = from o in Owner,
      join: mo in MediaOwners,
      on: o.id == mo.user_id,
      join: f in Media,
      on: mo.media_id == f.id,
      preload: [files: f]

    Repo.all(query)
  end

  def get_owners_preload_v3 do
    # Does only one query
    Repo.all(from u in Owner,
      join: f in assoc(u, :files),
      preload: [files: f])
  end

  defp update_files_result(%{files: files_result}, entry) do
    new_entry = Map.take(entry, [:id, :name, :full_path, :size])

    [new_entry | files_result]
    |> Enum.reverse()
  end

  defp _move(user_id, media_id, new_path, new_name) do
    with {:ok, :creator}  <- is_creator?(user_id, media_id),
         %Media{} = media <- get_media(media_id),
         new_path         <- new_path(media, new_path),
         new_name         <- new_name(media, new_name),
         {:ok, :nonexistent} <- media_already_exists?(user_id, new_path, new_name)
    do
      media
      |> Changeset.cast(%{full_path: new_path, file_name: new_name}, [:full_path, :file_name])
      |> Media.validate_field(:full_path)
      |> Media.validate_field(:file_name)
      |> Repo.update()
    else
      error -> error
    end
  end

  defp new_path(media, nil), do: media.full_path
  defp new_path(_media, new_path), do: new_path

  defp new_name(media, nil), do: media.file_name
  defp new_name(_media, new_name), do: new_name


  defp _media_by_folder(user_id, folder_path) do
    user_media_on_folder = user_media_on_folder(user_id, folder_path)

    folder_media = from e in subquery(user_media_on_folder),
      select: %{
        id: e.id,
        name: e.file_name,
        full_path: e.full_path,
        size: e.file_size,
        remaining_path: e.remaining_path,
        is_folder: is_folder(e.remaining_path)
      }

    folder_media
    |> Repo.all()
    |> files_and_folders_to_present()
  end

  defp files_and_folders_to_present(results) do
    result = results
    |> Enum.reduce(%{files: [], folders: %{}},
                   fn(entry, result) ->
                     case entry[:is_folder] do
                       true ->
                         folder_result = update_folder_result(result, entry)
                         Map.put(result, :folders, folder_result)
                       false ->
                         files_result = update_files_result(result, entry)
                         Map.put(result, :files, files_result)
                     end
                   end)

    folder_entry = result[:folders]
    Map.put(result, :folders, Map.values(folder_entry))
  end

  defp media_to_present(%Media{id: id, file_name: name,
    full_path: full_path, file_size: size, metadata: metadata,
    user_id: owner_id, uploaded_at: uploaded_at}),
    do: %{
      id: id,
      name: name,
      full_path: full_path,
      size: size,
      metadata: metadata,
      owner_id: owner_id,
      uploaded_at: uploaded_at
    }

  defp update_folder_result(%{folders: folder_result}, %{size: file_size} = entry) do
    folder_name = extract_folder_name(entry)

    updated_folder_entry = case Map.has_key?(folder_result, folder_name) do
      true -> increment_folder_files_and_size(folder_result[folder_name], file_size)
      false -> %{name: folder_name, files: 1, size: file_size}
    end

    Map.put(folder_result, folder_name, updated_folder_entry)
  end

  defp extract_folder_name(%{remaining_path: path}),
    do: Path.split(path) |> Enum.at(1)

  defp increment_folder_files_and_size(%{files: files, size: size} = folder_entry, file_size),
    do: %{folder_entry | files: files + 1, size: size + file_size}

  defp user_media_on_folder(user_id, folder_path) do
    folder_path_size = String.length(folder_path)
    folder_path_size = -folder_path_size

    # given we want to do a select below, we exclude it first
    user_media = user_media_query(user_id)
                 |> exclude(:select)

    from [_mo, m] in user_media,
      where: like(m.full_path, ^"#{folder_path}%"),
      select: %{
        id: m.id,
        full_path: m.full_path,
        file_name: m.file_name,
        file_size: m.file_size,
        remaining_path: remaining_path(^folder_path_size, m.full_path)
      }
  end

  defp is_creator?(user_id, media_id) do
    (from m in Media,
      where: m.id == ^media_id,
      where: m.user_id == ^user_id)
      |> Repo.one()
      |> case do
        nil -> {:error, :not_creator}
        _ -> {:ok, :creator}
      end
  end

  defp user_media_query(user_id) do
    from media_owner in MediaOwners,
      join: media in Media,
      on: media_owner.media_id == media.id,
      where: media_owner.user_id == ^user_id,
      select: media
  end

  defp user_media_query_alternative(user_id) do
    owner = %Owner{id: user_id}

    # Ecto.assoc(owner, [:files]) |> Repo.all
    # would return all files (%Media) from that user

    from [m, _o] in Ecto.assoc(owner, [:files]),
      select: m
  end

  defp _retrieve(%Media{} = media) do
    download_task = %{
      media: media,
      type: :download
    }
    Queue.enqueue(Queue.Download, download_task)

    {:ok, :download_enqueued, media}
  end
end
