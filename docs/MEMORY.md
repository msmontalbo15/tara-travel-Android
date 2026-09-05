# 🧠 TARA TRAVEL — ARCHITECTURAL MEMORY & AI GROUND TRUTH
> **AUTHORITATIVE CONTEXT FOR AI ASSISTANTS & CORE DEVELOPERS**  
> **Status**: Production Verified  
> **Last Synced**: September 2026  
> **Scope**: Complete Database Schema, Stored Functions, RPCs, Repositories, State Providers, Security Invariants, Feature Implementations, and [Software Design Patterns & REST Standards](file:///d:/Spencer/Downloads/tara_travel/SOFTWARE_DESIGN_PATTERNS.md).

---

## 1. 🏗️ SYSTEM SPECIFICATIONS & TECH STACK

| Component | Technology | Version / Standard | Architectural Role |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK) | `>=3.2.0 <4.0.0` | Cross-platform client targeting Android & iOS |
| **State Management** | `flutter_riverpod` | `^3.3.1` | MVI / MVVM state architecture via Notifiers & Providers |
| **Remote BaaS** | `supabase_flutter` | `^2.12.2` | PostgreSQL 15, PostgREST CRUD, Realtime WebSockets (Single Source of Truth) |
| **Secure Keystore** | `flutter_secure_storage` | `^10.3.1` | Android Keystore (`EncryptedSharedPreferences`) & iOS Keychain |
| **Network State** | `connectivity_plus` | `^6.1.3` | Reactive network connectivity monitoring |
| **Cryptography** | `pointycastle`, `encrypt`, `crypto` | `^3.9.1`, `^5.0.3`, `^3.0.6` | 3-Layer RSA-2048 + AES-256-GCM + TLS 1.3 |
| **API Client** | `dio` + `http` | `^5.9.2` / `^1.6.0` | Gateway interceptor, token rotation, audit logging |
| **Maps & Geo** | `flutter_map`, `latlong2`, `geolocator`, `location` | `^7.0.2`, `^0.9.1`, `^14.0.1`, `^8.0.1` | Free OpenStreetMap rendering, PostGIS live ride tracking, Nominatim PH geocoding |
| **Camera QR Scanner** | `mobile_scanner` | `^7.4.0` | Hardware-accelerated MLKit (Android) / AVFoundation (iOS) QR & barcode scanning |

---

## 2. 🗄️ SUPABASE DATABASE SCHEMAS (16 ACTIVE TABLES)

```sql
-- 1. USERS
public.users (
  id uuid primary key,                     -- matches auth.users.id
  email text,
  full_name text,                          -- fallback name
  display_name text,                       -- primary display name
  avatar_url text,
  phone text,                              -- encrypted at rest (3-Layer)
  gcash_number text,                       -- encrypted at rest (3-Layer)
  gcash_qr_url text,
  bio text,
  blood_type text,
  home_city text,
  allergies text[],
  dietary text[],                          -- tags: country:*, region:*, privacy:hide_surname
  share_health_with_org boolean default false,
  hide_surname boolean not null default false,
  is_online boolean default false,
  last_seen timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. USER SETTINGS
public.user_settings (
  user_id uuid primary key references public.users(id) on delete cascade,
  dark_mode boolean default false,
  push_notifications boolean default true,
  biometric_login boolean default false,
  sms_alerts boolean default false,
  hide_surname boolean not null default false,
  updated_at timestamptz default now()
);

-- 3. USER DEVICES
public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  device_token text not null,
  platform text check (platform in ('android','ios','web')),
  last_active timestamptz default now(),
  created_at timestamptz default now()
);

-- 4. FRIENDS (Reciprocal Social Graph)
public.friends (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  friend_id uuid references public.users(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'rejected', 'blocked')),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (user_id, friend_id)
);

-- 5. TRIPS (Authoritative Remote Source)
public.trips (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  destination text not null,
  start_date timestamptz not null,         -- Dart: fromDate
  end_date timestamptz not null,           -- Dart: toDate
  type text not null check (type in ('beach','city','adventure','nature','cultural','heritage','pilgrimage','business','other')),
  budget numeric(12,2) not null default 0, -- Dart: totalBudget
  split_method text not null default 'equal' check (split_method in ('equal','custom','percentage','fixed')),
  owner_id uuid references public.users(id) on delete cascade,
  status text not null default 'planned' check (status in ('draft','planned','ongoing','completed','archived')),
  invite_code text unique,
  departure_point text,
  departure_lat double precision,
  departure_lng double precision,
  departure_map_url text,
  destination_details jsonb,
  transport_mode text,
  transport_meta jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 6. TRIP MEMBERS
public.trip_members (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  role text not null default 'member' check (role in ('organizer','treasurer','navigator','buyer','documenter','member')),
  roles text[] default array['member']::text[],
  is_online boolean default false,
  last_seen timestamptz,
  is_location_sharing_paused boolean default false,
  status text not null default 'approved' check (status in ('pending','approved','rejected')),
  joined_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (trip_id, user_id)
);

-- 7. ITINERARY STOPS
public.itinerary_stops (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  title text not null,                     -- Map to stop title/name
  name text,
  description text,
  notes text,
  stop_date date,
  time_start text,
  time_end text,
  location text,
  address text,
  lat double precision,
  lng double precision,
  cost_estimate numeric(10,2) default 0,
  type text not null check (type in ('hotel','activity','food','transport','custom')),
  booking_ref text,
  visited_at timestamptz,
  checked_in_data jsonb default '{}'::jsonb,
  day_number integer default 1,
  sort_order integer default 0,
  assigned_user_id uuid references public.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 8. PACKING ITEMS
public.packing_items (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  name text not null,                      -- DB: name / item_name
  category text not null,                  -- essentials, clothing, toiletries, gadgets, documents, medicines, food, others, or custom
  sub_category text,                       -- user-defined custom sub-category (e.g. Breakfast Menu, Tops, Skincare)
  is_checked boolean default false,
  is_ai_suggested boolean default false,
  is_custom boolean default false,
  assigned_user_id uuid references public.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 10. EXPENSES
public.expenses (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  description text not null,
  amount numeric(10,2) not null,
  category text not null check (category in ('hotel','food','activities','transport','custom')),
  paid_by_user_id uuid references public.users(id) on delete set null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  receipt_url text,
  rejection_note text,
  approved_by uuid references public.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 11. SETTLEMENTS
public.settlements (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  payer_id uuid references public.users(id) on delete cascade,
  payee_id uuid references public.users(id) on delete cascade,
  amount numeric(10,2) not null,
  is_settled boolean default false,
  settled_at timestamptz,
  payment_method text,
  proof_photo_url text,
  created_at timestamptz default now()
);

-- 12. CONTRIBUTIONS
public.contributions (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  amount numeric(10,2) not null,
  paid_at timestamptz default now(),
  receipt_url text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  payment_reference text,
  created_at timestamptz default now()
);

-- 13. TRIP MESSAGES (Live Chat & Rich Embed Activity Hub)
public.trip_messages (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  sender_name text not null,
  content text not null,
  message_type text default 'text',        -- 'text', 'poll', 'announcement', 'quick_travel', 'itinerary_snippet', 'expense_request', 'packing_alert', 'location_drop', 'media', 'tara_bot'
  media_url text,
  metadata jsonb default '{}'::jsonb,      -- Rich embed payload (stop_id, expense_id, item_id, lat/lng, briefing items)
  reactions jsonb default '{}'::jsonb,     -- Emoji reactions map: {"👍": ["user_id_1"], "❤️": ["user_id_2"]}
  is_pinned boolean default false,
  poll_id uuid references public.trip_polls(id) on delete set null,
  created_at timestamptz default now()
);

-- 13A. TRIP POLLS (Interactive In-Chat Decision Making)
public.trip_polls (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  creator_id uuid not null references public.users(id) on delete cascade,
  creator_name text not null default 'Anonymous',
  question text not null,
  options jsonb not null default '[]'::jsonb,
  category text not null default 'custom' check (category in ('food', 'departure', 'activity', 'budget', 'custom')),
  allow_multiple boolean not null default false,
  is_closed boolean not null default false,
  winner_option_id text,
  created_at timestamptz not null default now(),
  closed_at timestamptz
);

-- 13B. TRIP POLL VOTES (Undoable & Optimistic)
public.trip_poll_votes (
  id uuid primary key default gen_random_uuid(),
  poll_id uuid not null references public.trip_polls(id) on delete cascade,
  trip_id uuid not null references public.trips(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  voter_name text not null default 'Anonymous',
  option_id text not null,
  created_at timestamptz not null default now(),
  constraint unique_user_poll_option unique (poll_id, user_id, option_id)
);
-- Invariant: Votes are toggle-undoable by tapping the voted option again,
-- supported by PollsNotifier optimistic local mutation and automatic rollback.

-- 14. ACTIVITY LOG
public.activity_log (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  user_id uuid references public.users(id) on delete set null,
  action_type text not null,
  description text not null,
  metadata jsonb,
  created_at timestamptz default now()
);

-- 15. NOTIFICATIONS
public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  trip_id uuid references public.trips(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null,
  is_read boolean default false,
  data jsonb,
  created_at timestamptz default now()
);

-- 16. DESTINATIONS
public.destinations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  country text not null default 'Philippines',
  description text,
  image_url text,
  tags text[],
  rating numeric(3,2) default 5.00,
  created_at timestamptz default now()
);

-- 17. MEMBER LOCATIONS (Live Map Presence)
public.member_locations (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  updated_at timestamptz default now(),
  unique (trip_id, user_id)
);

-- 18. TRIP PERSONAL ALLOWANCES (Migration 023)
public.trip_personal_allowances (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  total_allowance numeric(12,2) not null default 0.00,
  emergency_buffer_percent numeric(4,2) not null default 0.10,
  cash_on_hand numeric(12,2) not null default 0.00,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (trip_id, user_id)
);

-- 19. PERSONAL EXPENSES (Solo Out-of-Pocket Purchases - Migration 023)
public.personal_expenses (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  description text not null,
  amount numeric(12,2) not null,
  category text not null default 'custom',
  payment_mode text not null default 'cash' check (payment_mode in ('cash', 'digital')),
  date timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- 20. APP VERSIONS & REMOTE CONFIG (Migration 026)
public.app_versions (
  id uuid primary key default gen_random_uuid(),
  platform text not null default 'android' check (platform in ('android', 'ios', 'web')),
  min_supported_version text not null,
  latest_version text not null,
  force_update_url text,
  maintenance_mode boolean not null default false,
  maintenance_title text default 'Under Scheduled Maintenance',
  maintenance_message text default 'We are currently performing routine system upgrades to improve Tara Travel. Please check back shortly.',
  estimated_back_online timestamptz,
  release_notes text default 'General performance improvements and bug fixes.',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

---

## 3. ⚡ DATABASE FUNCTIONS, PROCEDURES & TRIGGERS (RPC)

All PostgreSQL functions are implemented with `SECURITY DEFINER` where required to bypass recursive RLS evaluations safely.

### 1. RLS Security Functions
- **`public.is_trip_member(p_trip_id uuid) -> boolean`**  
  Checks if `auth.uid()` has an approved row in `public.trip_members` or owns the trip.
- **`public.user_owns_trip(p_trip_id uuid) -> boolean`**  
  Checks if `auth.uid()` matches `public.trips.owner_id`.
- **`public.user_can_access_trip(p_trip_id uuid) -> boolean`**  
  Returns `true` if `user_owns_trip(p_trip_id)` OR `is_trip_member(p_trip_id)`.
- **`public.user_is_trip_organizer(p_trip_id uuid) -> boolean`** *(Migration 018)*  
  Checks if `auth.uid()` is the trip owner OR has an approved `organizer` role in `public.trip_members`. Prevents RLS recursion when evaluating organizer management permissions.

### 2. User & Auth Automation Functions
- **`public.handle_new_user()`** *(Trigger on `auth.users`)*  
  Automatically inserts a matching profile row in `public.users` and default row in `public.user_settings` when a new Supabase auth user registers.
- **`public.check_user_registered(p_email text) -> boolean`** *(RPC)*  
  Allows safe, pre-flight registration verification for Google Sign-In confirmation dialogs.
- **`public.set_updated_at()`** *(Trigger function)*  
  Updates the `updated_at` column to `now()` across all mutating tables (`users`, `trips`, `friends`, `expenses`, `itinerary_stops`).

### 3. Trip & Collaboration RPCs
- **`public.join_trip_by_code(p_invite_code text) -> jsonb`** *(RPC, Migration 019)*  
  Finds the trip by sanitized invite code (regex stripping hyphens/spaces), ensures caller's profile exists in `public.users` to prevent FK failures, handles re-application if previously rejected, detects already-approved and pending members returning exact status without duplicates, fans out in-app notifications (`trip_join_request`) to all organizers/owners, logs activity, and returns `{ success, trip_id, trip_name, status, already_member, already_pending }`.
- **`public.approve_member(p_trip_id uuid, p_member_uid uuid) -> jsonb`** *(RPC, Migration 017)*  
  Allows organizers/owners to approve a pending member, updates `status = 'approved'`, inserts `trip_approved` notification to the applicant, and logs activity.
- **`public.update_member_roles(p_trip_id uuid, p_member_uid uuid, p_roles text[]) -> jsonb`** *(RPC, Migration 018)*  
  Allows organizers/owners to assign and update member roles atomically. Validates roles against the enum domain, updates `public.trip_members.roles`, sends in-app `role_updated` notification to the affected member, and records an activity log entry.
- **`public.reject_or_remove_member(p_trip_id uuid, p_member_uid uuid, p_reason text) -> jsonb`** *(RPC, Migration 017)*  
  Deletes `trip_members` row, sends notification (`trip_rejected` or `member_removed`), and logs activity. Cannot be used on trip owner.
- **`public.leave_trip(p_trip_id uuid) -> jsonb`** *(RPC, Migration 017)*  
  Allows a non-owner member to leave a trip voluntarily and writes activity log.
- **`public.log_expense_activity()`** *(Trigger on `public.expenses`)*  
  Automatically logs an `expense_added` or `expense_updated` entry into `public.activity_log`.
- **`public.handle_user_offline()`** *(Presence sweep)*  
  Updates `is_online = false` and `last_seen = now()` when a user disconnects.

---

## 4. 🚫 AI HALLUCINATION BLACKLIST (PERMANENTLY DROPPED)

> [!CAUTION]
> The following tables and columns were dropped in schema cleanup migrations `012`, `014`, `015`, and `016`. **NEVER** write SQL or Dart queries referencing these fields:

| Entity | Dropped / Hallucinated Identifier | Correct Replacement / Behavior |
| :--- | :--- | :--- |
| `trips` | `destination_lat`, `destination_lng` | Dropped. Use `departure_lat/lng` or `destination_details` (jsonb). |
| `trips` | `invite_expires_at` | Dropped. Invite codes are permanent per trip. |
| `trips` | `cover_image_url`, `discord_channel_id`, `cover_color`, `cover_emoji` | Dropped. Theme color & emoji derived dynamically from `type` / `trip_type` via `AppTripTypes`. |
| `itinerary_stops` | `duration_min`, `google_place_id`, `photo_url`, `created_by` | Dropped. Use `location`, `booking_ref`, `time_start`, `time_end`. |
| `packing_items` | `quantity`, `notes`, `created_by`, `checked_by`, `checked_at` | Dropped. Use `is_checked`, `is_custom`, `assigned_to_user_id`. |
| `expenses` | `split_meta`, `rejected_by` | Dropped. Use `rejection_note`, `approved_by`. |
| `trip_messages` | `media_type`, `reply_to_id`, `is_edited`, `edited_at` | Dropped. Use `message_type`, `media_url`. |
| `user_settings` | `email_notifications`, `mpin_hash`, `mpin_salt`, `profile_visibility` | Dropped. Clean user settings model. |
| **`friendships`** | **TABLE PERMANENTLY DROPPED** | Use **`public.friends`** exclusively. |

---

## 5. 🛡️ 3-LAYER ENCRYPTION & SECURITY ENGINE

```
Client Tier               Storage Tier                Transport Tier
┌──────────────────────┐  ┌────────────────────────┐  ┌──────────────────────┐
│ Layer 1 (Asymmetric) │  │ Layer 2 (Symmetric)    │  │ Layer 3 (Transport)  │
│ RSA-2048 Public Key  │─▶│ AES-256-GCM Encrypted  │─▶│ TLS 1.3 / HTTPS      │
│ Android Keystore/iOS │  │ Payload Stored at Rest │  │ Supabase PostgREST   │
└──────────────────────┘  └────────────────────────┘  └──────────────────────┘
```

1. **`ThreeLayerEncryptionService.instance` Methods**:
   - `init()`: Generates / loads RSA keypair from `FlutterSecureStorage` (BigInt base64 encoding, zero ASN.1 dependencies).
   - `encryptData(String plaintext) -> Future<String>`: Produces JSON payload with Layer 1 RSA signature tag + Layer 2 AES-GCM IV and ciphertext.
   - `decryptData(String encryptedJson) -> Future<String>`: Unwraps and validates AES payload using private key stored in Keystore.
2. **Encrypted Fields at Rest**:
   - `users.phone`
   - `users.gcash_number`
   - `users.health_notes`
3. **Session Cold-Start Hydration**:
   - `SecureSessionRepository.instance.restoreSession()` executes in `main.dart` *before* `runApp()`.
   - On success: `DatabaseService.instance.switchUser(restoredUser.id)` pre-routes the local Sembast partition to prevent cold-start flicker.

---

## 6. 📦 CORE REPOSITORIES & SERVICES FUNCTION INDEX

### 1. `TripRepository` (`lib/core/repositories/trip_repository.dart`)
- `Future<List<TripModel>> getTrips()` — Pure remote query joining `trip_members` and `expenses`. Deduplicates by ID.
- `Future<TripModel?> getTripById(String tripId)` — Remote query for a single trip.
- `Future<void> createTrip(TripModel trip)` — Upserts user profile, inserts trip row, adds owner as organizer in `trip_members`.
- `Future<void> updateTrip(TripModel trip)` — Updates mutable trip fields in Supabase.
- `Future<void> archiveTrip(String tripId)` — Soft-deletes (`status = 'archived'`).
- `Future<void> unarchiveTrip(String tripId)` — Restores trip (`status = 'planned'`).
- `Future<void> deleteTrip(String tripId)` — Hard-deletes trip from Supabase.
- `Future<void> joinTripByCode(String code)` — Calls RPC `join_trip_by_code` with fallback direct insertion.
- `Future<String> regenerateInviteCode(String tripId)` — Generates fresh 6-char code and updates trip.
- `Future<void> updateMemberRoles(String tripId, String memberId, List<MemberRole> newRoles)` — Updates roles and logs activity.
- `Future<void> approveMember(String tripId, String memberId)` — Sets member status to `approved`.
- `Future<void> rejectMember(String tripId, String memberId)` — Deletes member row.

### 2. `AuthRepository` (`lib/core/repositories/auth_repository.dart`)
- `Future<bool> isUserRegistered(String email)` — Checks email presence via RPC `check_user_registered`.
- `Future<User?> signInWithGoogle({onConfirmNewAccount})` — Native Google Sign-In with ID token exchange and OAuth fallback.
- `Future<User?> waitForSession({timeout})` — Blocks until an async auth event fires.
- `Future<void> signOut()` — Clears Google Sign-In and Supabase auth sessions.
- `User? get currentUser` — Synchronous current user getter.
- `Stream<AuthState> get authStateChanges` — Supabase auth stream.

### 3. `ChatRepository` (`lib/core/repositories/chat_repository.dart`)
- `Future<List<ChatMessage>> getMessages(String tripId, {int limit})` — Direct PostgREST query on `trip_messages`.
- `Stream<List<ChatMessage>> messagesStream(String tripId)` — Live Supabase Realtime stream for trip chat.
- `Future<ChatMessage?> sendMessage({tripId, text, senderName})` — Direct remote insert into `trip_messages`.
- `Future<void> deleteMessage(String messageId)` — Remote delete where `id = messageId AND user_id = uid`.

### 4. `ExpenseRepository` (`lib/core/repositories/expense_repository.dart`)
- `Future<List<ExpenseModel>> getExpenses(String tripId)` — Direct Supabase query ordered by `created_at DESC`.
- `Future<void> addExpense(String tripId, ExpenseModel expense)` — Direct PostgREST insert into `expenses`.
- `Future<void> updateStatus(String expenseId, ExpenseStatus status, {note})` — Updates `status`, `rejection_note`, `approved_by` in Supabase.
- `Future<void> deleteExpense(String expenseId)` — Direct remote delete from `expenses`.

### 5. `FriendRepository` (`lib/core/repositories/friend_repository.dart`)
- `Future<List<FriendModel>> getFriends()` — Queries accepted friends with live presence (`is_online`, `last_seen`).
- `Future<List<FriendModel>> getIncomingRequests()` — Queries pending inbound friend requests with caller presence.
- `Future<List<FriendModel>> getOutgoingRequests()` — Queries pending outbound friend requests sent by the current user.
- `Future<List<FriendModel>> searchUsers(String query)` — Fuzzy search by `display_name`, `email`, or ID, cross-referencing and returning exact relationship status (`none`, `pending`, `incoming`, `accepted`).
- `Future<FriendModel?> lookupUser(String codeOrIdOrName)` — Resolves single user by exact ID, display name, or email with relationship status.
- `Future<void> sendRequest(String friendId)` — Directional upsert (`user_id = currentUserId, friend_id = friendId, status = 'pending'`).
- `Future<void> acceptRequest(String requesterId)` — Updates inbound row and upserts reciprocal row to `accepted`.
- `Future<void> rejectRequest(String friendId)` / `cancelRequest()` / `removeFriend()` — Deletes reciprocal friend rows.
- `Future<String> addFriendByCode(String codeOrId)` — Looks up user by UUID/name/email and sends/accepts request.
- `Future<Map<String, dynamic>?> getCurrentUserProfile()` — Public profile payload for QR sharing.

### 6. `ItineraryRepository` (`lib/core/repositories/itinerary_repository.dart`)
- `Future<List<ItineraryStop>> getStops(String tripId)` — Direct Supabase query ordered by `day_number`, `sort_order`.
- `Future<List<ItineraryDay>> getItinerary(String tripId, {startDate, endDate})` — Builds accurate chronological days aligned to the trip's date range (`fromDate` to `toDate`) and groups stops into day clusters.
- `Future<void> saveItineraryDay(String tripId, ItineraryDay day)` — Direct PostgREST upsert to `itinerary_stops`.
- `Future<void> deleteStop(String stopId)` — Direct delete from `itinerary_stops`.
- `Future<void> deleteStops(List<String> stopIds)` — Direct batch delete from `itinerary_stops`.
- `Future<void> deleteStopsBeyondDay(String tripId, int maxDayNumber)` — Cleans up remote orphaned stops when trip duration is shortened.

### 7. `PackingRepository` (`lib/core/repositories/packing_repository.dart`)
- `Future<List<PackingCategory>> getCategories(String tripId)` — Direct fetch from `public.packing_items` + auto default seed.
- `Future<void> toggleItem(String itemId, bool checked)` — Direct PostgREST update to `packing_items`.
- `Future<PackingItem> addItem({tripId, category, name, ...})` — Inserts item into `packing_items` (prohibits dropped `created_by` column).
- `Future<void> deleteItem(String itemId)` — Direct delete from `packing_items`.
- `Future<void> deleteCategory(String tripId, String categoryId)` — Deletes category items from `packing_items`.
- `Future<List<PackingTemplate>> getTemplates()` — Prebuilt templates + custom in-memory templates.
- `Future<void> applyTemplate({tripId, template})` — Batches template items into `packing_items`.
- `Future<void> sendPackingReminder(...)` — Dispatches in-app notification via `public.notifications`.

### 8. `ProfileRepository` (`lib/core/repositories/profile_repository.dart`)
- `Future<Map<String, dynamic>?> getRemoteProfile(String userId)` — Direct Supabase read with 3-Layer decryption.
- `Future<void> saveRemoteProfile(String userId, Map<String, dynamic> data)` — Direct Supabase upsert with 3-Layer encryption.
- `Future<String?> uploadAvatar(String userId, String localFilePath)` — Uploads image to Supabase Storage bucket `avatars` (`{userId}/profile.{ext}`) with cache-busting timestamp and returns public URL.

### 9. `PersonalAllowanceRepository` (`lib/core/repositories/personal_allowance_repository.dart`)
- `Future<PersonalAllowanceModel?> getPersonalAllowance(String tripId, String userId)` — Reads user-isolated allowance configuration and personal expenses from `trip_personal_allowances` and `personal_expenses`.
- `Future<void> savePersonalAllowance(PersonalAllowanceModel allowance)` — Upserts personal budget target, 10% emergency buffer, and cash on hand.
- `Future<void> addPersonalExpense(PersonalExpenseItem expense)` — Inserts solo private purchase into `personal_expenses` (zero group split pollution).
- `Future<void> deletePersonalExpense(String expenseId)` — Removes solo personal expense.

### 10. Core Infrastructure Services
- **`SecureSessionRepository.instance`** (`lib/core/auth/data/secure_session_repository.dart`):
  - `persistSession(Session session)`: Saves access/refresh tokens in Keystore.
  - `restoreSession()`: Recovers Supabase session using refresh token.
  - `clearSession()`: Wipes all auth tokens on logout.
- **`ThreeLayerEncryptionService.instance`** (`lib/core/security/three_layer_encryption_service.dart`):
  - `init()`: Generates/loads client RSA-2048 and AES-256-GCM keys into Keystore.
  - `encryptData(String plainText)` / `decryptData(String cipherText)`: Protects PII (`phone`, `gcash_number`, `health_notes`).
- **`UserPresenceService.instance`** (`lib/core/services/user_presence_service.dart`):
  - `start([userId])` / `stop()`: Automatic lifecycle observer (`WidgetsBindingObserver`) setting `is_online = true` / `false` and 45s heartbeat pings.
- **`LocationBroadcastService.instance`** (`lib/core/services/location_broadcast_service.dart`):
  - `startSession(...)` / `stopSession()`: Manages ephemeral Supabase Realtime broadcast channel (`trip:location:{tripId}`) for low-latency peer location streaming with zero database I/O overhead.
  - Speed-adaptive GPS sampling (Stationary 60s/25m, Walking 15s/10m, Driving 5s/30m) with battery saver mode.
  - Privacy modes: `exact`, `approximate` (~500m fuzzy bubble), `ghost` (broadcast suppression with duration timers).
  - Priority SOS panic beacon broadcasting (`broadcastSos`) and periodic PostGIS checkpointing.
- **`ModuleViewTrackerService.instance`** (`lib/core/services/module_view_tracker_service.dart`):
  - Keystore-backed timestamp tracker (`FlutterSecureStorage` with in-memory sync cache) recording `last_viewed:{module}:{tripId}` for client-side unread/change diffing.
  - Methods: `initialize()`, `getLastViewed(module, tripId)`, `markViewed(module, tripId)`, `clearTrip(tripId)`.
- **`SupaService.instance`** (`lib/core/services/supa_service.dart`):
  - Low-level direct table operations, device token registration, and presence pings.

---

## 7. 🔄 RIVERPOD PROVIDERS & STATE INDEX

| Provider Name | Type | Scope / Responsibility |
| :--- | :--- | :--- |
| `authNotifierProvider` | `StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>` | MVI Auth state machine (`Unauthenticated`, `Authenticating`, `Authenticated`, `AuthError`). |
| `tripProvider` | `StateNotifierProvider<TripNotifier, AsyncValue<List<TripModel>>>` | Global list of user trips, add/edit/archive/delete/join actions. |
| `selectedTripProvider` | `StateProvider<TripModel?>` | Active trip context across Detail, Itinerary, Budget, Packing, Chat. |
| `tripQuickActionChangesProvider(trip)` | `FutureProvider.family<TripQuickActionChanges, TripModel>` | Computes contextual Red Notification Dot indicators (`🔴`) for trip quick action buttons (Itinerary, Packing, Members, Expenses, Chat) by comparing remote timestamps against Keystore `ModuleViewTrackerService` with self-action exemption. |
| `activeTripProvider` | `FutureProvider<TripModel?>` | Returns the first non-draft, non-archived trip (or selected trip if unarchived); returns `null` when only archived trips exist. |
| `profileProvider` | `StateNotifierProvider<ProfileNotifier, ProfileState>` | User profile state, surname privacy toggle, encrypted data sync, `isAccountFullySet` onboarding guard & auto-recovery. |
| `chatNotifierProvider(tripId)`| `StateNotifierProvider<ChatNotifier, ChatState>` | Live chat messages, presence typing indicators, optimistic send. |
| `itineraryNotifierProvider(tripId)` | `StateNotifierProvider<ItineraryNotifier, AsyncValue<List<ItineraryDay>>>` | Multi-day stops, voting counters, drag-and-drop ordering. |
| `packingNotifierProvider(tripId)` | `StateNotifierProvider<PackingNotifier, PackingState>` | Categorized packing list, progress percentage, member assignment. |
| `expenseNotifierProvider(tripId)` | `StateNotifierProvider<ExpenseNotifier, ExpenseState>` | Group expenses, category breakdown, GCash settlement calculator. |
| `friendsProvider` | `FutureProvider<List<FriendModel>>` | List of accepted friends with presence status. |
| `incomingRequestsProvider` | `FutureProvider<List<FriendModel>>` | Inbound friend requests directed to the current user. |
| `outgoingRequestsProvider` | `FutureProvider<List<FriendModel>>` | Outbound friend requests sent by the current user. |
| `friendRequestsCountProvider` | `Provider<int>` | Badge counter for pending incoming requests. |
| `searchUsersProvider(query)` | `FutureProvider.family<List<FriendModel>, String>` | Fuzzy user search with annotated relationship states (`none`, `pending`, `incoming`, `accepted`). |
| `lookupUserProvider(query)` | `FutureProvider.family<FriendModel?, String>` | Live user resolution by ID/name/email with relationship preview. |
| `friendsRealtimePresenceProvider` | `StreamProvider.autoDispose<void>` | Supabase Realtime subscription on `public.users` and `public.friends`, auto-invalidates friends/requests providers on changes + 30s periodic refresh. |
| `onlineFriendsProvider` | `Provider<List<FriendModel>>` | Derived list of currently online friends (`isCurrentlyOnline == true`). |
| `onlineFriendsCountProvider` | `Provider<int>` | Count of currently online friends. |
| `navigationProvider` | `NotifierProvider<NavigationNotifier, NavigationState>` | Live group navigation state, telemetry streaming, member-as-waypoint routing, convoy separation alarms, SOS beacons, and privacy modes. |
| `realtimeNotifierProvider(tripId)`| `StateNotifierProvider<RealtimeNotifier, RealtimeState>` | Live GPS member location tracking, stop voting broadcasts. |
| `exploreProvider` | `FutureProvider<List<DestinationModel>>` | Destination catalog with search, tags, and rating filters. |

---

## 8. 🚀 IMPLEMENTED PLANS & FEATURE WORKFLOWS

### 1. Create Trip Flow (`lib/features/create_trip/`)
- **Step 1 (Basics)**: Trip Name, Destination search, Date range selection (`fromDate` to `toDate`).
- **Step 2 (Transport & Logistics)**: Tri-modal land transport selection (`private`, `commute`, `rental`; strictly no sea or plane) + `transport_meta` JSON serialization.
- **Step 3 (Budget & Splitting)**: Total budget allocation, currency selection, split method (`equal` vs `fixed`).
- **Step 4 (Cover & Customization)**: Palette selection (`cover_color`), emoji badge (`cover_emoji`), departure point GPS lookup.
- **Completion**: Generates 6-character alphanumeric `invite_code`, writes to Supabase, assigns organizer role, navigates to `/trip-detail`.

### 2. Real-Time Collaboration & Live Presence
- **Supabase Realtime Broadcast Channels**: Subscribes to `trip:<trip_id>` for instant updates.
- **Live Member GPS Tracking**: Broadcasts `latitude`/`longitude` to `member_locations` table and renders live avatars on `google_maps_flutter`.
- **Privacy Pause**: `is_location_sharing_paused` allows individual travelers to pause tracking at will.

### 3. Collaborative Itinerary Builder & Stop Voting
- Multi-day clustering (`ItineraryDay`) with sequential time slots (`time_start` -> `time_end`).
- Up/Down voting via `stop_votes` table for group consensus.
- Category coloring: Blue (Hotel), Green (Activity), Amber (Food), Coral (Transport), Purple (Custom).

### 4. Group Expenses & GCash Settlement Engine
- Category tagging: Hotel, Food, Activities, Transport, Custom.
- Split calculator computing debt graph minimization between payers and members.
- GCash QR upload (`gcash_qr_url`) and mobile number display for one-tap payments.
- Approval workflow: Organizers approve/reject reimbursement requests.

### 5. Social Graph & QR Friend Invites
- Reciprocal friendship model in `public.friends`.
- Instant friend request generation via QR code scanning or 6-char user code.
- Online presence sync (`is_online`, `last_seen`) displayed on friend avatars.

### 6. Offline-First Resilience Engine
- Network detection via `ConnectivityService`.
- Sembast-backed `OfflineSyncQueue` for offline writes (create stop, check packing item, log expense).
- `SyncManager` auto-flushes queued transactions in FIFO order upon network reconnection.
- Global `OfflineBanner` widget indicating active offline mode.

### 7. Live Navigation & Realtime Convoy Radar
- **Mapbox & OpenStreetMap HD Tile Engine**: Rendered via `flutter_map` with `MapTileConfig` (Mapbox Streets v12 via `MAPBOX_ACCESS_TOKEN` with CartoDB Voyager fallback) and interactive camera controls (Center My GPS, Fit Group Bounds, Zoom +/-).
- **Zero-Disk Broadcast Streaming**: Ephemeral sub-150ms WebSocket telemetry streaming via `trip:location:{trip_id}` channels in `LocationBroadcastService`.
- **Database Telemetry & Hydration**: Initial member location hydration from Supabase `member_locations` table and 45s PostGIS checkpointing (`update_member_location` RPC).
- **Dynamic Member Roster**: Dynamic sync with `activeTrip.members` respecting `hideSurname` privacy rules.
- **Member-as-Waypoint & Meet Halfway**: Dynamic in-app routing to separated companions, midpoint rendezvous calculation, and external GPS app deep linking (Google Maps/Apple Maps/Waze).
- **Convoy & SOS Intelligence**: Automated convoy separation alarm (>2.0 km) and emergency SOS panic beacon broadcast.

### 8. Real-Time Weather & Live Severe Advisory Engine (IDEA-013)
- **Dual-Source Meteorological Engine**:
  - **Open-Meteo High-Resolution Forecasts**: Up to 16-day daily horizons, ECMWF/GFS weather models, precipitation probability (`%`), UV index, high/low temperatures, and WMO code mapping.
  - **OpenWeatherMap Real-Time Telemetry**: Station telemetry fallback with configured `OPENWEATHERMAP_API_KEY`.
- **Philippine Travel Hub Resolution**: $O(1)$ coordinate lookup for top destination centers (Boracay, El Nido, Siargao, Baguio, Cebu, Coron, Bohol, Batanes, etc.) with automatic Open-Meteo geocoding fallback.
- **Local In-Memory Cache (3-Hour TTL)**: Minimizes network roundtrips and provides seamless offline fallback when travelers are in remote island/mountain regions.
- **Riverpod Architecture**: `weatherServiceProvider`, `tripWeatherProvider(tripId)` (forecast array), and `tripCurrentWeatherProvider(tripId)` (live telemetry).

---

## 9. 🎨 BRAND IDENTITY & DESIGN INVARIANTS

| Color Name | Hex Code | Flutter Value | Purpose |
| :--- | :--- | :--- | :--- |
| **Coral** | `#D85A30` | `const Color(0xFFD85A30)` | Primary Brand, Active CTAs, Highlights |
| **Light Coral** | `#F0997B` | `const Color(0xFFF0997B)` | Secondary Accents, Badges, Borders |
| **Sand** | `#FAECE7` | `const Color(0xFFFAECE7)` | Background Tints, Secondary Buttons |
| **Sunset** | `#EF9F27` | `const Color(0xFFEF9F27)` | Accent Warnings, Amber Statuses, Food Stops |
| **Deep Earth** | `#2C1A14` | `const Color(0xFF2C1A14)` | Primary Typography, High Contrast Dark |
| **Warm White** | `#F7F4F0` | `const Color(0xFFF7F4F0)` | Surface Canvas, Cards, Dialogs |

### Typography Tokens
- **Display & Headlines (`font-heading`)**: `Playfair Display` (Bold / SemiBold) with `Georgia` / `serif` fallback
- **Taglines & Accents**: `Playfair Display` (Italic) with `Georgia` / `serif` fallback
- **UI Labels & Body (`font-body`)**: `DM Sans` (Medium / Regular)
- **Direct Inline Serif Fallback**: `Georgia` (used on splash "Tara TRAVEL" branding and Home greeting name)
- **Centralized Reference**: `AppTextStyles` (`fontHeading`, `fontBody`, `fontSerifFallback`, `headline1`-`3`, `tagline`, `bodyLarge`-`Small`)

### Name Privacy Invariant
- Every user-facing name display MUST invoke `MemberModel.formatDisplayName(name, hideSurname: profile.hideSurname)`.
- When `hideSurname` is `true`: `"Juan Dela Cruz"` -> `"Juan D."`.

---

## 11. 🔄 END-TO-END SYSTEM ARCHITECTURAL FLOWS

### 1. App Bootstrapping & Cold-Start Session Hydration Flow

```
[ App Launch ]
      │
      ▼
1. WidgetsFlutterBinding.ensureInitialized()
   SystemChrome.setEnabledSystemUIMode(edgeToEdge)
      │
      ▼
2. dotenv.load('.env') ──▶ Load Supabase URLs & Client IDs
      │
      ▼
3. Supabase.initialize(url, anonKey)
      │
      ▼
4. SecureSessionRepository.instance.restoreSession()
   ├── Recover refresh token from Android Keystore / iOS Keychain
   ├── Supabase.auth.recoverSession(refreshToken)
   └── Returns Restored User OR null (expired / missing)
      │
      ▼
5. DatabaseService.instance.switchUser(restoredUser.id)
   └── Mounts isolated local Sembast store: `tara_travel_<user_id>.db`
      │
      ▼
6. ThreeLayerEncryptionService.instance.init()
   └── Loads RSA-2048 keypair from Keystore into memory cache
      │
      ▼
7. runApp(ProviderScope(child: TaraApp()))
      │
      ▼
8. AuthGate Route Decision:
   ├── Restored User != null && hasCompletedOnboarding ──▶ '/home'
   ├── Restored User != null && !hasCompletedOnboarding ──▶ '/onboarding'
   └── Restored User == null ──▶ '/' (SplashScreen)
```

---

### 2. Authentication & Onboarding Lifecycle Flow

```
[ User on SplashScreen / Onboarding ]
      │
      ▼
1. User taps "Continue with Google"
      │
      ▼
2. AuthRepository.signInWithGoogle()
   ├── Native GoogleSignIn.signIn() -> GoogleAuth (idToken + accessToken)
   ├── RPC `check_user_registered(email)`
   │   ├── New User: Trigger confirmation modal (if configured)
   │   └── Existing User: Proceed directly
   └── Supabase.auth.signInWithIdToken(provider: google, idToken: ...)
      │
      ▼
3. PostgreSQL Trigger `handle_new_user()` executes on Supabase:
   ├── Inserts row into `public.users` (email, full_name, avatar_url)
   └── Inserts default row into `public.user_settings`
      │
      ▼
4. AuthGate intercepts `AuthChangeEvent.signedIn`:
   ├── DatabaseService.instance.switchUser(user.id)
   ├── ProfileRepository.getRemoteProfile(user.id) (decrypts sensitive fields)
   └── Route to '/onboarding' (Step 0: Mode Selection -> Step 1: Privacy -> Step 2: Location)
      │
      ▼
5. ProfileCompletion:
   ├── Saves profile tags: `onboarding:completed`, `privacy:hide_surname`
   └── Navigator.pushReplacementNamed('/home')
```

---

### 3. Trip Creation & Member Join Flow

```
[ Trip Creation Flow ]
      │
      ▼
1. CreateTripFlow (4-Step Wizard):
   ├── Step 1: Name, Destination, Dates (fromDate, toDate)
   ├── Step 2: Transport Mode + Transport Details JSON
   ├── Step 3: Total Budget, Split Method (equal/fixed)
   └── Step 4: Cover Palette, Cover Emoji, Departure Point GPS
      │
      ▼
2. TripRepository.createTrip(TripModel):
   ├── Generates 6-character alphanumeric `invite_code`
   ├── `public.trips` INSERT payload
   └── `public.trip_members` INSERT (user_id = ownerId, roles = ['organizer'], status = 'approved')
      │
      ▼
3. Guest Member Join:
   ├── Guest enters invite code on '/trips' or via deep-link
   ├── Calls RPC `public.join_trip_by_code(p_invite_code)`
   │   ├── Validates code against `public.trips`
   │   ├── Inserts guest into `public.trip_members` (roles = ['member'], status = 'approved')
   │   └── Inserts entry into `public.activity_log`
   └── Realtime broadcast updates member roster across all devices
```

---

### 4. Real-Time Collaboration & Map Tracking Flow

```
[ Active Trip Workspace ]
      │
      ▼
1. Trip Screen Loaded ('/trip-detail', '/itinerary', '/navigation', '/chat')
      │
      ▼
2. RealtimeNotifier connects to Supabase Realtime Channel:
   └── Channel: `realtime:trip:<trip_id>`
      │
      ├───▶ GPS Live Presence:
      │     ├── Device captures coordinates (geolocator / location)
      │     ├── Checks `is_location_sharing_paused` (Privacy toggle)
      │     ├── Upserts `public.member_locations` (trip_id, user_id, lat, lng)
      │     └── Broadcasts location payload to all connected members on Map
      │
      ├───▶ Live Chat Flow:
      │     ├── User types text -> Optimistic local write to Sembast `chat_messages`
      │     ├── `public.trip_messages` INSERT
      │     └── Supabase Realtime Stream emits new message to all trip members
      │
      └───▶ Stop Voting Broadcast:
            ├── Member casts vote (up / down)
            ├── Upserts `public.stop_votes` (stop_id, user_id, vote)
            └── Realtime vote count badge updates instantly
```

---

### 5. Expense Tracking & GCash Debt Settlement Flow

```
[ Expense Logging & Split Flow ]
      │
      ▼
1. Member logs expense in '/budget':
   ├── ExpenseModel (description, amount, category, paid_by_user_id, receipt_url)
   └── Inserts into `public.expenses` with `status = 'pending'`
      │
      ▼
2. Organizer Review:
   ├── Organizer receives notification / views pending expenses
   └── Calls `updateStatus(expenseId, ExpenseStatus.approved / rejected)`
      │
      ▼
3. Debt Minimization & Balance Calculation:
   ├── `ExpenseNotifier` aggregates all approved expenses
   ├── Computes total trip spend, per-person share, and net debtor/creditor balances
   └── Renders individual settlement action cards
      │
      ▼
4. GCash Payment Execution:
   ├── Debtor opens Payee's settlement card (displays GCash number & QR code)
   ├── Payment made via GCash -> Debtor uploads receipt screenshot to Supabase Storage
   ├── Inserts row into `public.settlements` (payer_id, payee_id, amount, proof_photo_url)
   └── Payee verifies and toggles `is_settled = true`
```

---

### 6. Offline-First Resilience & Sync Queue Engine Flow

```
[ Network Interruption State ]
      │
      ▼
1. ConnectivityService detects loss of internet:
   └── Broadcasts `ConnectivityResult.none` -> Global `OfflineBanner` appears
      │
      ▼
2. User Performs Mutations Offline (Create Stop, Toggle Packing Item, Add Expense):
   ├── Read operations served instantly from Sembast user partition
   ├── Local state updated optimistically for zero UI latency
   └── Mutation enqueued in Sembast `offline_queue` via `OfflineSyncQueue.instance.enqueue()`
      │
      ▼
3. Network Connectivity Restored:
   ├── `ConnectivityService` detects `wifi` or `mobile`
   ├── `SyncManager` triggered automatically
   │   ├── Reads all queued `SyncOperation` records in FIFO order
   │   ├── Replays HTTP/PostgREST mutation against Supabase with retry backoff
   │   └── On success: Removes operation from `offline_queue`
   └── In-memory Riverpod providers refreshed (`ref.invalidate()`)
```

---

### 7. Secure Sign-Out & Clean State Disposal Flow

```
[ User Initiates Sign-Out ]
      │
      ▼
1. AuthGate / AuthNotifier.signOut():
   ├── 1. `AuditLogger.instance.flush()`: Flushes pending audit events to disk
   ├── 2. `Supabase.instance.client.auth.signOut()`: Revokes remote JWT session
   ├── 3. `GoogleSignIn.signOut()`: Clears native Google account cache
   ├── 4. `SecureSessionRepository.instance.clearSession()`:
   │      └── Deletes access token, refresh token, expiry, and user ID from Keystore
   ├── 5. `DatabaseService.instance.switchUser('default')`:
   │      └── Closes user DB file and unbinds user partition
   ├── 6. Invalidate Riverpod Stores:
   │      └── `ref.invalidate(profileProvider)`, `ref.invalidate(tripProvider)`, etc.
   └── 7. Navigator routes to '/' (SplashScreen / Landing)
```

---

## 12. 🗺️ SCREEN & ROUTE REGISTRY

```dart
'/'              -> SplashScreen (Cold-start session restore)
'/onboarding'    -> OnboardingScreen (Profile setup, privacy & mode selection)
'/home'          -> HomeScreen (Trip overview, active travel card, quick actions)
'/create-trip'   -> CreateTripFlow (4-step trip wizard)
'/notifications' -> NotificationsScreen (Push & system notification center)
'/budget'        -> BudgetScreen (Expense log, split calculator, GCash payments)
'/itinerary'     -> ItineraryScreen (Daily schedule, stops, map route, voting)
'/navigation'    -> NavigationScreen (Live GPS tracking, turn-by-turn map)
'/packing'       -> PackingScreen (Collaborative checklist, category progress)
'/members'       -> MembersScreen (Roster, role management, friend invite modal)
'/explore'       -> ExploreScreen (Destination catalog, travel guides)
'/profile'       -> ProfileScreen (3-Layer encrypted user settings, GCash QR)
'/trip-detail'   -> TripDetailScreen (Trip dashboard, actions, member status)
'/activity'      -> ActivityLogScreen (Audit trail of trip modifications)
'/chat'          -> ChatScreen (Realtime group chat & media sharing)
'/trips'         -> TripsScreen (All planned, ongoing, and archived trips)
'/friends'       -> FriendsScreen (Social graph, pending requests, search)
```

---

## 13. 🗓️ ITINERARY POWER SUITE ARCHITECTURE

- **Date Range Alignment**: `ItineraryRepository.getItinerary` computes `Day 1` ... `Day N` based strictly on `trip.fromDate` to `trip.toDate`.
- **Transit & Conflict Engine**:
  - `TransitConflictHelper`: Computes Haversine geodesic distance, estimated travel time by speed profile, and detects schedule collisions (start before previous end) or tight buffers (< 15 mins).
  - `InterStopTransitBadge`: Displays inter-stop transit duration, distance, and collision/tight buffer warning badges.
- **Cost-to-Expense Handoff**:
  - 1-tap conversion from `StopDetailSheet` pre-populating `AddExpenseForm` (description, cost, category, date).
- **Group Presence & Companion Arrival Hub**:
  - `StopDetailSheet` houses the consolidated "Members" arrival hub with inline interactive roster and batch "Mark Everyone as Arrived" (`RollCallSheet` retired).
- **Day Management**:
  - `shiftDaySchedule(dayIndex, minutesOffset)`: Adjusts all start/end times forward or backward by 30m or 60m.
  - `duplicateDay(dayIndex)`: Clones day and all stops into a new appended itinerary day.
  - `moveStopToDay(fromDay, toDay, stopId)`: Translocates a stop across different itinerary days.
  - `deleteDay(dayIndex)`: Removes day and re-indexes remaining days.

---

---

## 14. 🎨 STANDARDIZED FEEDBACK SYSTEM (IDEA-001 / IMP-060)

- **Location**: `lib/core/widgets/feedback/`
- **Core Components**:
  - `FeedbackType`: Semantic intent enum (`success`, `info`, `warning`, `error`, `destructive`) mapping to brand colors (`#FAECE7`, `#EAF3DE`, `#FFF8ED`, `#FEE2E2`) and iconography.
  - `AppFeedback`: Centralized floating snackbars/toasts (`showSuccess`, `showError`, `showWarning`, `showInfo`) featuring 14px border radius, haptic feedback, and custom action callbacks.
  - `AppDialog`: Centralized modal alerts & confirmation dialogs (`showConfirmation`, `showDestructive`, `showAlert`) featuring `Playfair Display` titles, `DM Sans` body text, 24px border radius, and async confirmation handlers.
  - `AppBanner`: Contextual inline notification banner with status icons, custom backgrounds, and dismissibility.
- **Architectural Invariant**:
  - Direct calls to `ScaffoldMessenger.of(context).showSnackBar` and raw unstyled `AlertDialog` are strictly forbidden. All feedback must use `AppFeedback` or `AppDialog`.

---

## 15. 🧭 STREAMLINED ITINERARY SUITE & PROGRESSIVE DISCLOSURE (IDEA-002 / IMP-061)

- **Location**: `lib/features/itinerary/`
- **Core Architecture & Components**:
  - `DayInsightsHeader` (`lib/features/itinerary/widgets/day_insights_header.dart`): Collapsible accordion card consolidating day weather (`DayForecast`), budget burn rate (`DayBudgetBar`), progress ring, and squad presence (`ItineraryFulfillmentBanner`).
  - `ItineraryActionSheet` (`lib/features/itinerary/widgets/itinerary_action_sheet.dart`): Unified bottom sheet consolidating secondary actions (Share, Calendar Export via `Add2Calendar`, Day Map View, Schedule Shifting, Stop Reassignment across days, Duplicate Day, Clear Stops, Delete Day).
  - `ItineraryBottomDock` (`lib/features/itinerary/widgets/itinerary_bottom_dock.dart`): Floating bottom action bar providing 1-tap route navigation & map overview and primary `+ Add Stop` button.
  - `StopDetailSheet` (`lib/features/itinerary/widgets/stop_detail_sheet.dart`): Modular detail sheet with photo gallery, 1-tap Google Maps directions, expense conversion, companion arrival roster, and group voting.
  - `ItineraryMapSheet` (`lib/features/itinerary/widgets/itinerary_map_sheet.dart`): Modular map bottom sheet with live companion rider presence chips, interactive map, and multi-stop route directions.
  - `SmartSuggestionChips` (`lib/features/itinerary/widgets/smart_suggestion_chips.dart`): Collapsible quick add template drawer.
  - **Automated GPS Arrival Geofencing**:
    - Connected to `LocationTrackingService.instance.snapshotStream`.
    - Automatically checks proximity against active day's uncompleted stops with coordinates.
    - Triggers floating `ArrivalPill` when user is within $150\text{m}$ geofence, with session dismiss cooldown tracking (`_dismissedStopIds`).

---

## 16. 🎴 ULTRA-SIMPLIFIED STOP CARDS & UNIFIED PRESENCE HUB (IDEA-007 / IMP-068)

- **Location**: `lib/features/itinerary/widgets/`
- **Core Architectural Invariants**:
  - **Ultra-Clean `StopCard`**: Reduced to pure essential metadata (Time, Title, Location, Type chip, Cost, Reference ID, and read-only checked-in member avatar preview). Single prominent CTA: `[ 🧭 Navigate ]`. Multi-button action rows (Check-in, Roll call, Expense) completely removed from the card face.
  - **Top-Right Sheet Controls**: `StopDetailSheet` places the `[ ✏️ Edit ]` button and dismiss `[ ✕ ]` in the top-right header for clean administrative separation.
  - **Canonical "Mark as Arrived" Hero CTA**: Replaces confusing multi-button check-ins with a 1-tap self-check-in hero button (`[ 📍 Mark as Arrived (You) ]` / `[ ✓ You Arrived at ... · Tap to Undo ]`).
  - **Unified "Members" Arrival Hub**: Completely retires "Roll Call" terminology. `StopDetailSheet` includes an interactive expandable "Members (X/Y Arrived)" hub with per-companion status badges, 1-tap arrival toggles, and batch "Mark Everyone as Arrived" for organizers.
  - **`RollCallSheet` Deprecation**: `RollCallSheet` is permanently deleted; its presence logic is fully unified inside `StopDetailSheet`.

---

## 17. 🗑️ RETIREMENT OF STOP VOTES & LEGACY STATUS LIFECYCLE (IMP-069)

- **Database / Backend**:
  - `public.stop_votes` table permanently dropped via Migration 021 (`021_drop_stop_votes_and_stop_status.sql`).
  - `status` column dropped from `public.itinerary_stops` table.
  - Realtime publication `stop_votes` and `stopVotesRealtimeProvider` removed.
- **Client Architecture**:
  - `StopStatus` enum and all related mappers (`_fromDbStatus`, `_toDbStatus`) deleted.
  - `votes` map and `voteScore` removed from `ItineraryStop` model.
  - `Group Vote` section and `Approve / Mark Done` status action rows removed from `StopDetailSheet`.
  - Canonical stop completion and arrival is exclusively tracked via `visitedAt` timestamp and `checkedInMemberIds`.

---

## 18. 🚘 DRIVER-READY SLIDE TO CONFIRM ARRIVAL & FULL SUPABASE PERSISTENCE (IMP-070)

- **Location**: `lib/features/itinerary/widgets/`, `lib/core/models/itinerary_model.dart`, `lib/core/repositories/itinerary_repository.dart`
- **Database & Persistence**:
  - `visited_at` (`timestamptz`): Tracks stop-level arrival timestamp in `public.itinerary_stops` (Migration 022).
  - `checked_in_data` (`jsonb`): Stores a map of `{ [userId]: ISO8601_Timestamp }` for per-member arrival tracking.
  - `ItineraryRepository.saveItineraryDay()` encodes and synchronizes both `visited_at` and `checked_in_data` to Supabase on every arrival or undo toggle.
- **Core Components & UX**:
  - `SlideToArriveButton` (`lib/features/itinerary/widgets/slide_to_arrive_button.dart`): High-contrast, tactile horizontal slider requiring a $\ge 75\%$ swipe gesture to confirm stop arrival, preventing accidental bumpy-road or pocket taps while driving.
  - **Haptic & Spring Physics**: Features `HapticFeedback.selectionClick()` on drag start, progressive color fill track, and `HapticFeedback.heavyImpact()` on confirmation trigger, with smooth spring reset animation if released early.
  - **Fixed Bottom Dock**: Positioned persistently at the bottom of `StopDetailSheet` above the safe area for immediate 1-tap/swipe driver access.
  - **Arrived Confirmation Bar & Undo**: Displays an emerald green status banner with the user's arrival timestamp and a high-visibility `[ Undo ]` button that clears the arrival timestamp in Supabase and resets state.
  - **Floating Post-Arrival Undo Banner**: Upon sliding to arrive and auto-navigating back to the main itinerary list, a floating branded banner (`AppFeedback.show`) remains visible for 6 seconds with an instant `[ Undo ]` action button, giving travelers immediate opportunity to reverse accidental check-ins without having to re-open the detail sheet.
  - **Per-Member Arrival Timestamps**: Companion roster displays individual arrival times (e.g. `✓ Arrived 3:42 PM`) beside each member.

---

## 19. 🏎️ DRIVER-READY ITINERARY TOUCH TARGETS & ENRICHED BUTTONS (IMP-073)

- **Location**: `lib/features/itinerary/widgets/`
- **Core Ergonomic & Driver UX Invariants**:
  - **`StopCard` Navigate CTA**: Upgraded from subtle low-contrast `10x5` pill to prominent, high-contrast solid primary button (`14x8` padding, size 16 icon, font 12.5 bold) with soft shadow and `HapticFeedback.lightImpact()`.
  - **`StopDetailSheet` Action Buttons**:
    - **`Navigate Maps` Button**: Height `54`, size 22 icon, 14.5 bold typography with elevated primary gradient.
    - **`Expense` Button**: Height `54`, size 19 icon, 13.5 bold typography.
    - **Top-Right `Edit` Action**: Roomy `14x9` pill target with size 15 icon and 13 bold text.
    - **`SlideToArriveButton`**: Height scaled to `60` with 52px sliding knob and size 24 vehicle icon.
    - **Arrived Status Bar**: Height `62` with 36px circular badge and `14x8` Undo button.
    - **Companion Roster Toggles**: Individual member `Mark Arrived` / `Undo` buttons scaled to `13x8` with size 15 icons and 12 bold text; batch `Mark Everyone as Arrived` button scaled to height `48`.
  - **`NavigateRouteButton` & Route Preview Modal**:
    - Multi-stop navigation button height scaled to `58` with size 24 icon and 14.5 bold text; tune options hit target $\ge 44\times 44\text{px}$.
    - "Open in Google Maps" and "Copy Link" buttons scaled to height `54`.
    - Travel mode and scope choice chips enlarged with `14x10` padding.
  - **`ItineraryBottomDock`**:
    - Border radius `26`, vertical padding `13` on `Live Nav`, `Day Map`, and `Stop` action buttons for seamless one-handed thumb reachability on dashboard mounts.
  - **`DayStrip` & `ArrivalPill`**:
    - DayStrip height `78` with `18x10` tab padding and bold labels.
    - ArrivalPill check-in action enlarged to `14x10` with size 20 icon and 11 bold text.

---

## 20. 🔙 BRAND-ALIGNED BACK BUTTON DESIGN INVARIANT (IMP-077)

- **Location**: `lib/core/widgets/buttons/app_back_button.dart`
- **Design Tokens**:
  - **Border Radius**: Strictly $12\text{px}$ in accordance with the brand-identity button specifications (`BorderRadius.circular(12)`).
  - **Touch Target**: $40\times 40\text{px}$ minimum (with custom `size` and `iconSize` parameters).
  - **Tactile Feedback**: Wrapped in `Semantics(button: true, label: 'Back')` and `Material` + `InkWell` for native ripple and high responsiveness.
- **Variant Archetypes (`AppBackButtonVariant`)**:
  1. **`glass`**: Frosted backdrop filter (`sigma: 8`), 12% white opacity fill, 18% white border, white icon. Used for dark hero gradients (`TripDetailScreen`, `MembersScreen`, `ItineraryScreen`, `PackingScreen`, `ActivityLogScreen`, `LiveNavigationScreen` [dark]).
  2. **`light`**: Crisp white fill with 1px `AppColors.cardBorder` and ambient shadow. Used for light pages (`FriendsScreen`, `NotificationsScreen`, `LiveNavigationScreen` [light], and `MapPinPickerModal`).
  3. **`brand`**: Warm Sand (`#FAECE7`) fill with light coral border and primary coral icon (`#D85A30`). Used for brand step flows (`BudgetStep`).
  4. **`ghost`**: Transparent fill with subtle coral border.

---

## 21. 📱 MOBILE RESPONSIVENESS & OVERFLOW PREVENTION INVARIANTS (IMP-079)

- **Ground Truth Standard**: All Tara Travel screens, dialogs, and modal bottom sheets must adapt seamlessly to any mobile viewport dimension (from compact 320px–360px displays up to large devices and tablets) with zero layout overflow errors (`RenderFlex` exceptions).
- **Core Guardrails (Detailed in [SOFTWARE_DESIGN_PATTERNS.md](file:///d:/Spencer/Downloads/tara_travel/docs/SOFTWARE_DESIGN_PATTERNS.md))**:
  1. **Scrollable Viewports**: Always wrap vertical or variable-length layouts in `SingleChildScrollView`, `ListView`, or `CustomScrollView` with keyboard insets awareness (`Scaffold.resizeToAvoidBottomInset: true`).
  2. **Bounded Row/Column Constraints**: In horizontal `Row` widgets, all dynamic text and flexible contents must be bounded via `Expanded` or `Flexible` with `TextOverflow.ellipsis`.
  3. **Safe Dynamic Typography**: Apply `maxLines` and `overflow: TextOverflow.ellipsis` on single-line and bounded text elements. Wrap critical action button texts in `FittedBox` or allow multi-line text wrapping.
  4. **Dynamic Wrapping**: Dynamic chip lists, tags, and badge collections must utilize `Wrap` with `spacing` and `runSpacing` instead of fixed `Row` layouts.
  5. **Hardware Cutout & Notch Safe Zones**: Always enclose top-level view content in `SafeArea` or consume `MediaQuery.paddingOf(context)` / `viewInsets`. All bottom sheets must set `isScrollControlled: true` and enforce internal scroll bounds.

---

## 22. 🧩 COMPONENT REUSE & ANTI-DUPLICATION INVARIANTS (IMP-079)

- **Ground Truth Standard**: Always audit and compose canonical shared widgets in `lib/core/widgets/` rather than creating redundant, hardcoded one-off widgets.
- **Canonical Components Catalog**:
  - **Back Navigation**: [`AppBackButton`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/buttons/app_back_button.dart) (`glass`, `light`, `brand`, `ghost`).
  - **Alerts & Dialogs**: [`AppDialog`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_dialog.dart), [`AppFeedback`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_feedback.dart), [`AppBanner`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_banner.dart).
  - **Form Controls**: [`AppTextField`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/app_text_field.dart), [`AppNumericField`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/app_numeric_field.dart), [`AppDropdown`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/app_dropdown.dart), [`TaraDateRangePicker`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/tara_date_range_picker.dart), [`LocationPicker`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/location_picker.dart).
  - **Loading & Skeleton**: [`ShimmerLoading`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/shimmer_loading.dart).
  - **Pickers & Carousels**: [`TripTypeCarousel`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/trip_color_carousel.dart), [`MultiMemberPickerSheet`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/multi_member_picker_sheet.dart).
- **Zero Inline Hardcoding**: All colors, fonts, and borders must strictly resolve through [`AppColors`](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_colors.dart) and [`AppTextStyles`](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_text_styles.dart).

---

## 23. 💬 TRIP CHAT, POLLS & RICH DECISION EMBEDS (IMP-078, IMP-083–087)

- **Database Tables**:
  - `public.trip_polls`: id, trip_id, creator_id, question, category, options (jsonb), is_closed, allow_multiple, winner_option_id.
  - `public.trip_poll_votes`: id, poll_id, user_id, option_id, created_at.
  - `public.trip_messages`: Extended with `message_type` (`text`, `poll`, `announcement`, `quick_travel`, `itinerary_snippet`, `expense_request`, `packing_alert`, `location_drop`, `media`, `tara_bot`), `poll_id`, `is_pinned`, `metadata` (jsonb), `reactions` (jsonb).
- **Winning Option Resolution Invariants**:
  - When the trip organizer taps "Add to Itinerary" or "Add to Expenses" to resolve a group poll, the system converts the option into an `ItineraryStop` or `ExpenseModel` and broadcasts a rich card message (`sendRichCard`) rather than plain text.
  - Payloads carry `is_poll_winner: true`, `poll_question`, `winner_votes`, and `total_votes`.
  - Embed cards (`ItineraryStopEmbed`, `ExpenseRequestEmbed`) render with distinct trophy badges and are tap-to-open to display full detail modal sheets with direct route navigation (`/itinerary`, `/budget`) and map integration.
- **Deep Linking & Itinerary Scroll Focus (IMP-087)**:
  - `ItineraryScreen` accepts `targetStopId` and `targetDayNumber` (via constructor or `ModalRoute.of(context)?.settings.arguments`).
  - When present, `ItineraryScreen` checks if `targetDayNumber` matches the active day. If not, it programmatically switches the active day tab (`notifier.setActiveDay`).
  - A registered map of `GlobalKey` widgets (`_stopKeys`) tracks stop items. A post-frame `Scrollable.ensureVisible` triggers with `Curves.easeOutCubic` and `alignment: 0.25` after a 350ms settle delay.
  - `StopCard` accepts `isHighlighted: true`, rendering an emerald glow background, green border, and `🏆 GROUP POLL WINNER · FOCUSED` banner.

---

## 24. 🔤 TYPOGRAPHY ARCHITECTURE & BRAND FONT TOKENS (IMP-088)

- **Centralized Font Token Contract**:
  - `AppTextStyles.fontHeading`: `'Playfair Display'` — Serif display font for brand logos, screen headlines, section titles, and modal headers.
  - `AppTextStyles.fontBody`: `'DM Sans'` — Primary geometric sans-serif for body copy, buttons, labels, inputs, chips, and UI controls.
  - `AppTextStyles.fontSerifFallback`: `'Georgia'` — Canonical high-legibility platform serif fallback.
  - `AppTextStyles.serifFallbacks`: `const ['Georgia', 'serif']` — Public constant list for all serif display fallbacks.
- **Strict Anti-Hardcoding & Numeric Invariant**:
  - **All Numbers & Statistics Must Be DM Sans**: All numeric readouts, countdowns, budget amounts, allowances, percentages, and metrics strictly resolve to [`AppTextStyles.fontBody`](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_text_styles.dart) (`'DM Sans'`) or semantic tokens like `AppTextStyles.statNumberLarge`, `statNumberMedium`, and `statNumberSmall`. Display serif (`fontHeading`) is reserved solely for non-numeric titles, brand marks, and section headers.
  - **Zero Hardcoded Font Family Strings**: Never write `fontFamily: 'DM Sans'`, `fontFamily: 'Playfair Display'`, or `['Georgia', 'serif']` anywhere in feature screens or widgets.
  - All text styles must resolve through semantic tokens in [`AppTextStyles`](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_text_styles.dart) or reference `AppTextStyles.fontHeading`, `AppTextStyles.fontBody`, and `AppTextStyles.serifFallbacks`.
  - Default parameters in shared widgets (e.g. `MemberAvatarCircle`) must default to `AppTextStyles.fontBody`.

---

## 25. 💰 BUDGET & EXPENSES ARCHITECTURE (IMP-084, IMP-085)

- **Shared Entity**: `ExpenseModel`
  - Columns: `id`, `trip_id`, `description`, `amount`, `category`, `paid_by_user_id`, `status` (`pending`, `approved`, `rejected`), `receipt_url`, `rejection_note`.
  - Invariant: Never insert or query forbidden columns `split_meta` or `rejected_by`.
- **Trip Expenses (Group Focus & Classic Layout)**:
  - Preserves the established group layout:
    - **Hero Card (`TripBudgetHeroCard`)**: Trip Name, Subtitle, Ring Chart with "% spent", total budget, remaining amount, and "₱X spent by Y members".
    - **Sub-tabs**: `Overview` (Category breakdown & Member contributions), `Expenses` (Transactional CRUD log with approval workflow and receipt inspection), and `Split` (Greedy settlement plan & balances).
  - Transactional CRUD: `AddExpenseForm` with Camera / Gallery receipt upload via `ReceiptOcrService`, heuristic OCR price extraction, split-member multi-select with per-person calculations, and `ExpenseLog` with status filters (`All`, `Pending`, `Approved`, `Rejected`).
- **Budget (Personal Focus + Trip Summary)**:
  - Tailored specifically to the traveler's personal target and overall trip expense footprint:
    - **Hero Card (`PersonalTripBudgetHeroCard`)**: Modeled after the clean template design with Deep Earth `#2C1A14` container, Playfair Display typography, personal budget readout, emerald green remaining badge, slim horizontal progress bar, and an integrated **Trip Expenses Summary** pill row (Solo Spent, Group Liability share, and Trip Total).
    - **Content**: `DailyPacingCard` (daily burn rate & velocity tips), `CashVsDigitalCard` (cash-in & digital split), `CategoryBudgetChart` (trip category breakdown summary), and `PersonalExpenseList` (pocket expense history).
  - Trip context switcher carousel: pure UI state allowing seamless trip flipping without state mutation or persistence overhead.

## 26. 🧭 TRIP STATUS ARCHITECTURE & LIFECYCLE (IMP-090)

- **TripStatus Canonical Enum**:
  - `TripStatus.draft`: Incomplete or unfinalized trip (`isDraft == true`).
  - `TripStatus.planning`: Future trip scheduled ahead of today (`today < fromDate`).
  - `TripStatus.ongoing`: Active trip happening right now (`fromDate <= today <= toDate`).
  - `TripStatus.completed`: Concluded or archived trip (`toDate < today` or `isArchived == true`).
- **Dynamic Status Derivation (`TripModel.status`)**:
  - Centralized single source of truth on `TripModel.status` with helper getters `isPlanning`, `isOngoing`, and `isCompleted`. Eliminates scattered inline date comparisons.
- **Dedicated ONGOING Section in Trips Screen**:
  - `TripsScreen` cleanly splits trips into 4 distinct chronological buckets:
    1. `DRAFTS` (if drafts exist)
    2. `ONGOING` (active trips happening today, pinned prominently above upcoming)
    3. `UPCOMING` (future trips still in planning)
    4. `PAST TRIPS` (completed/archived trips)
- **State Management & Home Prioritization (`tripStatusProvider` & `activeTripProvider`)**:
  - `tripStatusProvider`: Reactive Riverpod provider (`Provider.family<TripStatus, TripModel>`) providing instant status observation.
  - `activeTripProvider`: Automatically prioritizes `ongoing` trips first, then `planning` trips, ensuring travelers on an active vacation immediately see their live trip on the home screen.
- **Live Day Counter & Badge in NextTripCard**:
  - When a trip is `ongoing`, `NextTripCard` displays an `ONGOING TRIP` pill badge with emerald pulse dot and switches countdown to a live day-of-trip counter (`Day X of Y days` / `Day of trip`).


## 27. 📱 UI ARCHITECTURE & COMPONENT REGISTRY
- Comprehensive UI component hierarchy, screen routing map, design tokens, sheets, and modal structure are maintained in [docs/UI_STRUCTURE.md](file:///d:/Spencer/Downloads/tara_travel/docs/UI_STRUCTURE.md).
- Any screen or subcomponent restructuring must update `docs/UI_STRUCTURE.md` alongside code changes.

## 28. 📐 UNIVERSAL RESPONSIVE LAYOUT ENGINE (PLAN 19 / IMP-091)
- **Centralized Tokens & Breakpoints (`lib/core/theme/app_responsive.dart`)**:
  - Breakpoints: `compactWidth = 360` (small phones/fold covers), `standardWidth = 414` (standard flagship), `tabletWidth = 600`.
  - Dynamic `responsiveHPad`: 16dp on compact (<360dp), 20dp on standard, 24dp on wide/tablets.
  - Safe inset-aware bounds: `sheetMaxHeight([fraction = 0.85])` computes safe sheet ceiling subtracting system top/bottom insets to avoid notch clipping.
  - Inset helpers on `BuildContext`: `context.topInset`, `context.bottomInset`, `context.keyboardHeight`, `context.safeBottomPadding(base)`, `context.keyboardBottomPadding(base)`.
- **Global Text Scaler Bounds**:
  - `AppResponsive.clampedTextScaleBuilder` registered on `MaterialApp.builder` in `lib/main.dart`.
  - Clamps `MediaQuery.textScaler` between `0.85` and `1.20` to prevent extreme accessibility enlargement from overflowing fixed-height chips, pills, badges, and action docks.
- **Zero Hardcoded Dimension Multipliers**:
  - Eradicated raw `MediaQuery.of(context).size.height * fraction` and hardcoded `+ MediaQuery.of(context).padding.bottom` arithmetic across all 37+ modal sheets, dialogs, and screen lists.

## 29. 🚀 APP VERSIONING, REMOTE CONFIG & CI/CD OTA AUTOMATION (PLAN 17 / IMP-093)
- **Authoritative Remote Schema (`public.app_versions`)**:
  - Columns: `id`, `platform`, `min_supported_version`, `latest_version`, `force_update_url`, `maintenance_mode`, `maintenance_title`, `maintenance_message`, `estimated_back_online`, `release_notes`, `created_at`, `updated_at`.
  - Public read RLS (`anon_select_app_versions`) allows unauthenticated and authenticated clients to verify compatibility.
  - Mutations strictly restricted to `service_role` (CI/CD pipeline only).
- **Three-Tier User UX Modals**:
  - **Tier 1: Mandatory Force-Update (`ForceUpdateScreen`)**: Non-dismissible full-screen gate when current version < `min_supported_version`. Disables app access, renders changelog, and features in-app streaming download & install via `ApkDownloadInstaller`.
  - **Tier 2: Soft Update Recommendation (`SoftUpdateSheet`)**: Dismissible bottom sheet when current version < `latest_version` but supported. Highlights new features with "Update Now" and "Later" options.
  - **Tier 3: Maintenance Mode (`MaintenanceModeScreen`)**: Non-dismissible full-screen gate when `maintenance_mode == true`. Displays estimated back-online timer and status verification retry action.
- **Settings "Check for Updates"**:
  - Embedded in `ProfileScreen` Account Settings. Shows live version pill (`UPDATE`), triggers immediate Supabase remote check, and notifies user via `AppFeedback` toast or update modal.
- **Direct OTA Distribution & CI/CD Pipeline (`.github/workflows/auto_release.yml`)**:
  - Triggered on push to `live` or `release/**` and `workflow_dispatch`.
  - Enforces static analysis gate (`flutter analyze --fatal-warnings`), compiles release APK & Android App Bundle (.aab), uploads release APK to Supabase Storage bucket `app-releases`, and inserts new version record into `public.app_versions` via Supabase REST API curl.

---

*This document is the single source of architectural truth for Tara Travel. Update this file whenever database schemas, RPC functions, core repositories, or system flows are modified.*










