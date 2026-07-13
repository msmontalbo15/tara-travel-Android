-- Optional local development seed.
-- Use the provided authenticated user id.

with created_trip as (
  insert into public.trips (name, destination, start_date, end_date, budget, type, split_method, owner_id, status)
  values ('Dev Boracay Getaway', 'Boracay, Philippines', current_date + 7, current_date + 11, 50000, 'beach', 'equal', '48d7f1e8-beb7-4395-ba18-7acdba44e9f8', 'planned')
  returning id
)
insert into public.trip_members (trip_id, user_id, roles)
select id, '48d7f1e8-beb7-4395-ba18-7acdba44e9f8', '{"organizer"}'
from created_trip;
