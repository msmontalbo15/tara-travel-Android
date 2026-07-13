-- Add cover_emoji to trips (missing from schema but used in app)
alter table public.trips add column if not exists cover_emoji text;

-- Auto-create public.users row on new auth sign-up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, email, display_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Allow all trip members to insert itinerary stops (not just navigators)
drop policy if exists "Members can insert stops" on public.itinerary_stops;
create policy "Members can insert stops" on public.itinerary_stops for insert
  with check (exists (
    select 1 from public.trip_members
    where trip_id = itinerary_stops.trip_id and user_id = auth.uid()
  ));

-- Realtime for itinerary and packing
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'itinerary_stops') then
    alter publication supabase_realtime add table public.itinerary_stops;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'packing_items') then
    alter publication supabase_realtime add table public.packing_items;
  end if;
end $$;
