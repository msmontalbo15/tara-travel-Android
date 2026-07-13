-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · SUPABASE SQL MIGRATIONS
-- Run these in order in your Supabase SQL editor
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 001: Enable UUID extension ───────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── 002: USERS ───────────────────────────────────────────────────────────────
create table public.users (
  id                    uuid primary key default auth.uid(),
  email                 text unique not null,
  display_name          text not null default '',
  avatar_url            text,
  google_id             text unique,
  gcash_qr_url          text,
  gcash_number          text,
  health_notes          text,
  blood_type            text,
  allergies             text[] default '{}',
  dietary               text[] default '{}',
  home_city             text,
  phone                 text,
  share_health_with_org boolean default false,
  created_at            timestamptz default now(),
  updated_at            timestamptz default now()
);

alter table public.users enable row level security;
create policy "Users can read own profile"   on public.users for select using (auth.uid() = id);
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.users for insert with check (auth.uid() = id);

-- ── 003: TRIPS ───────────────────────────────────────────────────────────────
create table public.trips (
  id                uuid primary key default uuid_generate_v4(),
  name              text not null,
  destination       text not null,
  destination_lat   double precision,
  destination_lng   double precision,
  start_date        date not null,
  end_date          date not null,
  budget            numeric(12,2) default 0,
  currency          text default 'PHP',
  type              text default 'beach' check (type in ('beach','city','adventure','nature','cultural')),
  transport_mode    text default 'car',
  transport_meta    jsonb default '{}',
  split_method      text default 'equal' check (split_method in ('equal','fixed','bigger','category')),
  split_meta        jsonb default '{}',
  owner_id          uuid not null references public.users(id) on delete cascade,
  invite_code       text unique not null default upper(substr(md5(random()::text), 1, 6)),
  invite_expires_at timestamptz,
  discord_channel_id text,
  status            text default 'planned' check (status in ('draft','planned','active','completed','archived')),
  cover_color       text,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

alter table public.trips enable row level security;
create policy "Owner can manage trip" on public.trips for all using (auth.uid() = owner_id);
-- Note: 'Members can view their trips' policy is moved below the trip_members table creation

-- ── 004: TRIP MEMBERS ────────────────────────────────────────────────────────
create table public.trip_members (
  id               uuid primary key default uuid_generate_v4(),
  trip_id          uuid not null references public.trips(id) on delete cascade,
  user_id          uuid not null references public.users(id) on delete cascade,
  roles            text[] default '{"member"}',
  joined_at        timestamptz default now(),
  location_sharing boolean default true,
  last_lat         double precision,
  last_lng         double precision,
  last_speed       double precision,
  last_seen        timestamptz,
  unique (trip_id, user_id)
);

alter table public.trip_members enable row level security;
create policy "Members can view other members" on public.trip_members for select
  using (exists (select 1 from public.trip_members tm where tm.trip_id = trip_members.trip_id and tm.user_id = auth.uid()));
create policy "Users can update own membership" on public.trip_members for update using (user_id = auth.uid());
create policy "Trip owner can manage members" on public.trip_members for all
  using (exists (select 1 from public.trips where id = trip_id and owner_id = auth.uid()));

-- Now that trip_members exists, create the trip member view policy for public.trips
create policy "Members can view their trips" on public.trips for select
  using (
    auth.uid() = owner_id or
    exists (select 1 from public.trip_members where trip_id = trips.id and user_id = auth.uid())
  );

-- ── 005: ITINERARY STOPS ─────────────────────────────────────────────────────
create table public.itinerary_stops (
  id               uuid primary key default uuid_generate_v4(),
  trip_id          uuid not null references public.trips(id) on delete cascade,
  day_number       int not null,
  sort_order       int default 0,
  time_start       text,
  time_end         text,
  duration_min     int,
  title            text not null,
  type             text default 'activity' check (type in ('hotel','activity','food','transport','custom')),
  notes            text,
  cost_estimate    numeric(10,2),
  assigned_user_id uuid references public.users(id),
  google_place_id  text,
  lat              double precision,
  lng              double precision,
  status           text default 'planned' check (status in ('planned','arrived','completed','skipped')),
  created_at       timestamptz default now()
);

alter table public.itinerary_stops enable row level security;
create policy "Members can view stops" on public.itinerary_stops for select
  using (exists (select 1 from public.trip_members where trip_id = itinerary_stops.trip_id and user_id = auth.uid()));
create policy "Navigator/Organizer can manage stops" on public.itinerary_stops for all
  using (exists (
    select 1 from public.trip_members
    where trip_id = itinerary_stops.trip_id and user_id = auth.uid()
    and (roles && '{"organizer","navigator"}')
  ));

-- ── 006: EXPENSES ────────────────────────────────────────────────────────────
create table public.expenses (
  id               uuid primary key default uuid_generate_v4(),
  trip_id          uuid not null references public.trips(id) on delete cascade,
  description      text not null,
  amount           numeric(12,2) not null,
  category         text not null default 'other',
  paid_by_user_id  uuid not null references public.users(id),
  receipt_url      text,
  status           text default 'pending' check (status in ('pending','approved','rejected')),
  approved_by      uuid references public.users(id),
  rejection_note   text,
  created_at       timestamptz default now()
);

alter table public.expenses enable row level security;
create policy "Members can view expenses" on public.expenses for select
  using (exists (select 1 from public.trip_members where trip_id = expenses.trip_id and user_id = auth.uid()));
create policy "Members can add expenses" on public.expenses for insert
  with check (exists (select 1 from public.trip_members where trip_id = expenses.trip_id and user_id = auth.uid()));
create policy "Treasurer/Organizer can approve expenses" on public.expenses for update
  using (exists (
    select 1 from public.trip_members
    where trip_id = expenses.trip_id and user_id = auth.uid()
    and (roles && '{"treasurer","organizer"}')
  ));

-- ── 007: SETTLEMENTS ─────────────────────────────────────────────────────────
create table public.settlements (
  id             uuid primary key default uuid_generate_v4(),
  trip_id        uuid not null references public.trips(id) on delete cascade,
  from_user_id   uuid not null references public.users(id),
  to_user_id     uuid not null references public.users(id),
  amount         numeric(12,2) not null,
  method         text check (method in ('gcash','cash','bank')),
  proof_url      text,
  proof_note     text,
  status         text default 'unsettled' check (status in ('unsettled','sent','confirmed')),
  confirmed_at   timestamptz,
  created_at     timestamptz default now()
);

alter table public.settlements enable row level security;
create policy "Members can view settlements" on public.settlements for select
  using (exists (select 1 from public.trip_members where trip_id = settlements.trip_id and user_id = auth.uid()));
create policy "Payer can update settlement" on public.settlements for update using (from_user_id = auth.uid());
create policy "Payee can confirm settlement" on public.settlements for update using (to_user_id = auth.uid());
create policy "Organizer can manage settlements" on public.settlements for all
  using (exists (select 1 from public.trips where id = trip_id and owner_id = auth.uid()));

-- ── 008: PACKING ITEMS ───────────────────────────────────────────────────────
create table public.packing_items (
  id               uuid primary key default uuid_generate_v4(),
  trip_id          uuid not null references public.trips(id) on delete cascade,
  name             text not null,
  category         text not null default 'Essentials',
  is_checked       boolean default false,
  assigned_user_id uuid references public.users(id),
  is_ai_suggested  boolean default false,
  created_by       uuid references public.users(id),
  created_at       timestamptz default now()
);

alter table public.packing_items enable row level security;
create policy "Members can view packing" on public.packing_items for select
  using (exists (select 1 from public.trip_members where trip_id = packing_items.trip_id and user_id = auth.uid()));
create policy "Members can manage packing" on public.packing_items for all
  using (exists (select 1 from public.trip_members where trip_id = packing_items.trip_id and user_id = auth.uid()));

-- ── 009: CONTRIBUTIONS ───────────────────────────────────────────────────────
create table public.contributions (
  id          uuid primary key default uuid_generate_v4(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  user_id     uuid not null references public.users(id),
  amount      numeric(12,2) not null,
  reason      text not null,
  due_date    date,
  paid_at     timestamptz,
  proof_url   text,
  confirmed   boolean default false,
  created_at  timestamptz default now()
);

alter table public.contributions enable row level security;
create policy "Members can view contributions" on public.contributions for select
  using (exists (select 1 from public.trip_members where trip_id = contributions.trip_id and user_id = auth.uid()));
create policy "Treasurer can manage contributions" on public.contributions for all
  using (exists (
    select 1 from public.trip_members
    where trip_id = contributions.trip_id and user_id = auth.uid()
    and (roles && '{"treasurer","organizer"}')
  ));
create policy "User can update own contribution" on public.contributions for update using (user_id = auth.uid());

-- ── 010: ACTIVITY LOG ────────────────────────────────────────────────────────
create table public.activity_log (
  id          uuid primary key default uuid_generate_v4(),
  trip_id     uuid not null references public.trips(id) on delete cascade,
  user_id     uuid not null references public.users(id),
  action_type text not null,
  description text not null,
  meta        jsonb default '{}',
  created_at  timestamptz default now()
);

alter table public.activity_log enable row level security;
create policy "Members can view activity" on public.activity_log for select
  using (exists (select 1 from public.trip_members where trip_id = activity_log.trip_id and user_id = auth.uid()));
create policy "Members can log activity" on public.activity_log for insert
  with check (exists (select 1 from public.trip_members where trip_id = activity_log.trip_id and user_id = auth.uid()));

-- ── 011: NOTIFICATIONS ───────────────────────────────────────────────────────
create table public.notifications (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.users(id) on delete cascade,
  trip_id    uuid references public.trips(id) on delete cascade,
  type       text not null,
  title      text not null,
  body       text not null,
  data       jsonb default '{}',
  read       boolean default false,
  created_at timestamptz default now()
);

alter table public.notifications enable row level security;
create policy "Users can view own notifications" on public.notifications for select using (user_id = auth.uid());
create policy "Users can mark own as read"       on public.notifications for update using (user_id = auth.uid());
create policy "System can insert notifications"  on public.notifications for insert with check (true);

-- ── 012: REALTIME ────────────────────────────────────────────────────────────
-- Enable Realtime for live location + expense updates
alter publication supabase_realtime add table public.trip_members;
alter publication supabase_realtime add table public.expenses;
alter publication supabase_realtime add table public.settlements;
alter publication supabase_realtime add table public.activity_log;
alter publication supabase_realtime add table public.notifications;

-- ── 013: TRIGGERS - updated_at ───────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

create trigger set_users_updated_at before update on public.users
  for each row execute procedure public.set_updated_at();
create trigger set_trips_updated_at before update on public.trips
  for each row execute procedure public.set_updated_at();

-- ── 014: AUTO-LOG ACTIVITY ───────────────────────────────────────────────────
create or replace function public.log_expense_activity()
returns trigger language plpgsql security definer as $$
begin
  insert into public.activity_log (trip_id, user_id, action_type, description, meta)
  values (
    new.trip_id, new.paid_by_user_id,
    case when new.status = 'approved' then 'expense_approved' else 'expense_logged' end,
    'Logged expense: ' || new.description || ' ₱' || new.amount,
    jsonb_build_object('expense_id', new.id, 'amount', new.amount, 'category', new.category)
  );
  return new;
end; $$;

create trigger after_expense_insert after insert on public.expenses
  for each row execute procedure public.log_expense_activity();

-- ── 015: STORAGE BUCKETS ─────────────────────────────────────────────────────
insert into storage.buckets (id, name, public) values
  ('tara-media', 'tara-media', false),
  ('avatars',    'avatars',    true);

create policy "Members can upload receipts" on storage.objects for insert
  with check (bucket_id = 'tara-media' and auth.role() = 'authenticated');
create policy "Members can read receipts" on storage.objects for select
  using (bucket_id = 'tara-media' and auth.role() = 'authenticated');
create policy "Anyone can read avatars" on storage.objects for select
  using (bucket_id = 'avatars');
create policy "Users can upload own avatar" on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

-- ── SEED: Default packing templates ──────────────────────────────────────────
-- (Run after creating a trip to pre-populate packing items)
-- Example: insert into packing_items (trip_id, name, category, is_ai_suggested) values
--   ('YOUR_TRIP_ID', 'Passport / ID', 'Essentials', false),
--   ('YOUR_TRIP_ID', 'Cash (PHP)', 'Essentials', false), ...
