# * Query to get the top 10 users in terms of disk-usage, showing how to do it with a sub-query and then by using the `Repo.aggregate`,
#   * using the dynamic `field/2` to select order by disk usage or number of files

alias ElixirDrip.Repo
alias ElixirDrip.Accounts
alias ElixirDrip.Storage
alias ElixirDrip.Storage.Media
alias ElixirDrip.Storage.Owner
alias ElixirDrip.Accounts.User
alias ElixirDrip.Storage.MediaOwners
import Ecto.Query

# OK, but inner join, so doesn't show all users
user_stats = from m in Media,
group_by: m.user_id,
select: %{
  media_count: count(m.id),
  disk_usage: sum(m.file_size),
  user_id: m.user_id
}

# OK, left join so shows all users
# still without order
split_schemaless_users_media = from u in "users",
left_join: m in "storage_media",
on: u.id == m.user_id,
group_by: u.id

# OK, hardcoded order
# with column number (1 = media_count), you can't refer to it like media_count
schemaless_ordered_users_media = from [u,m] in split_schemaless_users_media,
order_by: [desc: 1],
select: %{
  media_count: count(m.id),
  disk_usage: sum(m.file_size),
  username: u.username
}
Repo.all(schemaless_ordered_users_media)

schemaless_users_media = from u in "users",
left_join: m in "storage_media",
on: u.id == m.user_id,
group_by: u.id,
select: %{
  media_count: count(m.id),
  disk_usage: sum(m.file_size),
  username: u.username
}
Repo.all(schemaless_users_media)

schemaless_ordered_users_media = from [u,m] in schemaless_users_media,
order_by: [desc: 1]
Repo.all(schemaless_ordered_users_media)

sort_order = :desc
dynamic_order_schemaless_users_media = from e in subquery(schemaless_users_media),
order_by: [{^sort_order, e.media_count}]
Repo.all(dynamic_order_schemaless_users_media)

sort_field = :disk_usage
dynamic_schemaless_users_media = from e in subquery(schemaless_users_media),
order_by: [{^sort_order, field(e, ^sort_field)}]
Repo.all(dynamic_schemaless_users_media)

# We could also use the schemas if we want
users_media = from u in User,
left_join: m in Media,
on: u.id == m.user_id,
group_by: u.id,
select: %{
  media_count: count(m.id),
  disk_usage: sum(m.file_size),
  username: u.username
}
Repo.all(users_media)

ordered_users_media = from r in subquery(users_media),
order_by: [desc: r.media_count],
select: r
Repo.all(ordered_users_media)

# dynamic sorting criteria, with the `field/2` function
sort_order = :desc
sort_field = :media_count
dynamic_ordered_users_media = from r in subquery(users_media),
order_by: [{^sort_order, field(r, ^sort_field)}],
select: r
Repo.all(dynamic_ordered_users_media)

# limit our results to the top-N
top = 3
top_users_media = from r in subquery(users_media),
order_by: [{^sort_order, field(r, ^sort_field)}],
limit: ^top,
select: r
Repo.all(top_users_media)

# Repo.aggregate simple example
Repo.aggregate(Media, :avg, :file_size)

# it doesn't work because `users_media` is using a `group_by` clause
Repo.aggregate(users_media, :avg, :media_count)

# Repo.aggregate example with subquery works. Why?
# aggregate/3 doesn't accept queries that are using `group_by`, like our `users_media`.
# But because we are converting it into a subquery first, Ecto considers the query outcome to aggregate and not the query itself, thus allowing us to use our `users_media` with the `group_by` clause query as a subquery
Repo.aggregate(subquery(users_media), :avg, :media_count)
