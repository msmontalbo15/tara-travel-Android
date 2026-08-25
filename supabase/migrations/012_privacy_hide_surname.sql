-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 012 — Privacy: Hide Surname from Other Members
-- ─────────────────────────────────────────────────────────────────────────────
-- Adds hide_surname column to public.users and public.user_settings.
-- When enabled, other trip members and peers see the user's name formatted
-- with their surname masked (e.g. First Name + Last Initial).
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.users
  add column if not exists hide_surname boolean not null default false;

alter table public.user_settings
  add column if not exists hide_surname boolean not null default false;

comment on column public.users.hide_surname is
  'When true, hides the surname from other trip members and friends (e.g. displays First Name + Last Initial).';

comment on column public.user_settings.hide_surname is
  'User preference to hide surname from other members in trip member lists and public views.';
