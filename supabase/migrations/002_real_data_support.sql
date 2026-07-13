create table if not exists public.member_locations (
  member_id uuid primary key references public.users(id) on delete cascade,
  trip_id uuid not null references public.trips(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  last_updated timestamptz default now()
);

alter table public.member_locations enable row level security;
create policy "Members can view trip locations" on public.member_locations for select
  using (exists (select 1 from public.trip_members where trip_id = member_locations.trip_id and user_id = auth.uid()));
create policy "Members can update own location" on public.member_locations for all
  using (member_id = auth.uid());

create table if not exists public.destinations (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  country text default 'Philippines',
  distance_from_metro text,
  best_mode text,
  avg_cost_range text,
  photo_emoji text default '🌏',
  tag text default 'General',
  description text,
  is_trending boolean default false,
  is_weekend_getaway boolean default false,
  is_recommended boolean default false,
  recommended_reason text,
  best_time_to_visit text default 'Year-round',
  created_at timestamptz default now()
);

alter table public.destinations enable row level security;
create policy "Anyone can read destinations" on public.destinations for select using (true);

create table if not exists public.trip_messages (
  id uuid primary key default uuid_generate_v4(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  body text not null,
  created_at timestamptz default now()
);

alter table public.trip_messages enable row level security;
create policy "Members can view trip messages" on public.trip_messages for select
  using (exists (select 1 from public.trip_members where trip_id = trip_messages.trip_id and user_id = auth.uid()));
create policy "Members can send trip messages" on public.trip_messages for insert
  with check (exists (select 1 from public.trip_members where trip_id = trip_messages.trip_id and user_id = auth.uid()));

insert into public.destinations (name, distance_from_metro, best_mode, avg_cost_range, photo_emoji, tag, description, is_trending, is_weekend_getaway, is_recommended, recommended_reason, best_time_to_visit)
values
('Boracay', '~590 km from Manila', '✈️ Plane', '₱8,000–₱15,000', '🏖️', 'Beach', 'World-famous white sand beaches and turquoise waters.', true, false, true, 'Popular right now', 'Nov–May'),
('Palawan', '~580 km from Manila', '✈️ Plane', '₱12,000–₱25,000', '🌴', 'Nature', 'Pristine lagoons, diving spots, and underground rivers.', true, false, true, 'Top choice for nature trips', 'Dec–May'),
('Tagaytay', '~60 km from Manila', '🚗 Car', '₱2,000–₱5,000', '🌋', 'City', 'Cool breezes, Taal Volcano view, and great bulalo.', false, true, true, 'Easy weekend trip', 'Year-round')
on conflict do nothing;
