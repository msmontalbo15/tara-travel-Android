---
trigger: always_on
---

# Tara Travel — Architectural Memory & Anti-Hallucination Rules

Enforces factual ground truth across all Flutter and Supabase development in Tara Travel. For full schema listings, see `docs/MEMORY.md`.

## 1. Ground-Truth Schema & Forbidden Columns

- **`trips` Table**: Has `start_date`, `end_date`, `budget`, `split_method`, `owner_id`, `status`, `invite_code`, `type` / `trip_type`, `departure_point`, `departure_lat`, `departure_lng`, `departure_map_url`, `destination_details`, `transport_mode`, `transport_meta`.
  - **NEVER QUERY / INSERT**: `destination_lat`, `destination_lng`, `invite_expires_at`, `cover_image_url`, `discord_channel_id`, `cover_color`, `cover_emoji` (permanently dropped — styling/emoji derived from `trip_type` via `AppTripTypes`).
- **`itinerary_stops` Table**: Has `id`, `trip_id`, `name`, `description`, `stop_date`, `start_time`, `end_time`, `location_name`, `latitude`, `longitude`, `cost`, `stop_type`, `status`, `booking_ref`, `order_index`.
  - **NEVER QUERY**: `duration_min`, `google_place_id`, `photo_url`, `created_by`.
- **`packing_items` Table**: Has `id`, `trip_id`, `item_name`, `category`, `is_packed`, `is_custom`, `assigned_to_user_id`.
  - **NEVER QUERY**: `quantity`, `notes`, `created_by`, `checked_by`, `checked_at`.
- **`expenses` Table**: Has `id`, `trip_id`, `description`, `amount`, `category`, `paid_by_user_id`, `status`, `receipt_url`, `rejection_note`.
  - **NEVER QUERY**: `split_meta`, `rejected_by`.
- **`friends` Table**: Use `public.friends` exclusively. `friendships` table is permanently dropped.

## 2. RLS Anti-Recursion Rule

- **Strict Ban**: Never write `SELECT 1 FROM trip_members WHERE trip_id = ...` inside a `trip_members` RLS policy.
- **Always Use Helper Functions**: `public.is_trip_member(trip_id)`, `public.user_owns_trip(trip_id)`, `public.user_can_access_trip(trip_id)`.

## 3. Architecture & State Management

- **Remote Single Source of Truth**: `TripRepository` is a direct Supabase remote repository. Do not inject local Sembast caching for trips.
- **State Management**: `flutter_riverpod` exclusively. No Bloc, GetX, or legacy Provider.
- **Session & Partitioning**: `SecureSessionRepository` restores session on startup; `DatabaseService.instance.switchUser(userId)` partitions local store per user UUID.
- **3-Layer Encryption**: RSA-2048 client keypair in Android Keystore / iOS Keychain + AES-256-GCM data payload + TLS 1.3 transport.

## 4. Name Privacy Invariant

- Always format user display names via `MemberModel.formatDisplayName(name, hideSurname: profile.hideSurname)` (e.g. `Juan Dela Cruz` becomes `Juan D.`).

## 5. 🔄 Continuous Memory Synchronization Rule (MANDATORY)

- **Rule**: Whenever any new feature, SQL migration, RPC function, repository method, Riverpod provider, service, or bugfix is implemented:
  1. **Update `docs/MEMORY.md`**: Update schemas, function indexes, providers, and architectural invariants to match the current state.
  2. **Append to `docs/IMPLEMENTATION_MEMORY.md`**: Add a chronological entry with Milestone ID (`IMP-XXX`), modified files, architectural rationale, and verification checks.
  3. **Update `docs/CHANGELOG.md`** (or sync via `tools/generate_changelog.ps1`): Ensure changelog entries reflect changes.

