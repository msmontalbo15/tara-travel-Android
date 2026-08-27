# 🧠 TARA TRAVEL — ARCHITECTURAL MEMORY & AI GROUND TRUTH
> **AUTHORITATIVE CONTEXT FOR AI ASSISTANTS & CORE DEVELOPERS**  
> **Status**: Production Verified  
> **Last Synced**: August 2026  
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

## 2. 🗄️ SUPABASE DATABASE SCHEMAS (17 ACTIVE TABLES)

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
  cover_color text,
  cover_emoji text,
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
  status text not null default 'planned' check (status in ('planned','completed','skipped','arrived')),
  booking_ref text,
  day_number integer default 1,
  sort_order integer default 0,
  assigned_user_id uuid references public.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 8. STOP VOTES
public.stop_votes (
  id uuid primary key default gen_random_uuid(),
  stop_id uuid references public.itinerary_stops(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  vote text not null check (vote in ('up', 'down')),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (stop_id, user_id)
);

-- 9. PACKING ITEMS
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

-- 13. TRIP MESSAGES (Live Chat)
public.trip_messages (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  sender_name text not null,
  content text not null,
  message_type text default 'text' check (message_type in ('text','image','system')),
  media_url text,
  created_at timestamptz default now()
);

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
- **`public.join_trip_by_code(p_invite_code text) -> jsonb`** *(RPC, Migration 017)*  
  Finds the trip by sanitized 6-character invite code, inserts `auth.uid()` into `trip_members` with `status = 'pending'`, fans out in-app notifications (`trip_join_request`) to all organizers/owners, logs activity, and returns `{ success, trip_id, trip_name, status }`.
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
| `trips` | `cover_image_url`, `discord_channel_id` | Dropped. Use `cover_emoji` and `cover_color`. |
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
- `Future<void> updateStopStatus(String stopId, StopStatus status)` — Syncs stop status (`planned`, `completed`, `skipped`, `arrived`) to Supabase.
- `Future<void> saveItineraryDay(String tripId, ItineraryDay day)` — Direct PostgREST upsert to `itinerary_stops`.
- `Future<void> deleteStop(String stopId)` — Direct delete from `itinerary_stops`.
- `Future<void> voteOnStop({tripId, stopId, memberId, upvote})` — Collaborative vote upsert into `public.stop_votes`.
- `Future<void> removeVote({stopId, memberId})` — Removes member vote from `public.stop_votes`.

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

### 9. Core Infrastructure Services
- **`SecureSessionRepository.instance`** (`lib/core/auth/data/secure_session_repository.dart`):
  - `persistSession(Session session)`: Saves access/refresh tokens in Keystore.
  - `restoreSession()`: Recovers Supabase session using refresh token.
  - `clearSession()`: Wipes all auth tokens on logout.
- **`ThreeLayerEncryptionService.instance`** (`lib/core/security/three_layer_encryption_service.dart`):
  - `init()`: Generates/loads client RSA-2048 and AES-256-GCM keys into Keystore.
  - `encryptData(String plainText)` / `decryptData(String cipherText)`: Protects PII (`phone`, `gcash_number`, `health_notes`).
- **`UserPresenceService.instance`** (`lib/core/services/user_presence_service.dart`):
  - `start([userId])` / `stop()`: Automatic lifecycle observer (`WidgetsBindingObserver`) setting `is_online = true` / `false` and 45s heartbeat pings.
- **`SupaService.instance`** (`lib/core/services/supa_service.dart`):
  - Low-level direct table operations, device token registration, and presence pings.

---

## 7. 🔄 RIVERPOD PROVIDERS & STATE INDEX

| Provider Name | Type | Scope / Responsibility |
| :--- | :--- | :--- |
| `authNotifierProvider` | `StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>` | MVI Auth state machine (`Unauthenticated`, `Authenticating`, `Authenticated`, `AuthError`). |
| `tripProvider` | `StateNotifierProvider<TripNotifier, AsyncValue<List<TripModel>>>` | Global list of user trips, add/edit/archive/delete/join actions. |
| `selectedTripProvider` | `StateProvider<TripModel?>` | Active trip context across Detail, Itinerary, Budget, Packing, Chat. |
| `activeTripProvider` | `FutureProvider<TripModel?>` | Returns the first non-draft, non-archived trip (or selected trip if unarchived); returns `null` when only archived trips exist. |
| `profileProvider` | `StateNotifierProvider<ProfileNotifier, ProfileState>` | User profile state, surname privacy toggle, encrypted data sync. |
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
| `realtimeNotifierProvider(tripId)`| `StateNotifierProvider<RealtimeNotifier, RealtimeState>` | Live GPS member location tracking, stop voting broadcasts. |
| `exploreProvider` | `FutureProvider<List<DestinationModel>>` | Destination catalog with search, tags, and rating filters. |

---

## 8. 🚀 IMPLEMENTED PLANS & FEATURE WORKFLOWS

### 1. Create Trip Flow (`lib/features/create_trip/`)
- **Step 1 (Basics)**: Trip Name, Destination search, Date range selection (`fromDate` to `toDate`).
- **Step 2 (Transport & Logistics)**: Transport mode selection (`plane`, `car`, `ferry`, `bus`) + `transport_meta` JSON serialization.
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
- **Display & Headlines**: `Playfair Display` (Bold / SemiBold)
- **Taglines & Accents**: `Playfair Display` (Italic)
- **UI Labels & Body**: `DM Sans` (Medium / Regular)

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
  - 1-tap conversion from `StopCard` / `_StopDetailSheet` pre-populating `AddExpenseForm` (description, cost, category, date).
- **Group Roll Call**:
  - `RollCallSheet` allows organizers to toggle companion check-ins per stop; updates `checkedInMemberIds` and syncs real-time state.
- **Day Management**:
  - `shiftDaySchedule(dayIndex, minutesOffset)`: Adjusts all start/end times forward or backward by 30m or 60m.
  - `duplicateDay(dayIndex)`: Clones day and all stops into a new appended itinerary day.
  - `moveStopToDay(fromDay, toDay, stopId)`: Translocates a stop across different itinerary days.
  - `deleteDay(dayIndex)`: Removes day and re-indexes remaining days.

---

*This document is the single source of architectural truth for Tara Travel. Update this file whenever database schemas, RPC functions, core repositories, or system flows are modified.*


