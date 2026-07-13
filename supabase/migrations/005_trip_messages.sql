-- ── trip_messages table ────────────────────────────────────────────────────
-- Clean slate: drop if exists to ensure no partial state
-- drop table if exists public.trip_messages cascade;

create table if not exists public.trip_messages (
  id          uuid        primary key default uuid_generate_v4(),
  trip_id     uuid        not null references public.trips(id) on delete cascade,
  user_id     uuid        not null references public.users(id) on delete cascade,
  sender_name text        not null default 'Anonymous',
  content     text        not null check (char_length(content) > 0),
  created_at  timestamptz not null default now()
);

-- ── Indexes ─────────────────────────────────────────────────────────────────
create index if not exists idx_trip_messages_trip_id
  on public.trip_messages (trip_id, created_at asc);

-- ── Row Level Security ───────────────────────────────────────────────────────
alter table public.trip_messages enable row level security;

-- 1. Read: Trip owners and trip members can see messages
drop policy if exists "trip_members_read_messages" on public.trip_messages;
create policy "trip_members_read_messages"
  on public.trip_messages for select
  using (
    trip_id in (
      select id from public.trips where owner_id = auth.uid()
      union
      select trip_id from public.trip_members where user_id = auth.uid()
    )
  );

-- 2. Insert: Authenticated users can post their own messages
drop policy if exists "authenticated_insert_messages" on public.trip_messages;
create policy "authenticated_insert_messages"
  on public.trip_messages for insert
  with check (auth.uid() = user_id);

-- 3. Delete: Users can only delete their own messages
drop policy if exists "owner_delete_messages" on public.trip_messages;
create policy "owner_delete_messages"
  on public.trip_messages for delete
  using (auth.uid() = user_id);

-- ── Real-time publication ────────────────────────────────────────────────────
-- This enables live chat updates. Run this separately if it errors (it might already exist).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' 
    and schemaname = 'public' 
    and tablename = 'trip_messages'
  ) then
    alter publication supabase_realtime add table public.trip_messages;
  end if;
end $$;
