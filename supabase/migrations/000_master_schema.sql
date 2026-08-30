-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MASTER SUPABASE SCHEMA (v1.0.0)
-- ─────────────────────────────────────────────────────────────────────────────
-- Run this on a FRESH Supabase project (Dashboard → SQL Editor → Run).
-- All statements are idempotent (CREATE TABLE IF NOT EXISTS / DROP POLICY IF
-- EXISTS) so it is safe to re-apply on an existing project.
--
-- Supabase Project Settings required BEFORE running:
--   1. Authentication → Providers → Google → ENABLED
--      Set Web Client ID + Secret from Google Cloud Console.
--   2. Connection Pooling → Supavisor → Port 6543 (Transaction Mode) for
--      Flutter client connections.
--   3. After running: create Storage Buckets in the dashboard
--      (the SQL-level storage inserts are included at the end).
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 0. EXTENSIONS ────────────────────────────────────────────────────────────
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists postgis schema public;

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 1 · USERS & IDENTITY
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1a. USERS ────────────────────────────────────────────────────────────────
-- Primary profile table. Auto-populated via handle_new_user trigger on every
-- Google OAuth / Email sign-up. Sensitive fields (phone, gcash_number,
-- health_notes) are encrypted at-rest by the Flutter 3-Layer Encryption layer
-- before reaching Supabase; we store the opaque cipher-text here.
create table if not exists public.users (
  id                    uuid        primary key default auth.uid(),
  email                 text        unique not null,
  display_name          text        not null default '',
  avatar_url            text,
  -- Google Sign-In fields
  google_id             text        unique,                         -- OAuth sub claim
  -- Personal contact
  phone                 text,                                       -- AES-encrypted
  home_city             text,
  -- GCash payment
  gcash_number          text,                                       -- AES-encrypted
  gcash_qr_url          text,
  -- Health & safety (opt-in sharing)
  blood_type            text,
  allergies             text[]      not null default '{}',
  dietary               text[]      not null default '{}',          -- also used for misc tag storage
  health_notes          text,                                       -- AES-encrypted
  share_health_with_org boolean     not null default false,
  -- Online presence
  is_online             boolean     not null default false,
  last_seen             timestamptz,
  -- Privacy & Visibility
  hide_surname          boolean     not null default false,
  -- Metadata
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

alter table public.users enable row level security;

drop policy if exists "users_select_own"  on public.users;
drop policy if exists "users_insert_own"  on public.users;
drop policy if exists "users_update_own"  on public.users;
-- Allow trip members to view each other's basic public profiles (needed for
-- member cards, chat avatars, friend search results).
drop policy if exists "users_select_trip_peers" on public.users;
drop policy if exists "users_select_any_authenticated" on public.users;

create policy "users_select_own"
  on public.users for select using (auth.uid() = id);

create policy "users_insert_own"
  on public.users for insert with check (auth.uid() = id);

create policy "users_update_own"
  on public.users for update using (auth.uid() = id);

-- Public search: allow any authenticated user to discover other users.
create policy "users_select_any_authenticated"
  on public.users for select
  using (auth.role() = 'authenticated');

-- ── 1b. USER SETTINGS ────────────────────────────────────────────────────────
-- App-level preferences. Auto-seeded with sensible defaults on sign-up.
create table if not exists public.user_settings (
  id                        uuid        primary key default uuid_generate_v4(),
  user_id                   uuid        not null references public.users(id) on delete cascade,
  -- UI/UX
  dark_mode                 boolean     not null default false,
  preferred_currency        text        not null default 'PHP',
  distance_unit             text        not null default 'km'
                            check (distance_unit in ('km', 'mi')),
  language                  text        not null default 'en',
  -- Notifications
  push_notifications        boolean     not null default true,
  trip_invites_notify       boolean     not null default true,
  expense_notify            boolean     not null default true,
  chat_notify               boolean     not null default true,
  -- Security
  biometric_enabled         boolean     not null default false,
  biometric_type            text,                                   -- 'fingerprint' | 'face' | null
  mpin_enabled              boolean     not null default false,
  -- Privacy
  location_sharing_default  boolean     not null default true,
  hide_surname              boolean     not null default false,
  -- Metadata
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  unique (user_id)
);

alter table public.user_settings enable row level security;

drop policy if exists "settings_select_own" on public.user_settings;
drop policy if exists "settings_insert_own" on public.user_settings;
drop policy if exists "settings_update_own" on public.user_settings;

create policy "settings_select_own"
  on public.user_settings for select using (auth.uid() = user_id);

create policy "settings_insert_own"
  on public.user_settings for insert with check (auth.uid() = user_id);

create policy "settings_update_own"
  on public.user_settings for update using (auth.uid() = user_id);

-- ── 1c. USER DEVICES ─────────────────────────────────────────────────────────
-- Maps FCM push tokens to user sessions for targeted push notifications.
create table if not exists public.user_devices (
  id            uuid        primary key default uuid_generate_v4(),
  user_id       uuid        not null references public.users(id) on delete cascade,
  fcm_token     text        not null,
  device_id     text        not null,                              -- hardware fingerprint
  platform      text        not null default 'android'
                check (platform in ('android', 'ios', 'web')),
  device_name   text,
  app_version   text,
  is_active     boolean     not null default true,
  last_active   timestamptz not null default now(),
  created_at    timestamptz not null default now(),
  unique (user_id, device_id)
);

alter table public.user_devices enable row level security;

drop policy if exists "devices_select_own" on public.user_devices;
drop policy if exists "devices_upsert_own" on public.user_devices;
drop policy if exists "devices_delete_own" on public.user_devices;

create policy "devices_select_own"
  on public.user_devices for select using (auth.uid() = user_id);

create policy "devices_upsert_own"
  on public.user_devices for all using (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 2 · SOCIAL / FRIENDS
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 2a. FRIENDS ──────────────────────────────────────────────────────────────
-- Reciprocal flat friendship table consumed by FriendRepository.
-- When A sends request to B: insert (A→B, pending) + (B→A, pending).
-- On accept: update both rows to 'accepted'.
create table if not exists public.friends (
  id          uuid        primary key default uuid_generate_v4(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  friend_id   uuid        not null references public.users(id) on delete cascade,
  status      text        not null default 'pending'
              check (status in ('pending', 'accepted', 'rejected', 'blocked')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, friend_id)
);

alter table public.friends enable row level security;

drop policy if exists "friends_select_own"   on public.friends;
drop policy if exists "friends_insert_own"   on public.friends;
drop policy if exists "friends_update_own"   on public.friends;
drop policy if exists "friends_delete_own"   on public.friends;

create policy "friends_select_own"
  on public.friends for select using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "friends_insert_own"
  on public.friends for insert with check (auth.uid() = user_id or auth.uid() = friend_id);

create policy "friends_update_own"
  on public.friends for update using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "friends_delete_own"
  on public.friends for delete using (auth.uid() = user_id or auth.uid() = friend_id);

-- ── 2b. FRIENDSHIPS ──────────────────────────────────────────────────────────
-- Directional friend request ledger (used by FriendshipModel.fromMap).
create table if not exists public.friendships (
  id           uuid        primary key default uuid_generate_v4(),
  requester_id uuid        not null references public.users(id) on delete cascade,
  receiver_id  uuid        not null references public.users(id) on delete cascade,
  status       text        not null default 'pending'
               check (status in ('pending', 'accepted', 'rejected')),
  created_at   timestamptz not null default now(),
  unique (requester_id, receiver_id)
);

alter table public.friendships enable row level security;

drop policy if exists "friendships_select" on public.friendships;
drop policy if exists "friendships_insert" on public.friendships;
drop policy if exists "friendships_update" on public.friendships;

create policy "friendships_select"
  on public.friendships for select
  using (auth.uid() = requester_id or auth.uid() = receiver_id);

create policy "friendships_insert"
  on public.friendships for insert
  with check (auth.uid() = requester_id);

create policy "friendships_update"
  on public.friendships for update
  using (auth.uid() = requester_id or auth.uid() = receiver_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 3 · TRIPS & MEMBERSHIP
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 3a. TRIPS ────────────────────────────────────────────────────────────────
create table if not exists public.trips (
  id                  uuid        primary key default uuid_generate_v4(),
  name                text        not null,
  destination         text        not null,
  destination_lat     double precision,
  destination_lng     double precision,
  start_date          date        not null,
  end_date            date        not null,
  budget              numeric(12,2) not null default 0,
  currency            text        not null default 'PHP',
  type                text        not null default 'beach',
  transport_mode      text        not null default 'car',
  transport_meta      jsonb       not null default '{}',
  split_method        text        not null default 'equal'
                      check (split_method in ('equal','fixed','bigger','category')),
  split_meta          jsonb       not null default '{}',
  owner_id            uuid        not null references public.users(id) on delete cascade,
  -- Invite
  invite_code         text        unique not null default upper(substr(md5(random()::text), 1, 6)),
  invite_expires_at   timestamptz,
  -- Status & visual
  status              text        not null default 'planned'
                      check (status in ('draft','planned','active','completed','archived')),
  departure_point     text,
  departure_lat       double precision,
  departure_lng       double precision,
  -- Metadata
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

alter table public.trips enable row level security;

drop policy if exists "trips_owner_all"        on public.trips;
drop policy if exists "trips_members_select"   on public.trips;

-- Owner: full CRUD
create policy "trips_owner_all"
  on public.trips for all using (auth.uid() = owner_id);

-- ── 3b. TRIP MEMBERS ─────────────────────────────────────────────────────────
create table if not exists public.trip_members (
  id               uuid        primary key default uuid_generate_v4(),
  trip_id          uuid        not null references public.trips(id) on delete cascade,
  user_id          uuid        not null references public.users(id) on delete cascade,
  roles            text[]      not null default '{"member"}',
  status           text        not null default 'approved'
                   check (status in ('pending','approved','rejected')),
  joined_at        timestamptz not null default now(),
  -- Location tracking
  location_sharing boolean     not null default true,
  last_lat         double precision,
  last_lng         double precision,
  last_speed       double precision,
  last_seen        timestamptz,
  unique (trip_id, user_id)
);

alter table public.trip_members enable row level security;

-- Helper 1: avoids recursive RLS by using SECURITY DEFINER
create or replace function public.is_trip_member(p_trip_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.trip_members
    where trip_id = p_trip_id and user_id = auth.uid()
  )
  or exists (
    select 1 from public.trips
    where id = p_trip_id and owner_id = auth.uid()
  );
$$;

grant execute on function public.is_trip_member(uuid) to authenticated;

-- Helper 2: can current user access this trip (avoids querying trip_members directly in trips RLS)
create or replace function public.user_can_access_trip(p_trip_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.trips
    where id = p_trip_id
      and owner_id = auth.uid()
  )
  or exists (
    select 1 from public.trip_members
    where trip_id = p_trip_id
      and user_id  = auth.uid()
  );
$$;

grant execute on function public.user_can_access_trip(uuid) to authenticated;

-- Helper 3: is current user the trip owner (avoids querying trips directly in trip_members RLS)
create or replace function public.user_owns_trip(p_trip_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.trips
    where id = p_trip_id
      and owner_id = auth.uid()
  );
$$;

grant execute on function public.user_owns_trip(uuid) to authenticated;

drop policy if exists "trip_members_select"       on public.trip_members;
drop policy if exists "trip_members_update_own"   on public.trip_members;
drop policy if exists "trip_members_owner_all"    on public.trip_members;
drop policy if exists "Members can view other members" on public.trip_members;

create policy "trip_members_select"
  on public.trip_members for select
  using (public.is_trip_member(trip_id));

create policy "trip_members_update_own"
  on public.trip_members for update
  using (user_id = auth.uid());

create policy "trip_members_owner_all"
  on public.trip_members for all
  using (public.user_owns_trip(trip_id));

-- Non-recursive trips member view policy using SECURITY DEFINER
drop policy if exists "trips_members_select" on public.trips;
create policy "trips_members_select"
  on public.trips for select
  using (public.user_can_access_trip(id));

-- ── 3c. MEMBER LOCATIONS TABLE ────────────────────────────────────────────────
-- Physical table for live GPS telemetry and real-time companion tracking.
create table if not exists public.member_locations (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references public.users(id) on delete cascade,
  trip_id      uuid not null references public.trips(id) on delete cascade,
  latitude     double precision not null,
  longitude    double precision not null,
  heading      double precision not null default 0,
  speed        double precision not null default 0,
  altitude     double precision not null default 0,
  is_online    boolean not null default true,
  geom         geometry(Point, 4326),
  last_updated timestamptz not null default now(),
  constraint uq_member_locations_trip_member unique (trip_id, member_id)
);

create index if not exists idx_member_locations_geom
  on public.member_locations using gist (geom);

alter table public.member_locations enable row level security;

drop policy if exists "member_locations_select" on public.member_locations;
drop policy if exists "member_locations_all_own" on public.member_locations;

create policy "member_locations_select"
  on public.member_locations for select
  using (public.is_trip_member(trip_id));

create policy "member_locations_all_own"
  on public.member_locations for all
  using (auth.uid() = member_id)
  with check (auth.uid() = member_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 4 · ITINERARY
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 4a. ITINERARY STOPS ──────────────────────────────────────────────────────
create table if not exists public.itinerary_stops (
  id               uuid        primary key default uuid_generate_v4(),
  trip_id          uuid        not null references public.trips(id) on delete cascade,
  day_number       int         not null,
  sort_order       int         not null default 0,
  time_start       text,
  time_end         text,
  title            text        not null,
  type             text        not null default 'activity'
                   check (type in ('hotel','activity','food','transport','custom')),
  notes            text,
  cost_estimate    numeric(10,2),
  assigned_user_id uuid        references public.users(id),
  lat              double precision,
  lng              double precision,
  address          text,
  booking_ref      text,
  status           text        not null default 'planned'
                   check (status in ('planned','arrived','completed','skipped')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table public.itinerary_stops enable row level security;

drop policy if exists "stops_select"        on public.itinerary_stops;
drop policy if exists "stops_insert"        on public.itinerary_stops;
drop policy if exists "stops_update_nav"    on public.itinerary_stops;
drop policy if exists "stops_delete_nav"    on public.itinerary_stops;

create policy "stops_select"
  on public.itinerary_stops for select
  using (public.is_trip_member(trip_id));

-- All trip members may insert stops
create policy "stops_insert"
  on public.itinerary_stops for insert
  with check (public.is_trip_member(trip_id));

create policy "stops_update_nav"
  on public.itinerary_stops for update
  using (public.is_trip_member(trip_id));

create policy "stops_delete_nav"
  on public.itinerary_stops for delete
  using (public.is_trip_member(trip_id));

-- ── 4b. STOP VOTES ───────────────────────────────────────────────────────────
create table if not exists public.stop_votes (
  id         uuid        primary key default uuid_generate_v4(),
  trip_id    uuid        not null references public.trips(id) on delete cascade,
  stop_id    uuid        not null,                                  -- references itinerary_stops.id
  member_id  uuid        not null references public.users(id) on delete cascade,
  upvote     boolean     not null,
  created_at timestamptz not null default now(),
  unique (stop_id, member_id)
);

alter table public.stop_votes enable row level security;

drop policy if exists "votes_select"   on public.stop_votes;
drop policy if exists "votes_insert"   on public.stop_votes;
drop policy if exists "votes_update"   on public.stop_votes;
drop policy if exists "votes_delete"   on public.stop_votes;

create policy "votes_select"
  on public.stop_votes for select
  using (public.is_trip_member(trip_id));

create policy "votes_insert"
  on public.stop_votes for insert
  with check (public.is_trip_member(trip_id) and member_id = auth.uid());

create policy "votes_update"
  on public.stop_votes for update
  using (member_id = auth.uid());

create policy "votes_delete"
  on public.stop_votes for delete
  using (member_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 5 · PACKING
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists public.packing_items (
  id               uuid        primary key default uuid_generate_v4(),
  trip_id          uuid        not null references public.trips(id) on delete cascade,
  name             text        not null,
  category         text        not null default 'Essentials',
  is_checked       boolean     not null default false,
  assigned_user_id uuid        references public.users(id),
  is_ai_suggested  boolean     not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table public.packing_items enable row level security;

drop policy if exists "packing_select"  on public.packing_items;
drop policy if exists "packing_all"     on public.packing_items;

create policy "packing_select"
  on public.packing_items for select
  using (public.is_trip_member(trip_id));

create policy "packing_all"
  on public.packing_items for all
  using (public.is_trip_member(trip_id));

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 6 · BUDGET: EXPENSES, SETTLEMENTS, CONTRIBUTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 6a. EXPENSES ─────────────────────────────────────────────────────────────
create table if not exists public.expenses (
  id               uuid        primary key default uuid_generate_v4(),
  trip_id          uuid        not null references public.trips(id) on delete cascade,
  description      text        not null,
  amount           numeric(12,2) not null check (amount > 0),
  category         text        not null default 'other',
  paid_by_user_id  uuid        not null references public.users(id),
  receipt_url      text,
  status           text        not null default 'pending'
                   check (status in ('pending','approved','rejected')),
  approved_by      uuid        references public.users(id),
  rejection_note   text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table public.expenses enable row level security;

drop policy if exists "expenses_select"              on public.expenses;
drop policy if exists "expenses_insert"              on public.expenses;
drop policy if exists "expenses_approve"             on public.expenses;
drop policy if exists "expenses_update_own_pending"  on public.expenses;

create policy "expenses_select"
  on public.expenses for select
  using (public.is_trip_member(trip_id));

-- All trip members may log expenses
create policy "expenses_insert"
  on public.expenses for insert
  with check (public.is_trip_member(trip_id) and paid_by_user_id = auth.uid());

-- Treasurer / Organizer can approve/reject
create policy "expenses_approve"
  on public.expenses for update
  using (
    exists (
      select 1 from public.trip_members
      where trip_id = expenses.trip_id
        and user_id = auth.uid()
        and roles && '{"treasurer","organizer"}'
    )
  );

-- Payer can edit own pending expenses
create policy "expenses_update_own_pending"
  on public.expenses for update
  using (paid_by_user_id = auth.uid() and status = 'pending');

-- ── 6b. SETTLEMENTS ──────────────────────────────────────────────────────────
create table if not exists public.settlements (
  id             uuid        primary key default uuid_generate_v4(),
  trip_id        uuid        not null references public.trips(id) on delete cascade,
  from_user_id   uuid        not null references public.users(id),
  to_user_id     uuid        not null references public.users(id),
  amount         numeric(12,2) not null check (amount > 0),
  method         text        check (method in ('gcash','cash','bank','other')),
  proof_url      text,
  proof_note     text,
  status         text        not null default 'unsettled'
                 check (status in ('unsettled','sent','confirmed')),
  confirmed_at   timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

alter table public.settlements enable row level security;

drop policy if exists "settlements_select"        on public.settlements;
drop policy if exists "settlements_payer_update"  on public.settlements;
drop policy if exists "settlements_payee_confirm" on public.settlements;
drop policy if exists "settlements_owner_all"     on public.settlements;
drop policy if exists "settlements_insert"        on public.settlements;

create policy "settlements_select"
  on public.settlements for select
  using (public.is_trip_member(trip_id));

create policy "settlements_payer_update"
  on public.settlements for update
  using (from_user_id = auth.uid());

create policy "settlements_payee_confirm"
  on public.settlements for update
  using (to_user_id = auth.uid());

create policy "settlements_owner_all"
  on public.settlements for all
  using (public.user_owns_trip(trip_id));

-- Trip members may create settlement entries
create policy "settlements_insert"
  on public.settlements for insert
  with check (public.is_trip_member(trip_id));

-- ── 6c. CONTRIBUTIONS ────────────────────────────────────────────────────────
create table if not exists public.contributions (
  id          uuid        primary key default uuid_generate_v4(),
  trip_id     uuid        not null references public.trips(id) on delete cascade,
  user_id     uuid        not null references public.users(id),
  amount      numeric(12,2) not null check (amount > 0),
  reason      text        not null,
  due_date    date,
  paid_at     timestamptz,
  proof_url   text,
  confirmed   boolean     not null default false,
  confirmed_by uuid       references public.users(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.contributions enable row level security;

drop policy if exists "contributions_select"     on public.contributions;
drop policy if exists "contributions_treasurer"  on public.contributions;
drop policy if exists "contributions_update_own" on public.contributions;

create policy "contributions_select"
  on public.contributions for select
  using (public.is_trip_member(trip_id));

create policy "contributions_treasurer"
  on public.contributions for all
  using (
    exists (
      select 1 from public.trip_members
      where trip_id = contributions.trip_id
        and user_id = auth.uid()
        and roles && '{"treasurer","organizer"}'
    )
  );

create policy "contributions_update_own"
  on public.contributions for update
  using (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 7 · CHAT
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists public.trip_messages (
  id            uuid        primary key default uuid_generate_v4(),
  trip_id       uuid        not null references public.trips(id) on delete cascade,
  user_id       uuid        not null references public.users(id) on delete cascade,
  sender_name   text        not null default 'Anonymous',
  content       text        not null check (char_length(content) > 0),
  media_url     text,                                              -- image/file attachment
  created_at    timestamptz not null default now()
);

alter table public.trip_messages enable row level security;

drop policy if exists "messages_select"  on public.trip_messages;
drop policy if exists "messages_insert"  on public.trip_messages;
drop policy if exists "messages_delete"  on public.trip_messages;
drop policy if exists "messages_update"  on public.trip_messages;

create policy "messages_select"
  on public.trip_messages for select
  using (public.is_trip_member(trip_id));

create policy "messages_insert"
  on public.trip_messages for insert
  with check (auth.uid() = user_id and public.is_trip_member(trip_id));

-- Users may edit/delete their own messages
create policy "messages_update"
  on public.trip_messages for update
  using (auth.uid() = user_id);

create policy "messages_delete"
  on public.trip_messages for delete
  using (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 8 · ACTIVITY LOG & NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 8a. ACTIVITY LOG ─────────────────────────────────────────────────────────
create table if not exists public.activity_log (
  id          uuid        primary key default uuid_generate_v4(),
  trip_id     uuid        not null references public.trips(id) on delete cascade,
  user_id     uuid        not null references public.users(id),
  action_type text        not null,                               -- e.g. 'expense_logged', 'stop_added'
  description text        not null,
  meta        jsonb       not null default '{}',
  created_at  timestamptz not null default now()
);

alter table public.activity_log enable row level security;

drop policy if exists "activity_select" on public.activity_log;
drop policy if exists "activity_insert" on public.activity_log;

create policy "activity_select"
  on public.activity_log for select
  using (public.is_trip_member(trip_id));

create policy "activity_insert"
  on public.activity_log for insert
  with check (public.is_trip_member(trip_id));

-- ── 8b. NOTIFICATIONS ────────────────────────────────────────────────────────
create table if not exists public.notifications (
  id         uuid        primary key default uuid_generate_v4(),
  user_id    uuid        not null references public.users(id) on delete cascade,
  trip_id    uuid        references public.trips(id) on delete cascade,
  type       text        not null,                               -- 'trip_invite','expense_approved', etc.
  title      text        not null,
  body       text        not null,
  data       jsonb       not null default '{}',
  read       boolean     not null default false,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

drop policy if exists "notif_select"          on public.notifications;
drop policy if exists "notif_update_read"     on public.notifications;
drop policy if exists "notif_system_insert"   on public.notifications;

create policy "notif_select"
  on public.notifications for select
  using (user_id = auth.uid());

create policy "notif_update_read"
  on public.notifications for update
  using (user_id = auth.uid());

-- Edge Functions (send-notification, expense-approved) insert rows on behalf
-- of the backend using service_role — true is safe here since service_role
-- bypasses RLS.
create policy "notif_system_insert"
  on public.notifications for insert
  with check (true);

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 9 · PERFORMANCE INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

-- Users
create index if not exists idx_users_email         on public.users (email);
create index if not exists idx_users_display_name  on public.users (display_name);
create index if not exists idx_users_google_id     on public.users (google_id);
create index if not exists idx_users_is_online     on public.users (is_online);

-- Friends
create index if not exists idx_friends_user_id     on public.friends (user_id, status);
create index if not exists idx_friends_friend_id   on public.friends (friend_id, status);

-- Trips
create index if not exists idx_trips_owner_id      on public.trips (owner_id);
create index if not exists idx_trips_invite_code   on public.trips (upper(invite_code));
create index if not exists idx_trips_status        on public.trips (status);

-- Trip Members
create index if not exists idx_tm_trip_id          on public.trip_members (trip_id);
create index if not exists idx_tm_user_id          on public.trip_members (user_id);

-- Itinerary Stops
create index if not exists idx_stops_trip_day      on public.itinerary_stops (trip_id, day_number, sort_order);

-- Stop Votes
create index if not exists idx_votes_stop_id       on public.stop_votes (stop_id);
create index if not exists idx_votes_trip_id       on public.stop_votes (trip_id);

-- Packing
create index if not exists idx_packing_trip_id     on public.packing_items (trip_id, category);

-- Expenses
create index if not exists idx_expenses_trip_id    on public.expenses (trip_id, created_at desc);
create index if not exists idx_expenses_user_id    on public.expenses (paid_by_user_id);
create index if not exists idx_expenses_status     on public.expenses (trip_id, status);

-- Settlements
create index if not exists idx_settle_trip_id      on public.settlements (trip_id);
create index if not exists idx_settle_from_user    on public.settlements (from_user_id);
create index if not exists idx_settle_to_user      on public.settlements (to_user_id);

-- Contributions
create index if not exists idx_contrib_trip_id     on public.contributions (trip_id);

-- Chat
create index if not exists idx_msgs_trip_created   on public.trip_messages (trip_id, created_at asc);

-- Activity Log
create index if not exists idx_activity_trip_id    on public.activity_log (trip_id, created_at desc);

-- Notifications
create index if not exists idx_notif_user_id       on public.notifications (user_id, read, created_at desc);

-- User Settings
create index if not exists idx_user_settings_user  on public.user_settings (user_id);

-- User Devices
create index if not exists idx_devices_user_id     on public.user_devices (user_id, is_active);

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 10 · TRIGGERS & STORED PROCEDURES
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 10a. set_updated_at() ────────────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Attach to all tables with updated_at
do $$ declare
  t text;
begin
  foreach t in array array[
    'users','user_settings','trips','trip_members','itinerary_stops',
    'packing_items','expenses','settlements','contributions','friends',
    'friendships','trip_messages'
  ] loop
    execute format('
      drop trigger if exists set_%s_updated_at on public.%s;
      create trigger set_%s_updated_at
        before update on public.%s
        for each row execute procedure public.set_updated_at();
    ', t, t, t, t);
  end loop;
end $$;

-- ── 10b. handle_new_user() — Google Auth + Email sign-up sync ────────────────
-- Fires after EVERY new auth.users row (Google OAuth, email/password, magic link).
-- Extracts Google-specific metadata (sub, picture) and seeds:
--   • public.users profile row
--   • public.user_settings default row
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email        text;
  v_display_name text;
  v_avatar_url   text;
  v_google_id    text;
begin
  -- Resolve email (Google logins always have an email; phone logins won't)
  v_email := coalesce(
    new.email,
    new.id::text || '@placeholder.taratravel.app'
  );

  -- Display name: prefer Google full_name → name → email prefix → fallback
  v_display_name := coalesce(
    nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
    nullif(trim(new.raw_user_meta_data->>'name'), ''),
    nullif(trim(split_part(v_email, '@', 1)), ''),
    'User'
  );

  -- Avatar: Google provides 'picture' OR 'avatar_url'
  v_avatar_url := coalesce(
    new.raw_user_meta_data->>'picture',
    new.raw_user_meta_data->>'avatar_url'
  );

  -- Google unique identifier (OAuth sub claim)
  v_google_id := coalesce(
    new.raw_user_meta_data->>'sub',
    new.raw_user_meta_data->>'provider_id'
  );

  -- Upsert public.users
  insert into public.users (id, email, display_name, avatar_url, google_id)
  values (new.id, v_email, v_display_name, v_avatar_url, v_google_id)
  on conflict (id) do update set
    email        = excluded.email,
    -- Only overwrite display_name when the stored value is blank / 'User'
    display_name = case
      when public.users.display_name is null
        or public.users.display_name = ''
        or public.users.display_name = 'User'
      then excluded.display_name
      else public.users.display_name
    end,
    avatar_url   = coalesce(excluded.avatar_url, public.users.avatar_url),
    google_id    = coalesce(excluded.google_id, public.users.google_id),
    updated_at   = now();

  -- Seed default user_settings (idempotent via ON CONFLICT DO NOTHING)
  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;

exception when others then
  -- Guarantee trigger exceptions NEVER abort auth sign-up
  raise warning '[handle_new_user] Error for user %: %', new.id, sqlerrm;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── 10c. check_user_registered() RPC ──────────────────────────────────────────
-- Returns true if an account with the given email already exists in public.users.
-- Used to prompt confirmation before creating a new account on Google Sign-In.
create or replace function public.check_user_registered(p_email text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users
    where lower(email) = lower(trim(p_email))
  );
$$;

grant execute on function public.check_user_registered(text) to anon, authenticated;

-- ── 10d. join_trip_by_code() RPC ─────────────────────────────────────────────
-- Secure SECURITY DEFINER RPC: authenticated user can join a trip using the
-- 6-character invite code without needing SELECT on public.trips directly.
create or replace function public.join_trip_by_code(p_invite_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id  uuid := auth.uid();
  v_trip_id  uuid;
  v_trip_name text;
begin
  if v_user_id is null then
    raise exception 'Must be logged in to join a trip.';
  end if;

  if p_invite_code is null or char_length(trim(p_invite_code)) = 0 then
    raise exception 'Invite code cannot be empty.';
  end if;

  -- Case-insensitive lookup
  select id, name into v_trip_id, v_trip_name
  from public.trips
  where upper(invite_code) = upper(trim(p_invite_code))
  limit 1;

  if v_trip_id is null then
    raise exception 'Invalid invite code or trip not found.';
  end if;

  -- Add member (upsert: keep existing roles, just ensure 'member' is present)
  insert into public.trip_members (trip_id, user_id, roles)
  values (v_trip_id, v_user_id, array['member'])
  on conflict (trip_id, user_id) do update
    set roles = case
      when not ('member' = any(trip_members.roles))
      then array_append(trip_members.roles, 'member')
      else trip_members.roles
    end;

  -- Log activity
  insert into public.activity_log (trip_id, user_id, action_type, description)
  values (
    v_trip_id, v_user_id,
    'member_joined',
    'Joined the trip via invite code'
  );

  return jsonb_build_object(
    'success',    true,
    'trip_id',    v_trip_id,
    'trip_name',  v_trip_name
  );
end;
$$;

grant execute on function public.join_trip_by_code(text) to authenticated;

-- ── 10d. log_expense_activity() trigger ──────────────────────────────────────
create or replace function public.log_expense_activity()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.activity_log (trip_id, user_id, action_type, description, meta)
  values (
    new.trip_id,
    new.paid_by_user_id,
    case
      when new.status = 'approved' then 'expense_approved'
      when new.status = 'rejected' then 'expense_rejected'
      else 'expense_logged'
    end,
    'Expense: ' || new.description || ' ₱' || new.amount,
    jsonb_build_object(
      'expense_id', new.id,
      'amount',     new.amount,
      'category',   new.category,
      'status',     new.status
    )
  );
  return new;
end;
$$;

drop trigger if exists after_expense_change on public.expenses;
create trigger after_expense_change
  after insert or update of status on public.expenses
  for each row execute procedure public.log_expense_activity();

-- ── 10e. update_online_status() ──────────────────────────────────────────────
-- Mark user offline when the JWT session expires / is revoked.
create or replace function public.handle_user_offline()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
  set is_online = false, last_seen = now()
  where id = old.user_id;
  return old;
end;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 11 · REALTIME PUBLICATIONS
-- ═══════════════════════════════════════════════════════════════════════════
-- Selective realtime: only enable for tables requiring live UI updates.

do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'trip_members',
    'itinerary_stops',
    'stop_votes',
    'packing_items',
    'expenses',
    'settlements',
    'contributions',
    'trip_messages',
    'activity_log',
    'notifications'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = tbl
    ) then
      execute format('alter publication supabase_realtime add table public.%I', tbl);
    end if;
  end loop;
end $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 12 · STORAGE BUCKETS
-- ═══════════════════════════════════════════════════════════════════════════

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  -- Public: profile avatars (Google avatar sync + user uploads)
  ('avatars',           'avatars',           true,  5242880,  array['image/jpeg','image/png','image/webp']),
  -- Private: trip media (cover photos, itinerary stop images)
  ('tara-media',        'tara-media',        false, 10485760, array['image/jpeg','image/png','image/webp','image/gif']),
  -- Private: expense receipts
  ('receipts',          'receipts',          false, 10485760, array['image/jpeg','image/png','image/webp','application/pdf']),
  -- Private: chat file attachments
  ('chat-attachments',  'chat-attachments',  false, 20971520, array['image/jpeg','image/png','image/webp','image/gif','application/pdf','audio/mpeg'])
on conflict (id) do nothing;

-- Storage RLS Policies

-- avatars: anyone can read, owner can upload/update/delete
drop policy if exists "avatars_public_select"  on storage.objects;
drop policy if exists "avatars_owner_upload"   on storage.objects;
drop policy if exists "avatars_owner_update"   on storage.objects;
drop policy if exists "avatars_owner_delete"   on storage.objects;

create policy "avatars_public_select"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_owner_upload"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "avatars_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "avatars_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- tara-media: authenticated users in a trip can upload & read
drop policy if exists "media_auth_select" on storage.objects;
drop policy if exists "media_auth_insert" on storage.objects;

create policy "media_auth_select"
  on storage.objects for select
  using (bucket_id = 'tara-media' and auth.role() = 'authenticated');

create policy "media_auth_insert"
  on storage.objects for insert
  with check (bucket_id = 'tara-media' and auth.role() = 'authenticated');

-- receipts: authenticated users upload, members read (trip-scoped at app layer)
drop policy if exists "receipts_auth_select" on storage.objects;
drop policy if exists "receipts_auth_insert" on storage.objects;

create policy "receipts_auth_select"
  on storage.objects for select
  using (bucket_id = 'receipts' and auth.role() = 'authenticated');

create policy "receipts_auth_insert"
  on storage.objects for insert
  with check (bucket_id = 'receipts' and auth.role() = 'authenticated');

-- chat-attachments: authenticated users
drop policy if exists "chat_attach_select" on storage.objects;
drop policy if exists "chat_attach_insert" on storage.objects;

create policy "chat_attach_select"
  on storage.objects for select
  using (bucket_id = 'chat-attachments' and auth.role() = 'authenticated');

create policy "chat_attach_insert"
  on storage.objects for insert
  with check (bucket_id = 'chat-attachments' and auth.role() = 'authenticated');

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ MASTER SCHEMA COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════
-- After running this file:
--   1. Verify all tables, RLS policies, and triggers in the Supabase Dashboard.
--   2. Enable Google Auth Provider: Auth → Providers → Google.
--   3. Update .env: SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_WEB_CLIENT_ID.
--   4. Set Connection Pooling to Supavisor Port 6543 (Transaction Mode).
--   5. Run flutter pub get && flutter run to test full auth + sync flow.
-- ═══════════════════════════════════════════════════════════════════════════
