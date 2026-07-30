-- ═══════════════════════════════════════════════════════════════════════════
-- 009: SAFE NEW USER HANDLE TRIGGER FIX
-- Prevents Supabase Auth 500 "Database error saving new user" (unexpected_failure)
-- ═══════════════════════════════════════════════════════════════════════════

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_email text;
  v_display_name text;
begin
  v_email := coalesce(new.email, new.id::text || '@placeholder.taratravel.app');
  v_display_name := coalesce(
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'name',
    nullif(split_part(v_email, '@', 1), ''),
    'User'
  );

  insert into public.users (id, email, display_name, avatar_url)
  values (
    new.id,
    v_email,
    v_display_name,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do update set
    email = excluded.email,
    display_name = case 
      when public.users.display_name is null or public.users.display_name = '' or public.users.display_name = 'User' 
      then excluded.display_name 
      else public.users.display_name 
    end,
    avatar_url = coalesce(excluded.avatar_url, public.users.avatar_url),
    updated_at = now();

  return new;
exception when others then
  -- Guarantee that trigger failures never abort auth user sign-up
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
