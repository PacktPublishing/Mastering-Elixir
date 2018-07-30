import_file("./examples/sample_data.exs")

alias ElixirDrip.Search.SampleData, as: Data

users = Data.users()

pretty_users = users
               |> Flow.from_enumerable(max_demand: 1)
               |> Flow.map(&Data.set_name_domain(&1))
               |> Flow.map(&Data.set_full_name(&1))
               |> Flow.map(&Data.set_country(&1))
               |> Flow.map(&Data.set_preferences(&1))

# all_media = 100 \
#             |> Data.random_media(length(users)) \
#             |> Flow.from_enumerable()

raw_media_set = Data.media_set()

media_set = raw_media_set
            |> Flow.from_enumerable()
            |> Flow.map(&Map.take(&1, [:id, :user_id, :file_name, :file_size]))
            |> Enum.to_list()

files_by_user_v1 = media_set
            |> Enum.sort(&(&1.file_name >= &2.file_name))
            |> Flow.from_enumerable(max_demand: 1)
            |> Flow.reduce(fn -> %{} end,
                           fn media, accum ->
                             Map.update(accum, media.user_id, 1, &(&1 + 1))
                           end)
# WRONG result: [{2, 1}, {3, 1}, {1, 1}, {3, 2}, {4, 1}]

files_by_user_v1_5 = media_set
            |> Flow.from_enumerable(max_demand: 1)
            |> Flow.partition(hash: fn m -> {m, m.user_id} end)
            |> Flow.reduce(fn -> %{} end,
                           fn media, accum ->
                             Map.update(accum, media.user_id, 1, &(&1 + 1))
                           end)
# WRONG result: [{2, 1}, {1, 1}, {3, 3}]

# # partitions, given by the last element of the tuple,
# # are 0-index based, thus the -1
files_by_user_v2 = media_set
            |> Flow.from_enumerable(max_demand: 1)
            |> Flow.partition(hash: fn m -> {m, m.user_id-1} end)
            |> Flow.reduce(fn -> %{} end,
                           fn media, accum ->
                             Map.update(accum, media.user_id, 1, &(&1 + 1))
                           end)
# RIGHT RESULT: [{1, 1}, {2, 1}, {4, 1}, {3, 3}]

files_by_user_v3 = media_set
            |> Flow.from_enumerable(max_demand: 1)
            |> Flow.partition(key: {:key, :user_id})
            |> Flow.reduce(fn -> %{} end,
                           fn media, accum ->
                             Map.update(accum, media.user_id, 1, &(&1 + 1))
                           end)
# RIGHT RESULT: [{1, 1}, {2, 1}, {4, 1}, {3, 3}]

disk_usage_by_user = media_set
            |> Flow.from_enumerable(max_demand: 1)
            |> Flow.partition(key: {:key, :user_id})
            |> Flow.reduce(fn -> %{} end,
                           fn %{user_id: user_id, file_size: size}, accum ->
                             Map.update(accum, user_id, size, &(&1 + size))
                           end)
# RIGHT RESULT: [...]

disk_usage_ranking_v1 = Flow.bounded_join(
  :inner,
  pretty_users,
  disk_usage_by_user,
  &(&1.id),
  &(elem(&1, 0)),
  fn user, {_user_id, total_size} ->
    %{user: user.full_name, disk_usage: total_size/1000}
  end)
  |> Enum.sort(&(&1.disk_usage >= &2.disk_usage))
# RIGHT RESULT: [...]

disk_usage_ranking_v2 = Flow.bounded_join(
  :left_outer,
  pretty_users,
  disk_usage_by_user,
  &(&1.id),
  &(elem(&1, 0)),
  fn user, right_elem ->
    disk_usage = case right_elem do
      nil                    -> 0
      {_user_id, total_size} -> total_size
    end

    %{user: user.full_name, disk_usage: disk_usage}
  end)
  |> Enum.sort(&(&1.disk_usage >= &2.disk_usage))
# RIGHT RESULT: [...]

