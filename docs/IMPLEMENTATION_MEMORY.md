# 📝 TARA TRAVEL — IMPLEMENTATION MEMORY & CHANGE LOG
> **AUTHORITATIVE LIFETIME IMPLEMENTATION RECORD (DAY 1 TO PRESENT)**  
> **Rule**: Every new feature, SQL migration, RPC function, repository method, Riverpod provider, service, or bugfix MUST append an entry here and synchronize [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md).

---

## 📋 Comprehensive Implementation Index

| Milestone | Date | Component(s) | Summary |
| :--- | :--- | :--- | :--- |
| **`IMP-001`** | 2026-07-13 | Core / UI Scaffold | Project genesis, directory architecture, Material 3 theme & Brand Design tokens. |
| **`IMP-002`** | 2026-07-30 | Supabase Migration 001 | Initial database schema (users, trips, members, stops, expenses, packing). |
| **`IMP-003`** | 2026-08-03 | Supabase Migration 002 | Real data support, `member_locations`, Google Maps live presence integration. |
| **`IMP-004`** | 2026-08-07 | Supabase Migration 003 | Dev seed data fixtures for Philippine destinations & sample itineraries. |
| **`IMP-005`** | 2026-08-12 | Supabase Migration 005 | Realtime group chat architecture with Sembast write-through caching. |
| **`IMP-006`** | 2026-08-14 | Supabase Migration 006 | Auth trigger automation (`handle_new_user`) & Google Sign-In token exchange. |
| **`IMP-007`** | 2026-08-17 | Supabase Migration 007 | Collaborative itinerary stop voting system (`public.stop_votes`). |
| **`IMP-008`** | 2026-08-18 | Supabase Migration 008 | 6-character alphanumeric invite code generator & `join_trip_by_code` RPC. |
| **`IMP-009`** | 2026-08-19 | Supabase Migration 009 | Error-resilient user auto-provisioning trigger with fallback metadata. |
| **`IMP-010`** | 2026-08-19 | Supabase Migration 010 | RLS anti-recursion engine & `is_trip_member` security definer. |
| **`IMP-011`** | 2026-08-20 | Supabase Migration 011 | Transport metadata sync & edge-to-edge system navigation across 17 screens. |
| **`IMP-012`** | 2026-08-21 | Supabase Migration 012 | Surname privacy obfuscation (`hide_surname`) & `formatDisplayName` formatter. |
| **`IMP-013`** | 2026-08-22 | Supabase Migration 013 | Global RLS security definers (`user_owns_trip`, `user_can_access_trip`). |
| **`IMP-014`** | 2026-08-23 | Supabase Migration 014 | Column normalization (`booking_ref`, `departure_point/lat/lng`, member status). |
| **`IMP-015`** | 2026-08-24 | Supabase Migration 015 | Schema cleanup: dropped legacy/unused columns & consolidated `friends` table. |
| **`IMP-016`** | 2026-08-24 | Supabase Migration 016 | Complete CRUD RLS policies for `trips` and `trip_members`. |
| **`IMP-017`** | 2026-08-24 | Security / Keystore | 3-Layer encryption engine (RSA-2048 + AES-256-GCM + TLS 1.3) for sensitive data. |
| **`IMP-018`** | 2026-08-24 | Auth / Session | Cold-start session hydration & per-user Sembast database partitioning. |
| **`IMP-019`** | 2026-08-24 | Offline Engine | Offline-first sync queue (`OfflineSyncQueue`) & auto-flushing `SyncManager`. |
| **`IMP-020`** | 2026-08-24 | Architecture Memory | Master `MEMORY.md`, system flow specs & continuous memory synchronization protocol. |
| **`IMP-021`** | 2026-08-24 | Design Patterns / REST API | Created `SOFTWARE_DESIGN_PATTERNS.md` defining 10 Core API guidelines & Flutter architecture patterns. |
| **`IMP-039`** | 2026-08-24 | UI / Empty-State | "No Trip Created" premium empty-state experience: `EmptyTripHeroCard`, `StarterTemplatesCarousel`, shared `showJoinTripModal`, prefill support in `CreateTripFlow`. |
| **`IMP-041`** | 2026-08-25 | Provider / State | Active Trip Archived Fallback Guard in `activeTripProvider`. |
| **`IMP-042`** | 2026-08-25 | UI / Responsiveness | Mobile Resolution & Layout Responsiveness Hardening across 7 core screens. |
| **`IMP-043`** | 2026-08-25 | Member Lifecycle / Notifications | Organizer approval workflow, member removal, voluntary trip departure, and automated notification triggers. |
| **`IMP-047`** | 2026-08-25 | Itinerary / Supabase Sync | Permission-gated Itinerary Day Deletion (Organizers & Navigators), multi-day check, batch stop deletion (`deleteStops`), and remote day re-indexing synchronization. |
| **`IMP-048`** | 2026-08-26 | Maps & Live Tracking | Complete open-source migration to `flutter_map` (OSM), PostGIS live tracking (`004_postgis_live_tracking.sql`), `LocationTrackingService` with offline queue, `GroupRideSyncService` with exponential backoff, and Philippine `Nominatim` geocoding. |
| **`IMP-049`** | 2026-08-26 | Member Roles & Security RPC | Atomic member role assignment via `update_member_roles` RPC, `user_is_trip_organizer` RLS recursion helper, extended `trip_members_update` policy, and reactive UI state invalidation. |
| **`IMP-050`** | 2026-08-26 | Social Graph & Friend Module | 3-tab modern Friends UI (My Friends, Requests, Find Friends), bidirectional friend status resolution, live user preview search, QR sharing, request management, and trip invitation integration. |
| **`IMP-051`** | 2026-08-26 | Real-time Friend Presence | `UserPresenceService` with heartbeat & lifecycle observer, `friendsRealtimePresenceProvider`, dynamic online calculation (`isCurrentlyOnline`, `presenceStatusText`), and interactive online friend filtering. |
| **`IMP-052`** | 2026-08-27 | Packing / Custom Sub-Categories | Custom sub-categories pill/tab filter system in `_PackingCategoryCard`, `sub_category` schema sync in `PackingRepository`, preset suggestions, item tag chips & inline add integration. |
| **`IMP-053`** | 2026-08-27 | UI / Home Trip Budget Bar | Functional & interactive trip card budget bar, `QuickBudgetSheet` modal editor, dynamic warning states (Warning Amber 70%+, Exceeded Red 100%+), remaining/over budget calculation, and NextTripCard budget tracker integration. |
| **`IMP-054`** | 2026-08-27 | Itinerary / Next Destination Banner | Made `ItineraryFulfillmentBanner` (the progress % and N of N stops visited card) interactive to open Google Maps for the next uncompleted stop, with fallback search and visual 'Go' navigation CTA button. |
| **`IMP-055`** | 2026-08-27 | UI / Home Hero Clean-up | Removed budget tracker section and unused imports from homepage header hero (`NextTripCard`), recalibrating `_HomeHeaderDelegate` max extent height. |
| **`IMP-056`** | 2026-08-27 | Itinerary / Multi-Stop Navigation | Fixed `NavigateRouteButton` multi-stop navigation to directly launch Google Maps with all intermediate waypoints and final destination instead of single-point `geo:` fallback. |
| **`IMP-057`** | 2026-08-27 | Itinerary / Multi-Stop Route Engine | Advanced Multi-Stop Route Construction engine: smart Title+Location target geocoding, GPS origin prefill, remaining-vs-all stops scope selector, dynamic travel mode mapping (car, motorcycle, walking, transit, bike), interactive timeline preview sheet, and one-tap link sharing. |
| **`IMP-058`** | 2026-08-28 | Social / Camera QR & Profile ID | Live Camera QR Scanner modal (`QrScannerModal`) via `mobile_scanner`, point-and-shoot camera friend scanning with auto-lookup and prefill in `friends_screen.dart`, and User ID / Friend Code badge chips and QR modal launch in `profile_screen.dart`. |
| **`IMP-059`** | 2026-08-28 | Trips / Invite Code Join Flow | Hardened Join Trip by Invite Code workflow: regex sanitization in `InviteCodeGenerator`, FK pre-flight user row provision in `TripRepository`, resilient RPC parsing & direct fallback, `019_fix_join_trip_by_code.sql` migration, and reactive `_JoinTripSheet` (ConsumerStatefulWidget). |
| **`IMP-060`** | 2026-08-28 | UI / Standardized Feedback System | Unified Feedback System (IDEA-001): `AppFeedback`, `AppDialog`, `AppBanner`, semantic `FeedbackType`, brand token theme integration, and 100% migration across 11+ UI feature screens/widgets. |
| **`IMP-061`** | 2026-08-28 | Itinerary / Progressive Disclosure & Action Hub | Streamlined Itinerary Architecture (IDEA-002): `DayInsightsHeader` collapsible accordion, `ItineraryActionSheet` unified "⋯" more hub, `ItineraryBottomDock` floating action bar, `StopDetailSheet`, `ItineraryMapSheet`, collapsible `SmartSuggestionChips`, and automated GPS arrival geofencing engine. |
| **`IMP-062`** | 2026-08-28 | Navigation / Live Location & Convoy Tracking | Real-Time Group Live Location Sharing, Convoy Tracking & Direct Member Navigation (IDEA-003): `LocationBroadcastService` over Supabase Realtime ephemeral broadcast channels, adaptive GPS polling (5s/15s/60s), `NavigateToMemberSheet` (in-app routing & external GPS launch), `ConvoyAlertBanner` separation warnings, `SosEmergencyModal` panic beacons, and `PrivacyControlSheet` (Ghost Mode & approximate location fuzzing). |
| **`IMP-065`** | 2026-08-31 | Trips / Theme & Visual Consolidation | Unified trip type, theme accent color, and emoji under canonical `tripType` and `AppTripTypes`. Dropped redundant `cover_color` and `cover_emoji` columns via migration 020. |
| **`IMP-066`** | 2026-08-31 | UI / Shared TripTypeCarousel & Type Precision | Extracted shared `TripTypeCarousel` widget (DRY) for both Create and Edit Trip flows; dropped PostgreSQL and Dart enum whitelists to support all 16 `AppTripTypes`. |
| **`IMP-067`** | 2026-08-31 | Auth / Onboarding Bypass & Account State Guard | Fixed onboarding resurfacing for existing accounts by adding `isAccountFullySet` fallback checks, auto-recovering `hasCompletedOnboarding` in `ProfileNotifier`, and updating `AuthGate` & `OnboardingScreen` lifecycle guards. |
| **`IMP-068`** | 2026-08-31 | Itinerary / Ultra-Simplified Stop Cards & Presence Hub | Ultra-Simplified Itinerary Stop Cards & Unified "Mark as Arrived" Presence Hub (IDEA-007): stripped StopCard to single Navigate CTA, added top-right edit & hero self check-in to StopDetailSheet, built inline companion arrival roster with batch toggle, and retired RollCallSheet. |
| **`IMP-069`** | 2026-09-01 | Database & Itinerary / Stop Votes & Status Retirement | Dropped public.stop_votes table and status column on itinerary_stops (Migration 021). Removed StopStatus enum, voting models/repositories/providers, and status action bars. |
| **`IMP-070`** | 2026-09-01 | UI & Itinerary / Driver-Ready Slide-to-Arrive Bottom Dock | Relocated arrival control to a fixed bottom dock in StopDetailSheet featuring SlideToArriveButton with spring physics, haptics, and high-contrast confirmed arrival status with Undo. |
| **`IMP-071`** | 2026-09-01 | UI & Navigation / Floating Dock Live Nav Migration | Relocated Live Nav trigger to ItineraryBottomDock, decluttered NextTripCard/TripCard action bars, and optimized TurnCard with external Google Maps navigation handoff. |
| **`IMP-072`** | 2026-09-01 | UI & Home / Trip Card Date Abbreviation & Budget Clean-up | Abbreviated date ranges on home trip cards, replaced middle stat box with non-clickable ITINERARY (visited/total), and converted budget tracker to an informational progress bar without Manage >. |
| **`IMP-073`** | 2026-09-01 | UI & Itinerary / Driver-Ready Touch Targets & Enriched Buttons | Scaled up all itinerary interactive CTA buttons (StopCard Navigate button, StopDetailSheet Navigate Maps / Expense / Edit / Slide to Arrive / Member toggle, NavigateRouteButton, DayStrip tabs, and ItineraryBottomDock) for effortless driver and one-handed thumb tapping on the road. |
| **`IMP-091`** | 2026-09-05 | Architecture & UI / Universal Responsive Layout Engine (Plan 19) | Dynamic screen-size adaptation (iPhone SE to large foldables), global textScaler clamp (0.85-1.20), centralized AppResponsive tokens/extensions, zero hardcoded MediaQuery arithmetic across 37+ files. |
| **`IMP-074`** | 2026-09-02 | UI & Home / Quick-Action Red Notification Dot Indicator | Implemented IDEA-010: Contextual Red Notification Dot Indicator (`🔴`) on TripCard quick action buttons for new or modified content inside (Itinerary, Packing, Members, Expenses, Chat) using Keystore-backed `ModuleViewTrackerService`, self-action exemption, and reactive Riverpod stream diffing. |
| **`IMP-075`** | 2026-09-02 | UI & Itinerary / Stop Detail Sheet Live GPS ETA & Stop Sharing | Implemented real-time Estimated Time of Arrival (Live GPS ETA & inter-stop Haversine routing fallback) and 1-tap Stop Details Sharing (`share_plus`) inside `StopDetailSheet`, with 6-pillar information hierarchy and `previousStop` contextual routing handoff. |
| **`IMP-077`** | 2026-09-03 | UI / Brand-Aligned Back Button Standardization | Standardized and upgraded `AppBackButton` with Tara Travel brand tokens (12px radius, frosted glass, light, brand, and ghost variants) and replaced one-off back buttons across all screens (Packing, Friends, Navigation, Live Navigation, Chat, Notifications, Activity Log, Create Trip, and MapPinPicker). |
| **`IMP-078`** | 2026-09-04 | Chat, Polls & Firebase FCM | Interactive In-Chat Travel Polls, real-time live vote sync, one-tap winner resolution to itinerary, pinned announcements drawer, quick travel action chips, branded Coral gradient UI, and Firebase FCM notification service. |
| **`IMP-079`** | 2026-09-04 | Architecture & UI Standards | Formalized Mobile Responsive Layout Standards and Strict Overflow Prevention Patterns in `SOFTWARE_DESIGN_PATTERNS.md` & `MEMORY.md` (bounded flex, scrollable viewports, dynamic font ellipsis, and zero RenderFlex overflow tolerance). |
| **`IMP-080`** | 2026-09-04 | UI & Home / Quick Actions Grid | Refined Quick Actions Grid layout, card dimensions, and aesthetics: calibrated `childAspectRatio` from 1.34 to 1.52, compact padding, 30x30 icon containers, crisp typography, and responsive `_PulsingGuide` border alignment. |
| **`IMP-082`** | 2026-09-04 | Profile & Avatars / Storage Pipeline | Full unification of user profile photos and companion avatars across 8+ screens via Supabase Storage bucket `avatars` and `MemberAvatarCircle`. |
| **`IMP-083`** | 2026-09-04 | Chat, Polls & Activity Hub (IDEA-004) | Full rich travel chat hub: migration 025 (metadata & reactions jsonb), interactive rich embeds (Itinerary stops, Expense requests, Packing alerts, GPS location pin drops, Media photos, Tara Bot briefings), crowdsourced poll suggestions, emoji reactions bar with haptic toggle, and offline outbox queue. |
| **`IMP-084`** | 2026-09-04 | Polls & Votes / Bidirectional Vote Undo | Full vote undo engine: optimistic in-memory toggle and rollback in `PollsNotifier`, `getPollsAndVotesRaw` synchronous hydration, and clean tap-to-toggle unvoting on poll options without UI clutter. |
| **`IMP-085`** | 2026-09-04 | Polls / Winner Card & Detail Sheet | Replaced flat `_WinnerActions` resolve section with premium gradient `_WinnerCard` (green gradient, trophy badge, vote %, voter chips) that opens `_WinnerDetailSheet` bottom sheet with ranked results breakdown, animated progress bars, voter lists, and quick-action resolution buttons. |
| **`IMP-088`** | 2026-09-04 | Typography & Brand Identity Standardization | Formalized system branding font tokens in `AppTextStyles` (`fontHeading`, `fontBody`, `fontSerifFallback`), wired Georgia serif fallback for display headlines, splash "Tara TRAVEL" branding, and Home greeting name, aligned `AppTheme` light theme definitions, and synchronized `MEMORY.md`. |
| **`IMP-093`** | 2026-09-05 | UI / Home Trip Card Avatar Removal | Removed the overlapping member avatar section (`MemberAvatarCircle` stack row) from `TripCard` on the Home screen, eliminating redundant `travelers` mapping and dead code. |

---

## 🔍 Detailed Implementation History

### `IMP-001` · Project Genesis & Baseline Design Scaffold
- **Date**: July 13, 2026
- **Target Files**:
  - `pubspec.yaml`, `lib/main.dart`
  - `lib/core/theme/app_theme.dart`, `lib/core/theme/app_colors.dart`, `lib/core/theme/app_text_styles.dart`
  - `0_Brand identity.html`
- **Scope & Objectives**:
  - Initialized Flutter codebase with Material 3 and custom Tara Travel branding.
  - Implemented brand color tokens: Coral (`#D85A30`), Light Coral (`#F0997B`), Sand (`#FAECE7`), Sunset (`#EF9F27`), Deep Earth (`#2C1A14`), Warm White (`#F7F4F0`).
  - Configured typography system pairing `Playfair Display` (Headlines) and `DM Sans` (UI / Body).
  - Scaffolded feature modules: Onboarding, Home, Create Trip, Itinerary, Budget, Packing, Navigation, Chat, Profile.

---

### `IMP-002` · Supabase Initial Database Schema
- **Date**: July 30, 2026
- **Target Files**:
  - `supabase/migrations/001_initial_schema.sql`
- **Scope & Objectives**:
  - Provisioned relational database core tables: `users`, `trips`, `trip_members`, `itinerary_stops`, `expenses`, `settlements`, `packing_items`, `contributions`, `activity_log`, `notifications`.
  - Added timestamp trigger function `set_updated_at()` and expense audit trigger `log_expense_activity()`.
  - Configured foreign key cascades and relational constraints.

---

### `IMP-003` · Live Presence & Destination Tracking
- **Date**: August 3, 2026
- **Target Files**:
  - `supabase/migrations/002_real_data_support.sql`
  - `lib/features/navigation/`
- **Scope & Objectives**:
  - Created `public.member_locations` for live GPS coordinate sharing.
  - Created `public.destinations` catalog table.
  - Integrated `google_maps_flutter`, `geolocator`, and `location` packages for real-time map rendering.

---

### `IMP-004` · Destination Catalog & Seed Fixtures
- **Date**: August 7, 2026
- **Target Files**:
  - `supabase/migrations/003_dev_seed.sql`
  - `lib/core/providers/explore_provider.dart`
- **Scope & Objectives**:
  - Seeded top Philippine travel destinations (El Nido, Boracay, Siargao, Baguio, Cebu).
  - Wired `exploreProvider` to filter destinations by tags, activity types, and ratings.

---

### `IMP-005` · Real-Time Group Chat & Write-Through Caching
- **Date**: August 12, 2026
- **Target Files**:
  - `supabase/migrations/005_trip_messages.sql`
  - `lib/core/repositories/chat_repository.dart`
  - `lib/core/providers/chat_provider.dart`
  - `lib/features/chat/chat_screen.dart`
- **Scope & Objectives**:
  - Implemented `public.trip_messages` table for in-trip communication.
  - Built `ChatRepository` featuring optimistic local Sembast writes, write-through caching (`_kCacheLimit = 100`), and Supabase Realtime WebSocket streaming.

---

### `IMP-006` · User Auto-Provisioning & Native Google Auth
- **Date**: August 14, 2026
- **Target Files**:
  - `supabase/migrations/006_multi_user_fixes.sql`
  - `lib/core/repositories/auth_repository.dart`
  - `lib/core/auth/`
- **Scope & Objectives**:
  - Created PostgreSQL trigger `handle_new_user()` on `auth.users` to automatically populate `public.users` and `public.user_settings`.
  - Implemented `AuthRepository.signInWithGoogle()` exchanging native Google ID tokens with Supabase auth sessions.

---

### `IMP-007` · Collaborative Itinerary Stop Voting System
- **Date**: August 17, 2026
- **Target Files**:
  - `supabase/migrations/007_stop_votes.sql`
  - `lib/core/models/itinerary_model.dart`
  - `lib/features/itinerary/`
- **Scope & Objectives**:
  - Added `public.stop_votes` table supporting `up` and `down` votes per member.
  - Implemented real-time vote aggregation on stop cards to enable collaborative group consensus on itinerary activities.

---

### `IMP-008` · 6-Character Invite Code & Join Trip RPC
- **Date**: August 18, 2026
- **Target Files**:
  - `supabase/migrations/008_join_trip_by_code.sql`
  - `lib/core/utils/invite_code_generator.dart`
  - `lib/core/repositories/trip_repository.dart`
- **Scope & Objectives**:
  - Implemented `InviteCodeGenerator` generating clean 6-character codes excluding ambiguous characters (`0`, `O`, `I`, `1`).
  - Created PostgreSQL `SECURITY DEFINER` RPC `join_trip_by_code(p_invite_code)` to allow seamless trip joining without RLS recursion issues.

---

### `IMP-009` · Resilient Auth Trigger Metadata Handling
- **Date**: August 19, 2026
- **Target Files**:
  - `supabase/migrations/009_fix_new_user_trigger.sql`
- **Scope & Objectives**:
  - Refactored `handle_new_user()` trigger to gracefully extract `full_name`, `name`, or email prefix fallback from `raw_user_meta_data`, eliminating new-user sign-up failures.

---

### `IMP-010` · RLS Anti-Recursion Engine & Security Definer
- **Date**: August 19, 2026
- **Target Files**:
  - `supabase/migrations/010_fix_trip_members_rls_recursion.sql`
- **Scope & Objectives**:
  - Fixed PostgreSQL `42P17: infinite recursion detected` by introducing `public.is_trip_member(p_trip_id uuid)` with `SECURITY DEFINER` execution context.

---

### `IMP-011` · Transport Metadata & Edge-to-Edge Navigation Padding
- **Date**: August 20, 2026
- **Target Files**:
  - `supabase/migrations/011_sync_missing_fields.sql`
  - `lib/core/models/trip_model.dart`
  - All screens in `lib/features/`
- **Scope & Objectives**:
  - Added `transport_mode` and `transport_meta` columns to `public.trips`.
  - Enforced `SystemUiMode.edgeToEdge` with transparent status/navigation bars and standardized bottom safe-area paddings across all 17 screens.

---

### `IMP-012` · Surname Privacy Obfuscation Engine
- **Date**: August 21, 2026
- **Target Files**:
  - `supabase/migrations/012_privacy_hide_surname.sql`
  - `lib/core/models/member_model.dart`
  - `lib/core/providers/profile_provider.dart`
- **Scope & Objectives**:
  - Added `hide_surname` boolean column to `public.users` and `public.user_settings`.
  - Implemented `MemberModel.formatDisplayName(name, hideSurname: bool)` across all UI layers, transforming `"Juan Dela Cruz"` into `"Juan D."` when privacy is enabled.

---

### `IMP-013` · Global RLS Recursion Elimination & Security Definers
- **Date**: August 22, 2026
- **Target Files**:
  - `supabase/migrations/013_fix_rls_recursion.sql`
- **Scope & Objectives**:
  - Replaced subqueries in RLS policies with `public.user_owns_trip(trip_id)` and `public.user_can_access_trip(trip_id)`.
  - Enforced deterministic row access isolation for trips, itinerary stops, and expenses.

---

### `IMP-014` · Schema Normalization & Booking Reference Columns
- **Date**: August 23, 2026
- **Target Files**:
  - `supabase/migrations/014_ensure_columns.sql`
- **Scope & Objectives**:
  - Added `booking_ref` to `itinerary_stops`.
  - Added `departure_point`, `departure_lat`, `departure_lng` to `trips`.
  - Added `status` (`pending`, `approved`, `rejected`) to `trip_members`.

---

### `IMP-015` · Legacy Column Elimination & Friendship Consolidation
- **Date**: August 24, 2026
- **Target Files**:
  - `supabase/migrations/015_drop_unused_columns.sql`
- **Scope & Objectives**:
  - Permanently dropped unused/deprecated columns:
    - `trips`: `destination_lat`, `destination_lng`, `invite_expires_at`, `cover_image_url`, `discord_channel_id`.
    - `itinerary_stops`: `duration_min`, `google_place_id`, `photo_url`, `created_by`.
    - `packing_items`: `quantity`, `notes`, `created_by`, `checked_by`, `checked_at`.
    - `expenses`: `split_meta`, `rejected_by`.
    - `trip_messages`: `media_type`, `reply_to_id`, `is_edited`, `edited_at`.
    - `user_settings`: `email_notifications`, `mpin_hash`, `mpin_salt`, `profile_visibility`.
  - Permanently dropped redundant `friendships` table in favor of `public.friends`.

---

### `IMP-016` · Complete CRUD Row-Level Security Policies
- **Date**: August 24, 2026
- **Target Files**:
  - `supabase/migrations/016_fix_crud_rls.sql`
- **Scope & Objectives**:
  - Implemented complete CRUD RLS policies on `trips` (`trips_owner_all`, `trips_members_select`).
  - Implemented complete CRUD RLS policies on `trip_members` (`trip_members_select`, `trip_members_insert`, `trip_members_update`, `trip_members_delete`).

---

### `IMP-017` · 3-Layer Client Encryption Engine
- **Date**: August 24, 2026
- **Target Files**:
  - `lib/core/security/three_layer_encryption_service.dart`
  - `lib/core/repositories/profile_repository.dart`
- **Scope & Objectives**:
  - Layer 1: RSA-2048 client asymmetric keypair generated and stored in Android Keystore / iOS Keychain.
  - Layer 2: AES-256-GCM symmetric cipher encrypting sensitive fields (`phone`, `gcash_number`, `health_notes`) at rest in Supabase.
  - Layer 3: Enforced TLS 1.3 / HTTPS transport encryption.

---

### `IMP-018` · Cold-Start Session Hydration & Database Partitioning
- **Date**: August 24, 2026
- **Target Files**:
  - `lib/core/auth/data/secure_session_repository.dart`
  - `lib/core/services/database_service.dart`
  - `lib/core/widgets/auth_gate.dart`
  - `lib/main.dart`
- **Scope & Objectives**:
  - `SecureSessionRepository.restoreSession()` recovers Supabase auth session from Keystore *before* `runApp()`.
  - `DatabaseService.switchUser(userId)` isolates local Sembast databases per user UUID (`tara_travel_<user_id>.db`).
  - `AuthGate` route guard handles auto-login and session token refresh persistence.

---

### `IMP-019` · Offline-First Sync Queue & Reconnection Engine
- **Date**: August 24, 2026
- **Target Files**:
  - `lib/core/services/connectivity_service.dart`
  - `lib/core/offline/offline_sync_queue.dart`
  - `lib/core/offline/sync_manager.dart`
  - `lib/core/widgets/offline_banner.dart`
- **Scope & Objectives**:
  - `ConnectivityService` monitors network status changes.
  - `OfflineSyncQueue` enqueues failed/offline mutations in Sembast `offline_queue` store.
  - `SyncManager` auto-drains queued operations in FIFO order with retry backoff when online, invalidating Riverpod caches.

---

### `IMP-020` · Master Architecture Memory & Continuous Protocol
- **Date**: August 24, 2026
- **Target Files**:
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md)
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md)
  - [.agents/rules/architecture-memory.md](file:///d:/Spencer/Downloads/tara_travel/.agents/rules/architecture-memory.md)
- **Scope & Objectives**:
  - Documented all 17 database schemas, SQL functions, RPCs, 11 Riverpod providers, 9 repositories, 7 system flows, and brand design invariants.
  - Automated continuous memory synchronization rule across AI development cycles.

---

### `IMP-021` · REST API Best Practices & Software Design Pattern Standards
- **Date**: August 24, 2026
- **Target Files**:
  - [SOFTWARE_DESIGN_PATTERNS.md](file:///d:/Spencer/Downloads/tara_travel/SOFTWARE_DESIGN_PATTERNS.md)
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md)
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md)
- **Scope & Objectives**:
  - Formulated 10 Core REST API design guidelines: Versioning, Pagination (`limit`/`offset`), Rate Limiting headers (429), Idempotency Keys, HATEOAS (`_links`), Meaningful Status Codes, Database-side Filtering/Sorting, Plural Resource Naming, Header-based Auth (`Authorization: Bearer`), and Standardized Error Envelopes.
  - Documented 6 Flutter/Dart application design patterns: Repository Pattern, MVI/MVVM State Notifiers, Write-Through Sembast Caching, Partitioned Multitenancy, Circuit Breaker Offline Sync Queue, and 3-Layer Encryption.

---

### `IMP-022` · Removed Profile Completion Banner from Home Screen
- **Date**: August 24, 2026
- **Target Files**:
  - [home_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart)
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md)
- **Scope & Objectives**:
  - Completely removed the `ProfileCompletionBanner` widget from `HomeScreen` body list.
  - Cleaned up the unused `profile_completion_banner.dart` import in `home_screen.dart`.
  - Retained `ProfileCompletionBanner` in `ProfileScreen` where profile editing and management is housed.

---

### `IMP-039` · "No Trip Created" Premium Empty-State Experience
- **Date**: August 24, 2026
- **Target Files**:
  - [lib/features/trips/widgets/join_trip_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/widgets/join_trip_modal.dart) **[NEW]**
  - [lib/features/home/widgets/empty_trip_hero_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/empty_trip_hero_card.dart) **[NEW]**
  - [lib/features/home/widgets/starter_templates_carousel.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/starter_templates_carousel.dart) **[NEW]**
  - [lib/features/home/home_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart) **[MODIFIED]**
  - [lib/features/create_trip/create_trip_flow.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/create_trip/create_trip_flow.dart) **[MODIFIED]**
  - [lib/features/trips/trips_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/trips_screen.dart) **[MODIFIED]**
- **Scope & Objectives**:
  - **`join_trip_modal.dart`**: Extracted `_JoinTripSheet` from `trips_screen.dart` into a standalone, reusable `showJoinTripModal(BuildContext, WidgetRef)` function. Added drag handle, autofocus, focus-aware border, and `onSubmitted` keyboard handling for a polished UX.
  - **`empty_trip_hero_card.dart`**: Glassmorphic hero card rendered in the dark home header when `activeTrip == null`. Features BackdropFilter blur, animated breathing amber/coral ambient glow, faint compass watermark, dynamic rotating animated pill badges (e.g. `✈️ READY FOR YOUR NEXT GETAWAY?`, `🌴 TIME FOR AN ISLAND ESCAPE?`, `🚗 WEEKEND ROAD TRIP CALLING?`, `⛰️ READY FOR MOUNTAIN BREEZES?`), Playfair Display headline, and tactile bouncy interactive CTAs (`[ + Plan a Trip ]` with JIT guard & `[ 🏷️ Join with Code ]` with haptic feedback).
  - **`starter_templates_carousel.dart`**: Horizontal card carousel with 4 curated Philippine getaway templates (Boracay, Baguio, Siargao, Cebu). Each card includes emoji, destination name, tagline, duration pill, and accent-colored gradient border. Tap pre-fills `NewTripModel` and navigates to `/create-trip`.
  - **`home_screen.dart`**: (a) Added imports for new widgets. (b) Updated `_HomeHeaderDelegate.minExtent`/`maxExtent` to `topPadding + 220` when `activeTrip == null` — gives the glassmorphic hero card the correct non-collapsible space. (c) Added `else` branch to the `activeTrip` / `isLoadingTrip` conditional to render `EmptyTripHeroCard`. (d) Replaced `SizedBox.shrink()` in the body empty-state with `StarterTemplatesCarousel`.
  - **`create_trip_flow.dart`**: Added `didChangeDependencies` that reads a `NewTripModel` from `ModalRoute.of(context)?.settings.arguments` (guarded by `_didApplyPrefill` flag). Copies `destination`, `destinationLat/Lng`, `tripType`, `fromDate`, `toDate`, `coverColor` into `_draft` so `DetailsStep` opens pre-populated from a starter template.
  - **`trips_screen.dart`**: (a) Imported `join_trip_modal.dart`. (b) Upgraded `trips.isEmpty` view: sand circle icon container, updated headline/description copy, full-width primary "Create a Trip" button with coral shadow, secondary underlined text "Have an invite code? Join Trip". (c) Removed the 142-line inline `_JoinTripSheet` class (DRY elimination). (d) Removed now-unused `app_brand_logo.dart` import.
- **Architectural Rationale**:
  - Centralizing join-trip logic in a single `showJoinTripModal` function follows the DRY principle and prevents future divergence between the Home and Trips screens.
  - Route-argument prefill in `CreateTripFlow` uses the existing `ModalRoute.of(context)?.settings.arguments` pattern already used elsewhere in the app (e.g., `HomeRouteArgs`), maintaining architectural consistency.
  - `_didApplyPrefill` guard prevents re-applying the prefill on widget rebuilds (e.g., after system navigation events).
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).

---

### `IMP-040` · Pure Supabase Migration & Complete Local Cache Elimination
- **Date**: August 25, 2026
- **Target Files**:
  - [lib/core/repositories/expense_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/expense_repository.dart) **[REWRITTEN]**
  - [lib/core/repositories/itinerary_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/itinerary_repository.dart) **[REWRITTEN]**
  - [lib/core/repositories/packing_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/packing_repository.dart) **[REWRITTEN]**
  - [lib/core/repositories/chat_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/chat_repository.dart) **[REWRITTEN]**
  - [lib/core/repositories/profile_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/profile_repository.dart) **[REWRITTEN]**
  - [lib/core/providers/profile_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/profile_provider.dart) **[REWRITTEN]**
  - [lib/core/providers/realtime_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/realtime_provider.dart) **[REWRITTEN]**
  - [lib/core/providers/repository_providers.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/repository_providers.dart) **[CLEANED]**
  - [lib/core/widgets/auth_gate.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/auth_gate.dart) **[CLEANED]**
  - [lib/main.dart](file:///d:/Spencer/Downloads/tara_travel/lib/main.dart) **[CLEANED]**
  - [lib/features/onboarding/onboarding_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/onboarding/onboarding_screen.dart) **[CLEANED]**
  - [lib/features/onboarding/widgets/choose_mode_step.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/onboarding/widgets/choose_mode_step.dart) **[CLEANED]**
  - [lib/features/onboarding/widgets/gcash_mpin_view.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/onboarding/widgets/gcash_mpin_view.dart) **[CLEANED]**
  - [pubspec.yaml](file:///d:/Spencer/Downloads/tara_travel/pubspec.yaml) **[CLEANED]**
  - `lib/core/offline/offline_sync_queue.dart` **[DELETED]**
  - `lib/core/offline/sync_manager.dart` **[DELETED]**
  - `lib/core/services/database_service.dart` **[DELETED]**
  - `lib/core/services/session_cache_service.dart` **[DELETED]**
  - `lib/core/widgets/offline_banner.dart` **[DELETED]**
- **Scope & Objectives**:
  - **100% Pure Remote Supabase Architecture**: Removed all local Sembast databases, user-partitioned `.db` files, session cache timestamps, offline mutation queues, and offline banners.
  - **Direct PostgREST CRUD**: `ExpenseRepository`, `ItineraryRepository`, `PackingRepository`, `ChatRepository`, and `ProfileRepository` interact directly with Supabase via remote PostgREST queries with strict RLS enforcement.
  - **Stop Voting Remote Sync**: Added `voteOnStop` and `removeVote` methods to `ItineraryRepository` directly mutating `public.stop_votes`, with `stopVotesRealtimeProvider` invalidating providers on vote changes.
  - **Dropped Column Safety**: Fixed `PackingRepository.addItem` to avoid referencing the permanently dropped `created_by` column. Removed `rejected_by` in `SupaService`.
  - **3-Layer Encryption Preserved**: Retained `ThreeLayerEncryptionService` on `ProfileRepository` for end-to-end security on sensitive PII (`phone`, `gcash_number`, `health_notes`).
  - **Clean Riverpod Realtime Streams**: Removed all offline short-circuit guards across `realtime_provider.dart` so all multi-user collaborative streams remain live.
- **Architectural Rationale**:
  - Eliminates state desynchronization and dual-write complexity between local NoSQL stores and remote PostgreSQL tables.
  - Supabase Realtime WebSocket streams now act as the single source of truth for multi-user collaboration across group trips.
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).

---

### `IMP-041` · Active Trip Archived Fallback Guard
- **Date**: August 25, 2026
- **Target Files**:
  - [lib/core/providers/trip_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/trip_provider.dart) **[MODIFIED]**
- **Scope & Objectives**:
  - Updated `activeTripProvider` to explicitly guard against returning archived trips:
    - Selected trip must satisfy `!selected.isArchived`.
    - If `activeUpcoming` (non-draft, non-archived trips) is empty, `activeTripProvider` now returns `null` instead of falling back to `trips.first`.
  - Guarantees that when a user only has archived trips, the Homepage Header cleanly renders `EmptyTripHeroCard` (with `[ + Plan a Trip ]` and `[ 🏷️ Join with Code ]` CTAs) rather than rendering an archived trip in `NextTripCard`.
- **Architectural Rationale**:
  - Prevents archived trips from occupying active hero surfaces and ensures visual consistency between the Hero Header and the Homepage Body's `StarterTemplatesCarousel`.
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).

---

### `IMP-042` · Mobile Resolution & Layout Responsiveness Hardening
- **Date**: August 25, 2026
- **Target Files**:
  - [lib/features/home/home_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart) **[MODIFIED]**
  - [lib/features/home/widgets/empty_trip_hero_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/empty_trip_hero_card.dart) **[MODIFIED]**
  - [lib/features/home/widgets/quick_action_tile.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/quick_action_tile.dart) **[MODIFIED]**
  - [lib/features/trips/widgets/join_trip_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/widgets/join_trip_modal.dart) **[MODIFIED]**
  - [lib/features/trips/trips_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/trips_screen.dart) **[MODIFIED]**
  - [lib/features/explore/explore_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/explore/explore_screen.dart) **[MODIFIED]**
  - [lib/features/members/members_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/members/members_screen.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [lib/features/profile/profile_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/profile/profile_screen.dart) **[MODIFIED]**
- **Scope & Objectives**:
  - **Header Bounds Calibration**: Updated `_HomeHeaderDelegate.minExtent` / `maxExtent` when no active trip exists to `topPadding + 290.0`, eliminating RenderFlex overflows on the empty-state hero card.
  - **Grid Aspect Ratio**: Adjusted Quick Action Grid `childAspectRatio` from 1.45 to 1.34 for robust vertical breathing room on narrow screen widths (320px–360px).
  - **Dynamic Text Scaling**: Fitted CTA button labels and quick action tile text inside `FittedBox(fit: BoxFit.scaleDown)` to prevent clipping and overflow with large accessibility system fonts.
  - **Dynamic Safe Area PII**: Replaced hardcoded status bar top offsets (`56`, `52`) across all primary screens with `MediaQuery.paddingOf(context).top` offsets to seamlessly adapt to diverse hardware cutouts, notches, and status bar heights.
  - **Modal Scrollability**: Wrapped `_JoinTripSheet` in `SafeArea` + `SingleChildScrollView` with keyboard inset padding to prevent overflow when the virtual keyboard is open on small mobile viewports.
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).

---

### `IMP-043` · Organizer Approval Workflow, Member Removal & Notification Triggers
- **Date**: August 25, 2026
- **Target Files**:
  - [supabase/migrations/017_member_approval_and_notifications.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/017_member_approval_and_notifications.sql) **[NEW]**
  - [lib/core/repositories/trip_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/trip_repository.dart) **[MODIFIED]**
  - [lib/features/trips/widgets/join_trip_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/widgets/join_trip_modal.dart) **[MODIFIED]**
  - [lib/features/members/members_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/members/members_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Migration 017**:
    - Rewrote `public.join_trip_by_code(p_invite_code text)` RPC to insert joiners with `status = 'pending'`, automatically notify trip owners/organizers (`trip_join_request`), and write to `activity_log`.
    - Created `public.approve_member(p_trip_id uuid, p_member_uid uuid)` RPC with applicant notification (`trip_approved`).
    - Created `public.reject_or_remove_member(p_trip_id uuid, p_member_uid uuid, p_reason text)` RPC for declining pending requests or removing approved members with notification (`trip_rejected` / `member_removed`). Owner removal is strictly blocked.
    - Created `public.leave_trip(p_trip_id uuid)` RPC allowing non-owner members to exit a trip.
  - **Repository & Types**:
    - Added `JoinStatus` (`pending`, `approved`) and `JoinResult` model to `trip_repository.dart`.
    - Implemented `approveMember`, `rejectMember`, `removeMember`, and `leaveTrip` calling respective PostgreSQL RPCs.
  - **UI/UX Refinements**:
    - `join_trip_modal.dart`: Renders distinct feedback based on `JoinResult.isPending` vs `JoinResult.isApproved`.
    - `members_screen.dart`:
      - Added 1-tap Approve & Reject handlers with SnackBars for pending member requests.
      - Added "Remove from Trip" button to `_MemberCard` and `_RoleEditorSheet` with confirmation dialogs (hidden on trip creator).
      - Added "Leave Trip" button in the screen header for non-owners with confirmation dialog.
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).

---

### `IMP-044` · Accurate Itinerary Day Alignment to Trip Date Range
- **Date**: August 25, 2026
- **Target Files**:
  - [lib/core/repositories/itinerary_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/itinerary_repository.dart) **[MODIFIED]**
  - [lib/core/providers/itinerary_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/itinerary_provider.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [lib/features/trip_detail/widgets/edit_trip_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trip_detail/widgets/edit_trip_sheet.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Accurate Trip Date Range Mapping**:
    - Updated `ItineraryRepository.getItinerary(tripId, {startDate, endDate})` to calculate total days and sequential day dates (`Day 1` ... `Day N`) derived directly from the trip's `start_date` (`fromDate`) and `end_date` (`toDate`), rather than relying on `DateTime.now()` or only generating days that already contain stops.
    - Added fallback Supabase `trips` lookup for `start_date` and `end_date` if not supplied explicitly.
    - Maintained support for trips with stops beyond the trip end date by resolving `totalDays = max(tripDaysCount, maxStopDay)`.
  - **Riverpod Provider Integration**:
    - `ItineraryNotifier.build()` now resolves `tripRepo.getTripById(_tripId)` and passes `trip.fromDate` & `trip.toDate` to `getItinerary()`.
  - **Dynamic Budget & State Robustness**:
    - Replaced hardcoded `tripBudget / 7` with dynamic `tripBudget / totalDaysCount`.
    - Added bounds-safe fallback to `days.first` if `activeDay` index exceeds the current day count.
| **`IMP-045`** | 2026-08-25 | Comprehensive Itinerary Power Suite | Transit conflict detection, live roll call sheet, 1-tap cost-to-expense, and day schedule manipulation. |
| **`IMP-046`** | 2026-08-25 | Multi-Member Assignment Suite | Multi-member assignments on packing items & itinerary stops, batch role assignments, and multi-member expense splitting. |
| **`IMP-047`** | 2026-08-25 | Itinerary Functional Add Day & Date Extension | Fully functional Add Day action via DayStrip (+ Day) and DayActionsSheet, with dynamic date calculation and trip end_date auto-extension. |

---

## 🔍 Detailed Implementation History

### `IMP-047` · Itinerary Functional Add Day & Date Extension
- **Date**: August 25, 2026
- **Target Files**:
  - [lib/core/providers/itinerary_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/itinerary_provider.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/day_actions_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/day_actions_sheet.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/day_strip.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/day_strip.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Dynamic Add Day Engine**:
    - Implemented `ItineraryNotifier.addDay({DateTime? customDate})` returning the newly created `ItineraryDay`.
    - Automatically calculates next day number (`days.length + 1`) and next calendar date (+1 day from last day, or trip `fromDate`).
    - If the newly appended day exceeds `trip.toDate`, automatically updates `trip.toDate` in Supabase (`trips` table) and invalidates `activeTripProvider` / `allTripsProvider`.
    - Automatically shifts `activeDay` focus to the newly added day.
  - **User Experience & Feedback**:
    - Wired `DayStrip` "+ Day" button to call `addDay()` with informative toast (`Added Day N (MMM d) to itinerary! 🗓️`).
    - Added "Add New Day" action tile inside `DayActionsSheet`.
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).


### `IMP-046` · Multiple Member Assignment Suite (Packing, Itinerary, Roles, Expense Splitting)
- **Date**: August 25, 2026
- **Target Files**:
  - [lib/core/widgets/multi_member_picker_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/multi_member_picker_sheet.dart) **[NEW]**
  - [lib/core/models/packing_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/packing_model.dart) **[MODIFIED]**
  - [lib/core/models/itinerary_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/itinerary_model.dart) **[MODIFIED]**
  - [lib/core/providers/packing_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/packing_provider.dart) **[MODIFIED]**
  - [lib/features/packing/widgets/member_assignment_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/packing/widgets/member_assignment_sheet.dart) **[MODIFIED]**
  - [lib/features/packing/packing_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/packing/packing_screen.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/add_stop_form.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/add_stop_form.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/edit_stop_form.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/edit_stop_form.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/stop_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_card.dart) **[MODIFIED]**
  - [lib/features/members/members_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/members/members_screen.dart) **[MODIFIED]**
  - [lib/features/budget/widgets/add_expense_form.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/budget/widgets/add_expense_form.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Shared Multi-Member Picker Component**:
    - Created `MultiMemberPickerSheet` with interactive checkboxes, "Select All / Clear All" toggle, unassigned option, and reactive `onConfirm` callback.
    - Created `MemberAvatarStack` helper widget to visually stack multi-member profile badges with `+N` overflow indicator.
  - **Packing Items Multi-Assignment**:
    - Expanded `PackingItem` model to store `assignedMemberIds: List<String>`.
    - Rewrote `MemberAssignmentSheet` to utilize `MultiMemberPickerSheet`.
    - Updated `PackingNotifier.assignMembers()` and packing filter logic.
    - Rendered stacked member avatars in `_PackingItemRow`.
  - **Itinerary Stops Multi-Lead Assignment**:
    - Updated `ItineraryStop` model with `assignedMemberIds: List<String>`.
    - Updated `AddStopForm` and `EditStopForm` with toggleable multi-member chips.
    - Updated `StopCard` to render `MemberAvatarStack` and pluralized lead labels (`N leads`).
  - **Batch Role Assignment for Organizers**:
    - Added "Batch Assign" header action in `MembersScreen`.
    - Implemented `_BatchRoleEditorSheet` allowing organizers to apply multiple roles across selected members at once.
  - **Multi-Member Expense Split Calculator**:
    - Integrated multi-member "Split With" toggle chips into `AddExpenseForm`.
    - Added live calculation badge displaying `₱XX.XX / person (N travelers)`.
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).


### `IMP-047` · Itinerary Day Deletion & Supabase Synchronization
- **Date**: August 25, 2026
- **Target Files**:
  - [lib/core/repositories/itinerary_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/itinerary_repository.dart) **[MODIFIED]**
  - [lib/core/providers/itinerary_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/itinerary_provider.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/add_stop_form.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/add_stop_form.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/day_actions_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/day_actions_sheet.dart) **[VERIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Permission Enforcement**:
    - Enforced `canManageItinerary` check (`isOrganizer || isNavigator`) with a strict `false` fallback in `ItineraryScreen`.
    - Protected `DayActionsSheet` and "Delete Day" actions from non-privileged members.
  - **Multi-Day Guard**:
    - Guarded day deletion so trips with only 1 day cannot delete their remaining day (`allDays.length > 1`).
  - **Supabase Schema Alignment & UUID Validation**:
    - Replaced legacy `'new_timestamp'` ID generation in `AddStopForm` with standard `const Uuid().v4()` satisfying PostgreSQL `uuid` type constraints.
    - Added `_ensureUuid` and `_isValidUuid` in `ItineraryRepository.saveItineraryDay` to ensure all row IDs and `assigned_user_id` foreign keys strictly conform to PostgreSQL UUID requirements.
    - Aligned check constraints for `type` (`hotel`, `activity`, `food`, `transport`, `custom`) and `status` (`planned`, `arrived`, `completed`, `skipped`).
  - **Cost Sanitization & Location Input Fallback**:
    - Fixed `double.tryParse` failure in `AddStopForm` and `EditStopForm` caused by `CurrencyInputFormatter` comma formatting (e.g. `1,000` -> `double.tryParse` was evaluating to `null`).
    - Added `initialValue` support to `LocationPicker` for pre-populating existing locations in `EditStopForm`.
    - Added fallback text capture in `LocationPicker` so manual/custom typed addresses are captured and saved to Supabase even when a dropdown place prediction is not tapped.
  - **Full 4-Step Supabase Synchronization for Day Deletion**:
    - **Step 1**: Batch deleted all stops in the deleted day via `deleteStops`.
    - **Step 2**: Re-indexed remaining days (`day_number = 1..N`) and updated their calendar dates consecutively.
    - **Step 3**: Purged any orphan stops beyond the new total day count via `deleteStopsBeyondDay`.
    - **Step 4**: Shortened `end_date` in the `trips` table in Supabase via `tripRepo.updateTrip()` and invalidated `activeTripProvider` / `allTripsProvider`, preventing deleted days from reappearing as empty placeholder days.
  - **Itinerary Quick Actions Supabase Synchronization**:
    - **Duplicate Day**: Generates RFC4122 v4 UUIDs for all duplicated stops, appends the new day, and extends `end_date` in Supabase `trips` table when crossing the trip boundary.
    - **Move Stop to Another Day**: Synchronizes both source and destination days (`saveItineraryDay`) to ensure updated `day_number` and `sort_order` are immediately persisted.
    - **Shift Schedule**: Batch updates `time_start` and `time_end` across the day's stops and persists to Supabase.
    - **Clear Day**: Executes batch `deleteStops` in Supabase to completely remove all stops for the targeted day.
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).


### `IMP-048` · Open-Source Map Provider & PostGIS Real-Time Tracking Migration
- **Date**: August 26, 2026
- **Target Files**:
  - [pubspec.yaml](file:///d:/Spencer/Downloads/tara_travel/pubspec.yaml) **[MODIFIED]**
  - [supabase/migrations/004_postgis_live_tracking.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/004_postgis_live_tracking.sql) **[NEW]**
  - [lib/core/services/philippine_geocoding_service.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/services/philippine_geocoding_service.dart) **[NEW]**
  - [lib/core/services/location_tracking_service.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/services/location_tracking_service.dart) **[NEW]**
  - [lib/core/services/group_ride_sync_service.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/services/group_ride_sync_service.dart) **[NEW]**
  - [lib/core/providers/group_tracking_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/group_tracking_provider.dart) **[NEW]**
  - [lib/features/itinerary/widgets/itinerary_map.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/itinerary_map.dart) **[MODIFIED]**
  - [lib/core/widgets/inputs/location_picker.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/location_picker.dart) **[MODIFIED]**
  - [lib/core/widgets/inputs/map_pin_picker_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/map_pin_picker_modal.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/navigate_route_button.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/navigate_route_button.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **100% Free Open-Source Map Provider**:
    - Purged `google_maps_flutter` and `maplibre_gl` dependencies and API keys.
    - Integrated `flutter_map: ^7.0.2` and `latlong2: ^0.9.1` with OpenStreetMap / CartoDB tiles.
    - Added custom Flutter widget markers for stops and animated group rider avatars with heading orientation and speed badges.
    - Implemented polyline route overlays and interactive camera controls.
  - **PostGIS Realtime Spatial Sync**:
    - Created migration `004_postgis_live_tracking.sql` with PostGIS extension, `GEOMETRY(Point, 4326)` column, GiST spatial index, and `update_member_location` RPC.
    - Built `LocationTrackingService` streaming high-accuracy GPS telemetry (lat, lng, heading, speed, altitude) synced to Supabase every 3 seconds.
  - **Network Resilience & Mountain Pass Offline Handling**:
    - Implemented local FIFO queue for outgoing GPS pings when connection drops in rural/mountainous Philippine terrain, automatically bulk-flushing once reconnected.
    - Built `GroupRideSyncService` wrapping Supabase Realtime with exponential backoff auto-reconnection (1s → 30s) and WebSocket disconnect handling.
    - Handled offline group riders by retaining last-known locations with a visual "Signal Lost" badge and dimmed opacity instead of dropping markers.
  - **Philippine-Bounded Nominatim Geocoding**:
    - Built `PhilippineGeocodingService` with strict PH bounding box (`viewbox=116.9298,4.5872,126.6053,21.1221`) and `countrycodes=ph`.
    - Integrated LRU caching and `CancelToken` debounce cancellation for forward search and reverse geocoding.
    - Refactored `LocationPicker` and `MapPinPickerModal` to use the open geocoder without proprietary API keys.
  - **Uniform Map Pin Picker Standardization**:
    - Embedded direct "Pin on Map" interactive header button, text field suffix icon, and dropdown quick-launch into the universal `LocationPicker`.
    - Refactored `DetailsStep` (Destination), `TransportStep` (Departure Point), `EditTripSheet` (Destination), `AddStopForm` (Stop Location), and `EditStopForm` (Stop Location) onto the unified `LocationPicker` standard.
    - Removed redundant manual Autocomplete widgets, separate HTTP callers, and ad-hoc map button listeners across the codebase.
- **Verification**:
  - `flutter pub get` → clean (exit code 0).
  - `flutter analyze` → 0 issues (exit code 0).

---

### `IMP-049` · Member Role Assignment & Security RPC Suite
- **Date**: August 26, 2026
- **Target Files**:
  - [supabase/migrations/018_update_member_roles.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/018_update_member_roles.sql) **[NEW]**
  - [lib/core/repositories/trip_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/trip_repository.dart) **[MODIFIED]**
  - [lib/features/members/members_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/members/members_screen.dart) **[MODIFIED]**
  - [test/core_model_mapping_test.dart](file:///d:/Spencer/Downloads/tara_travel/test/core_model_mapping_test.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Migration 018**:
    - Implemented `public.user_is_trip_organizer(p_trip_id uuid)` with `SECURITY DEFINER` execution context to check trip ownership or approved organizer status without triggering RLS infinite recursion.
    - Implemented `public.update_member_roles(p_trip_id uuid, p_member_uid uuid, p_roles text[])` RPC (`SECURITY DEFINER`):
      - Verifies caller has organizer permissions.
      - Validates assigned role strings against allowed values (`organizer`, `treasurer`, `navigator`, `buyer`, `documenter`, `member`).
      - Atomically updates `trip_members.roles` (defaults to `['member']` if empty).
      - Emits in-app `role_updated` notification to the affected member.
      - Records `member_role_changed` entry in `activity_log`.
    - Extended `trip_members_update` policy to allow `auth.uid() = user_id OR public.user_owns_trip(trip_id) OR public.user_is_trip_organizer(trip_id)`.
  - **Trip Repository**:
    - Updated `updateMemberRoles()` to call `update_member_roles` RPC first, with fallback to direct table update and activity log insertion.
  - **Members Screen State & Permissions**:
    - Guaranteed trip owner has management privileges: `canManageMembers = (currentMember?.canManageMembers ?? false) || isOwner`.
    - Ensured `activeTripProvider` is explicitly invalidated along with `selectedTripProvider` and `allTripsProvider` in `_RoleEditorSheet` and `_BatchRoleEditorSheet` upon successful role updates.
  - **Unit Testing**:
    - Added unit test cases in `test/core_model_mapping_test.dart` verifying multiple roles parsing, `isOrganizer`, `canManageMembers`, `canManageItinerary`, `canApproveExpenses`, and `isTripCreator` permission evaluation.
- **Verification**:
  - `flutter analyze` → 0 issues (exit code 0).

---

### `IMP-050` · Social Graph & Friend Module Overhaul
- **Date**: August 26, 2026
- **Target Files**:
  - [lib/core/models/friend_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/friend_model.dart) **[MODIFIED]**
  - [lib/core/repositories/friend_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/friend_repository.dart) **[MODIFIED]**
  - [lib/core/providers/friend_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/friend_provider.dart) **[MODIFIED]**
  - [lib/features/friends/widgets/friend_list_item.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/widgets/friend_list_item.dart) **[MODIFIED]**
  - [lib/features/friends/friends_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/friends_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Friend Status & Model Enhancements**:
    - Expanded `FriendStatus` enum to include `none`, `pending` (outgoing), `incoming` (inbound), `accepted`, `rejected`, and `blocked`.
    - Added optional `email` field and helper getters for direct social mapping.
  - **Bidirectional Friend Repository Architecture**:
    - Upgraded `FriendRepository.searchUsers()` to query users from `public.users` and cross-reference all existing relationships for the current user in `public.friends`, returning dynamic contextual statuses.
    - Added `lookupUser(query)` for instantaneous user lookup by UUID, display name, or email with live relationship check.
    - Updated `sendRequest()`, `acceptRequest()`, `rejectRequest()`, `cancelRequest()`, and `removeFriend()` for clean, reciprocal consistency in `public.friends`.
  - **Riverpod Provider Suite**:
    - Added `incomingRequestsProvider`, `outgoingRequestsProvider`, `friendRequestsCountProvider` (for badge counters), and `lookupUserProvider`.
  - **Revamped 3-Tab Friends Screen Experience**:
    - **Tab 1 (My Friends)**: Real-time presence indicators, local filtering bar, pull-to-refresh, empty-state onboarding, and a 3-dots friend options bottom sheet (Invite to Trip, Copy ID, Remove Friend).
    - **Tab 2 (Requests)**: Sectioned display for Inbound requests (with one-tap Accept and Decline actions) and Outgoing requests (with Cancel Request action).
    - **Tab 3 (Find Friends)**: Debounced real-time global user search with contextual state buttons (`+ Add`, `Requested`, `Accept`, `Friends ✓`), quick QR code modal launcher, and "Add by ID" dialog featuring a live user preview card before sending requests.
  - **Trip Invitation Integration**:
    - Built trip picker bottom sheet allowing users to directly copy/share active trip invite codes with selected friends.
- **Verification**:
  - `flutter analyze` → 0 issues across entire `lib/` (ran in 9.7s, exit code 0).

---

### `IMP-051` · Real-time Online Presence & Friend Activity Telemetry
- **Date**: August 26, 2026
- **Target Files**:
  - [lib/core/services/user_presence_service.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/services/user_presence_service.dart) **[NEW]**
  - [lib/core/widgets/auth_gate.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/auth_gate.dart) **[MODIFIED]**
  - [lib/core/models/friend_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/friend_model.dart) **[MODIFIED]**
  - [lib/core/providers/friend_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/friend_provider.dart) **[MODIFIED]**
  - [lib/features/friends/widgets/friend_list_item.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/widgets/friend_list_item.dart) **[MODIFIED]**
  - [lib/features/friends/friends_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/friends_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **User Presence Service**:
    - Built `UserPresenceService` with `WidgetsBindingObserver` to track lifecycle transitions.
    - Automatically sets `is_online = true` and `last_seen = now()` on foregrounding/login and marks `is_online = false` on backgrounding/logout.
    - Dispatches heartbeats every 45 seconds to guarantee active session freshness.
  - **Presence Evaluation & Relative Timestamps**:
    - Added `FriendModel.isCurrentlyOnline` checking `isOnline == true` alongside active heartbeat within the last 5 minutes.
    - Added `FriendModel.presenceStatusText` converting `lastSeen` into human-friendly relative activity descriptions (`Active now`, `Active 5m ago`, `Active 2h ago`, `Active yesterday`, `Offline`).
  - **Realtime Presence Streaming**:
    - Created `friendsRealtimePresenceProvider` subscribing to Supabase Realtime changes on `public.users` and `public.friends`.
    - Automatically refreshes the friends roster when any friend transitions between online and offline states.
  - **Interactive Online Friend Filter & Glow Badges**:
    - Added interactive `All Friends` vs `🟢 Online` chip toggles to the header banner in `FriendsScreen`.
    - Added green status dots with ambient glow shadows on online friend avatars and cards.
- **Verification**:
  - `flutter analyze lib/` → 0 issues (ran in 5.4s, exit code 0).

---

### `IMP-052` · Custom Packing Sub-Categories & Filter Tab Engine
- **Date**: August 27, 2026
- **Target Files**:
  - [lib/core/models/packing_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/packing_model.dart) **[MODIFIED]**
  - [lib/core/repositories/packing_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/packing_repository.dart) **[MODIFIED]**
  - [lib/core/providers/packing_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/packing_provider.dart) **[MODIFIED]**
  - [lib/features/packing/packing_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/packing/packing_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Packing Model & Sub-Category Schema**:
    - Added `subCategory` (`String?`) field to `PackingItem` with `copyWith`, `toMap` (`sub_category`), and `fromMap`.
    - Added `PackingCategory.subCategories` getter computing distinct non-empty subcategories across items.
    - Updated `PackingRepository.addItem` to accept `subCategory` and persist `sub_category` column in Supabase `packing_items`.
    - Added `PackingRepository.updateItemSubCategory` and `PackingNotifier.updateItemSubCategory` for remote and local reassignment.
  - **Horizontal Tab / Pill Sub-Category Filtering**:
    - Built a horizontal scrolling pill filter row inside `_PackingCategoryCard` when expanded:
      - **"All"** pill with total category item count.
      - Dynamic custom sub-category pills (e.g. "Breakfast Menu", "Lunch Menu", "Dinner Menu", "Tops", "Swimwear") with live item count badges.
      - **"+ Sub-category"** pill triggering the creation bottom sheet.
    - Selecting a sub-category dynamically filters items and routes newly added items into the selected sub-category automatically.
  - **Curated Preset Suggestions & Quick Input**:
    - Added category-specific sub-category presets (`_kCategorySubCategoryPresets`) for all default categories (`food`, `clothing`, `essentials`, `toiletries`, `gadgets`, `documents`, `medicines`, `others`).
    - Provided modal bottom sheet with one-tap suggestions + custom input field to create sub-categories instantly.
  - **Item Row Tagging & Quick Reassignment**:
    - Added sub-category tag badge chips with category accent styling in `_PackingItemRow`.
    - Tap on badge opens `_showEditItemSubCategorySheet` allowing instantaneous reassignment, removal, or custom creation.
- **Verification**:
  - Full repo `flutter analyze` → 0 issues across entire project (ran in 12.3s, exit code 0).

---

### `IMP-053` · Functional Home Trip Budget Bar & Interactive Budget Management
- **Date**: August 27, 2026
- **Target Files**:
  - [lib/features/home/widgets/quick_budget_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/quick_budget_sheet.dart) **[NEW]**
  - [lib/features/home/widgets/trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/trip_card.dart) **[MODIFIED]**
  - [lib/features/home/widgets/next_trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/next_trip_card.dart) **[MODIFIED]**
  - [lib/features/home/home_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Interactive Budget Bar & Stat Box on TripCard**:
    - Transformed static budget bar and stats cell into responsive, interactive touchpoints.
    - Added `onBudgetTap` (routes directly to `/budget` for the active trip) and `onSetBudget` (opens `QuickBudgetSheet`).
    - Added dynamic multi-stage alert coloring:
      - Normal spend (<70%): App primary gradient with remaining budget summary (`₱X remaining`).
      - Warning spend (70%-90%): Amber gradient and warning alert tint.
      - Danger / Over-budget (>90% or >100%): Red gradient, over-budget badge (`Exceeded by ₱X`), and red tint on budget stat pill.
    - If no budget is configured, renders a clean `+ Set budget` action pill and calls `QuickBudgetSheet.show`.
  - **Quick Budget Editor Modal (`QuickBudgetSheet`)**:
    - Created a modal bottom sheet allowing travelers to configure or adjust a trip's total budget on the fly without navigating away from the homepage.
    - Integrated preset quick chips (`₱5,000`, `₱10,000`, `₱20,000`, `₱50,000`) and live spend summary display.
    - Automatically persists changes through `TripRepository.updateTrip` and invalidates `allTripsProvider`, `activeTripProvider`, and `selectedTripProvider`.
  - **NextTripCard Hero Budget Tracker Integration**:
    - Embedded a compact budget tracker bar within the expanded view of the hero `NextTripCard`.
    - Offers one-tap direct navigation to the Budget Hub or immediate quick budget configuration.
- **Verification**:
  - Verified static analysis with zero errors or warnings.

---

### `IMP-054` · Interactive Next Destination Progress Banner
- **Date**: August 27, 2026
- **Target Files**:
  - [lib/features/itinerary/widgets/itinerary_fulfillment_banner.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/itinerary_fulfillment_banner.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Reverted Hero Subtitle**:
    - Restored the trip destination subtitle in the dark top header back to clean static typography.
  - **Interactive Itinerary Fulfillment Banner**:
    - Converted the entire `ItineraryFulfillmentBanner` (the progress % + "N of N stops visited" card) into a clickable interactive card.
    - When tapped, resolves the next uncompleted stop (`nextStop = day.stops.where((s) => !s.isCompleted).firstOrNull`).
    - Opens Google Maps targeting the exact coordinates (`lat,lng`) or `stop.location` string directly (avoiding custom title mixing), falling back to `stop.title` only if location is absent.
    - Also updated `NavigateRouteButton` (`_formatStopTarget` and `openGoogleMapsForStop`) to use `stop.location` directly for accurate map search resolution.
    - Added an amber navigational CTA badge ("Go" + `near_me_rounded` icon) and interactive border highlight to clearly signal that the banner is active and tappable.
- **Verification**:
  - `flutter analyze lib/` passed with 0 issues.

---

### `IMP-055` · Homepage Header Hero Budget Section Removal
- **Date**: August 27, 2026
- **Target Files**:
  - [lib/features/home/widgets/next_trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/next_trip_card.dart) **[MODIFIED]**
  - [lib/features/home/home_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Header Hero Simplification**:
    - Removed the budget tracker container (progress bar, spend ratio, and quick budget CTA) from the expanded view of [NextTripCard](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/next_trip_card.dart).
    - Cleaned up unused imports in `next_trip_card.dart` (`currency_utils.dart` and `quick_budget_sheet.dart`).
  - **Header Extents & Responsive Spacing Calibration**:
    - Adjusted `NextTripCard` vertical padding (`fromLTRB(18, 14, 18, 16)`) and tightened spacing between elements.
### `IMP-056` · Itinerary Multi-Stop Google Maps Navigation Resolution
- **Date**: August 27, 2026
- **Target Files**:
  - [lib/features/itinerary/widgets/navigate_route_button.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/navigate_route_button.dart) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Multi-Stop Route Construction**:
    - Resolved bug where tapping "Start Route Navigation (N stops)" intercepted the action with a single-point `geo:` URI to the final destination whenever coordinates were present, bypassing all intermediate waypoints.
    - Updated `_navigate()` in `NavigateRouteButton` to directly launch the universal Google Maps directions URI (`https://www.google.com/maps/dir/?api=1&destination=...&waypoints=...&travelmode=driving`).
### `IMP-057` · Advanced Multi-Stop Route Construction & Navigation Engine
- **Date**: August 27, 2026
- **Target Files**:
  - [lib/features/itinerary/widgets/navigate_route_button.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/navigate_route_button.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Smart Target Geocoding (`formatStopTarget`)**:
    - Coordinates (`lat,lng`) prioritized for pinpoint precision.
    - If coordinates are absent, combines `Title` + `Location` (e.g. `"Burnham Park, Baguio City"`) to avoid generic city-only query pins.
  - **GPS Origin Resolution**:
    - Proactively resolves current GPS coordinates with a fast 2-second timeout to populate `origin=lat,lng` for instant turn-by-turn navigation initiation without location delays.
  - **Intelligent Route Scoping**:
    - Automatically filters to remaining uncompleted stops when some stops are already arrived/visited, with one-tap toggle between **Remaining Stops** and **All Stops**.
  - **Dynamic Travel Mode Mapping**:
    - Maps `TransportMode` directly to Google Maps transport modes (`driving`, `two-wheeler`, `walking`, `transit`, `bicycling`).
  - **Interactive Route Options Modal Sheet (`_RouteOptionsSheet`)**:
    - Features a visual timeline waypoint tree (GPS Origin ➔ Intermediate Stops ➔ Destination).
    - Mode chips (🚗 Car, 🏍️ Motorcycle, 🚶 Walking, 🚌 Transit, 🚴 Cycling).
    - "Copy Route Link" button for sharing multi-stop itineraries with group members.
    - Fast quick-launch on the primary button + options button (`tune_rounded`).
- **Verification**:
  - `flutter analyze lib/features/itinerary/` passed with 0 errors / 0 warnings.

### `IMP-058` · Live Camera QR Scanner & Profile User ID Integration
- **Date**: August 28, 2026
- **Target Files**:
  - [pubspec.yaml](file:///d:/Spencer/Downloads/tara_travel/pubspec.yaml) **[MODIFIED]**
  - [lib/core/widgets/scanner/qr_scanner_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/scanner/qr_scanner_modal.dart) **[NEW]**
  - [lib/features/friends/friends_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/friends_screen.dart) **[MODIFIED]**
  - [lib/features/profile/profile_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/profile/profile_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Live Camera QR Scanner (`QrScannerModal`)**:
    - Integrated `mobile_scanner: ^7.4.0` for hardware-accelerated on-device MLKit/AVFoundation camera scanning.
    - Custom brand overlay painter (`_ScannerOverlayPainter`) with Coral (`#D85A30`) corner brackets, dark translucent frame, torch toggle, camera facing switcher, and haptic feedback.
  - **Friends Screen Direct Camera Scanning**:
    - Added `_scanFriendQr` action in Friends screen top bar and Find Friends tab quick action tiles.
    - Added camera scan button directly inside the "Add Friend" dialog TextField suffix alongside paste button.
    - Automatic UUID parsing and instant live profile preview lookup upon scan completion.
  - **Profile Screen User ID & QR Integration**:
    - Added interactive **User ID (Friend Code)** badge chip and **My QR** launch button in the profile header.
    - Added User ID row with one-tap copy and QR launch in the "Personal Info" card.
    - Added standalone `_showMyQrCodeModal` with personalized QR code generation and direct share functionality.
- **Verification**:
  - `flutter analyze` completed across all files with 0 errors and 0 warnings.

---

### `IMP-059` · Hardened Join Trip by Invite Code Workflow & Resilience
- **Date**: August 28, 2026
- **Target Files**:
  - [lib/core/utils/invite_code_generator.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/utils/invite_code_generator.dart) **[MODIFIED]**
  - [lib/core/repositories/trip_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/trip_repository.dart) **[MODIFIED]**
  - [lib/features/trips/widgets/join_trip_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/widgets/join_trip_modal.dart) **[MODIFIED]**
  - [supabase/migrations/019_fix_join_trip_by_code.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/019_fix_join_trip_by_code.sql) **[NEW]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Input Sanitization (`InviteCodeGenerator`)**:
    - Hardened `InviteCodeGenerator.sanitize()` with regex `[^a-zA-Z0-9]` to automatically strip spaces, hyphens, and formatting noise when copying/pasting codes (e.g. `TAR-4BC` -> `TAR4BC`).
    - Extended length validation to support clean codes between 4 and 12 characters.
  - **Foreign Key Safeguard (`TripRepository.joinTripByCode`)**:
    - Added pre-flight check and upsert for `public.users` before executing join logic to ensure new users without pre-existing profile rows never hit foreign key constraint violations on `trip_members` or `activity_log`.
  - **RPC Parsing & Direct Fallback**:
    - Added defensive type checking and JSON decoding for `_supabase.rpc('join_trip_by_code')` responses.
    - Added a robust direct-table fallback path querying `trips` via `ilike` and inserting into `trip_members` if the remote RPC encounters issues.
  - **Migration 019 (`019_fix_join_trip_by_code.sql`)**:
    - Rewrote `join_trip_by_code(text)` to auto-create missing user records, check existing membership state (`already_member`, `already_pending`), handle re-application from `rejected` state, and wrap secondary notification and activity logging in exception blocks.
  - **Reactive Modal UI (`_JoinTripSheet`)**:
    - Migrated `_JoinTripSheet` to `ConsumerStatefulWidget` using Riverpod `ref`.
    - Invalidates both `allTripsProvider` and `activeTripProvider` on join completion.
    - Extended TextField `maxLength` to 12 to prevent clipping formatted pastes.
    - Added contextual SnackBars for already-approved members, pending requests, and new approvals.
- **Verification**:
  - `flutter analyze` completed with 0 issues across all affected files.

---

### `IMP-060` · Standardized & Brand-Unified Feedback System (IDEA-001)
- **Date**: August 28, 2026
- **Target Files**:
  - [lib/core/widgets/feedback/feedback_type.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/feedback_type.dart) **[NEW]**
  - [lib/core/widgets/feedback/app_feedback.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_feedback.dart) **[NEW]**
  - [lib/core/widgets/feedback/app_dialog.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_dialog.dart) **[NEW]**
  - [lib/core/widgets/feedback/app_banner.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_banner.dart) **[NEW]**
  - [lib/core/widgets/feedback/feedback.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/feedback.dart) **[NEW]**
  - [lib/core/theme/app_theme.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_theme.dart) **[MODIFIED]**
  - [lib/features/budget/widgets/alert_banner.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/budget/widgets/alert_banner.dart) **[MODIFIED]**
  - [lib/features/trips/widgets/join_trip_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/widgets/join_trip_modal.dart) **[MODIFIED]**
  - [lib/features/trips/trips_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/trips_screen.dart) **[MODIFIED]**
  - [lib/features/trip_detail/trip_detail_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trip_detail/trip_detail_screen.dart) **[MODIFIED]**
  - [lib/features/trip_detail/widgets/edit_trip_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trip_detail/widgets/edit_trip_sheet.dart) **[MODIFIED]**
  - [lib/features/members/members_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/members/members_screen.dart) **[MODIFIED]**
  - [lib/features/packing/packing_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/packing/packing_screen.dart) **[MODIFIED]**
  - [lib/features/packing/widgets/packing_template_modals.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/packing/widgets/packing_template_modals.dart) **[MODIFIED]**
  - [lib/features/home/widgets/trip_action_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/trip_action_sheet.dart) **[MODIFIED]**
  - [lib/features/home/widgets/quick_budget_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/quick_budget_sheet.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/itinerary_fulfillment_banner.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/itinerary_fulfillment_banner.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/day_actions_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/day_actions_sheet.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/navigate_route_button.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/navigate_route_button.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [lib/features/friends/friends_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/friends_screen.dart) **[MODIFIED]**
  - [lib/features/friends/widgets/friend_list_item.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/widgets/friend_list_item.dart) **[MODIFIED]**
  - [lib/features/profile/profile_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/profile/profile_screen.dart) **[MODIFIED]**
  - [DEV_IDEA.md](file:///d:/Spencer/Downloads/tara_travel/DEV_IDEA.md) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Core Component Infrastructure (`lib/core/widgets/feedback/`)**:
    - `FeedbackType`: Semantic intent enum (`success`, `info`, `warning`, `error`, `destructive`) with unified color/icon mappings.
    - `AppFeedback`: Centralized toast/snackbar helper (`showSuccess`, `showError`, `showWarning`, `showInfo`) rendering floating, rounded (14px radius), haptic-enabled, brand-styled SnackBars.
    - `AppDialog`: Centralized confirmation and alert modal helper (`showConfirmation`, `showDestructive`, `showAlert`) featuring `Playfair Display` titles, `DM Sans` descriptions, 24px border radius, and haptic feedback.
    - `AppBanner`: Inline contextual alert widget with dismissibility, icon branding, and action button support.
  - **Theme Configuration**:
    - Updated `dialogTheme` and `snackBarTheme` in `app_theme.dart` to match Tara Travel design tokens globally.
  - **Comprehensive Codebase Migration**:
    - Eliminated 100% of raw `ScaffoldMessenger.of(context).showSnackBar` and unstyled `AlertDialog` calls across all 11+ feature screens and widgets.
- **Verification**:
  - `flutter analyze` completed with 0 errors and 0 warnings.

---

### `IMP-061` · Streamlined Itinerary Suite & Progressive Disclosure (IDEA-002)
- **Date**: August 28, 2026
- **Target Files**:
  - [lib/features/itinerary/widgets/day_insights_header.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/day_insights_header.dart) **[NEW]**
  - [lib/features/itinerary/widgets/itinerary_action_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/itinerary_action_sheet.dart) **[NEW]**
  - [lib/features/itinerary/widgets/stop_detail_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_detail_sheet.dart) **[NEW]**
  - [lib/features/itinerary/widgets/itinerary_map_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/itinerary_map_sheet.dart) **[NEW]**
  - [lib/features/itinerary/widgets/itinerary_bottom_dock.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/itinerary_bottom_dock.dart) **[NEW]**
  - [lib/features/itinerary/widgets/smart_suggestion_chips.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/smart_suggestion_chips.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/stop_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_card.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [DEV_IDEA.md](file:///d:/Spencer/Downloads/tara_travel/DEV_IDEA.md) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Expandable Day Insights Accordion (`DayInsightsHeader`)**:
    - Consolidates weather forecast, day budget spend/limit, and completion fulfillment progress into a single collapsible card.
    - Slim collapsed pill (`☀️ 29°C · ₱1,400 / ₱5,000 · 3/5 done ▾`) expands smoothly to reveal `ItineraryFulfillmentBanner` (progress ring, squad presence, Google Maps CTA) and `DayBudgetBar`.
  - **Unified Action Hub (`ItineraryActionSheet`)**:
    - Replaced the crowded top horizontal scrolling toolbar with a clean top header and a unified "⋯ More" action sheet.
    - Centralizes Share (`ShareTripModal`), Calendar export (`Add2Calendar`), Day Map preview (`ItineraryMapSheet`), and Day Management (Schedule shifting $-60/-30/+30/+60\text{m}$, move stop to another day, duplicate day, clear stops, and delete day).
  - **Floating Action Dock (`ItineraryBottomDock`)**:
    - Integrated a glassmorphic floating bottom bar containing 1-tap route navigation & map overview alongside the primary coral `+ Add Stop` button.
  - **Automated GPS Arrival Geofencing Engine**:
    - Actively listens to `LocationTrackingService.instance.snapshotStream` when itinerary view is open.
    - Computes distance against uncompleted stops with coordinates; automatically displays `ArrivalPill` when traveler arrives within $150\text{m}$ geofence.
    - Tracks dismissed stop IDs in state (`_dismissedStopIds`) for session-level suppression.
  - **Screen Modularization**:
    - Extracted `StopDetailSheet` and `ItineraryMapSheet` into dedicated widgets.
    - Refactored `itinerary_screen.dart` into a modular, clean controller under 400 lines while preserving 100% of existing functionality.
- **Verification**:
  - `flutter analyze` passed with 0 errors across all affected files.

---

### `IMP-062` · Real-Time Group Live Location Sharing, Convoy Tracking & Direct Member Navigation (IDEA-003)
- **Date**: August 28, 2026
- **Target Files**:
  - [lib/core/services/location_broadcast_service.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/services/location_broadcast_service.dart) **[NEW]**
  - [lib/features/navigation/models/navigation_models.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/models/navigation_models.dart) **[MODIFIED]**
  - [lib/features/navigation/providers/navigation_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/providers/navigation_provider.dart) **[MODIFIED]**
  - [lib/features/navigation/widgets/navigate_to_member_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/navigate_to_member_sheet.dart) **[NEW]**
  - [lib/features/navigation/widgets/convoy_alert_banner.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/convoy_alert_banner.dart) **[NEW]**
  - [lib/features/navigation/widgets/sos_emergency_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/sos_emergency_modal.dart) **[NEW]**
  - [lib/features/navigation/widgets/privacy_control_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/privacy_control_sheet.dart) **[NEW]**
  - [lib/features/navigation/widgets/live_map_tab.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/live_map_tab.dart) **[MODIFIED]**
  - [lib/features/navigation/widgets/group_tracker_tab.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/group_tracker_tab.dart) **[MODIFIED]**
  - [lib/features/navigation/live_navigation_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/live_navigation_screen.dart) **[MODIFIED]**
  - [DEV_IDEA.md](file:///d:/Spencer/Downloads/tara_travel/DEV_IDEA.md) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Zero-Latency Ephemeral Broadcast Service (`LocationBroadcastService`)**:
    - Leverages Supabase Realtime broadcast channels (`trip:location:{trip_id}`) for $<150\text{ms}$ peer location streaming without database disk I/O bottlenecks.
    - Speed-adaptive GPS sampling engine: Stationary ($60\text{s} / 25\text{m}$), Walking ($15\text{s} / 10\text{m}$), Driving/Transit ($5\text{s} / 30\text{m}$) plus a low-power Battery Saver mode ($60\text{s} / 50\text{m}$).
    - Periodic PostGIS background checkpointing ($45\text{s}$ interval) to `update_member_location` RPC for offline recovery and session persistence.
  - **Direct "Navigate to Member" / Member-as-Waypoint Routing (`NavigateToMemberSheet`)**:
    - 1-tap navigation to separated companions from `GroupTrackerTab` and `LiveMapTab`.
    - Supports in-app dynamic waypoint routing (`_DirectMemberRoutePin`, heading cone, distance delta) and deep linking to external turn-by-turn navigation apps (Google Maps, Apple Maps, Waze via `geo:` and universal URL schemes).
    - Intelligent "Meet Halfway" midpoint calculator calculating exact geographic bisector coordinates between companions with interactive map pins.
  - **Convoy Intelligence & Separation Radar (`ConvoyAlertBanner`)**:
    - Automated convoy perimeter monitoring alerting companions when a traveler drifts $>2.0\text{km}$ behind with estimated delay times, quick locate action, and dismissible state.
  - **Emergency Panic Beacon & Haptic SOS Engine (`SosEmergencyModal` & `ActiveSosAlertBanner`)**:
    - High-priority real-time SOS broadcast with exact coordinates, timestamp, custom distress note, and remaining battery percentage.
    - Red pulsating top alert banner with 1-tap Google Maps directions to distressed member.
  - **Privacy & Local-First Battery Controls (`PrivacyControlSheet`)**:
    - Three-tier privacy governance: *Exact Location*, *Approximate Neighborhood* ($\approx 500\text{m}$ fuzzy bubble), and *Ghost Mode* (complete broadcast pause with custom 30m/1h/2h/end-of-day countdown timers).
    - Top bar quick-toggle buttons for SOS and Privacy controls in `LiveNavigationScreen`.
- **Verification**:
---

### `IMP-063` · Real Supabase Data & OpenStreetMap (flutter_map) Live Navigation
- **Date**: August 30, 2026
- **Target Files**:
  - [lib/core/services/location_broadcast_service.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/services/location_broadcast_service.dart) **[MODIFIED]**
  - [lib/features/navigation/models/navigation_models.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/models/navigation_models.dart) **[MODIFIED]**
  - [lib/features/navigation/providers/navigation_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/providers/navigation_provider.dart) **[MODIFIED]**
  - [lib/features/navigation/widgets/live_map_tab.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/live_map_tab.dart) **[MODIFIED]**
  - [lib/features/navigation/widgets/group_tracker_tab.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/group_tracker_tab.dart) **[MODIFIED]**
  - [lib/features/home/widgets/next_trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/next_trip_card.dart) **[MODIFIED]**
  - [lib/features/home/widgets/trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/trip_card.dart) **[MODIFIED]**
  - [lib/features/home/widgets/trip_action_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/trip_action_sheet.dart) **[MODIFIED]**
  - [lib/features/home/home_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Real Database & Realtime Telemetry Sync**:
    - `LocationBroadcastService.hydratePeersFromSupabase`: Hydrates initial member locations directly from Supabase `member_locations` table (`trip_id`).
    - Connected dynamic `trip.members` roster to `NavigationNotifier`, respecting user surname privacy rules (`hideSurname`).
    - Wired device GPS stream (`myGpsStream`) to keep traveler position, speed, and heading synchronized in real-time.
  - **Full Interactive Map Engine via `flutter_map`**:
    - Replaced mock canvas painters in `LiveMapTab` and `GroupTrackerTab` with interactive `FlutterMap` instances utilizing CartoDB Voyager and OpenStreetMap tiles.
    - Integrated real `MarkerLayer` with dynamic compass heading cones, pulsating user beacons, real companion pins (with tap-to-navigate sheet triggers), destination flags, and SOS emergency radar markers.
    - Integrated real `PolylineLayer` showing the live path from current user location to active destination or companion waypoint.
    - Added on-map floating controls for **Center My GPS** (`_centerOnMe`), **Fit Group Bounds** (`_fitGroupBounds`), and **Zoom In / Out**.
  - **Ubiquitous 1-Tap Entry Points**:
    - Added "🧭 Live Nav" quick CTA buttons and callbacks to `NextTripCard` (homepage hero), `TripCard` (trip list cards), and `TripActionSheet` (bottom sheet options).
- **Verification**:
  - `flutter analyze` completed with **0 errors, 0 warnings, 0 infos** across entire repository.

---

### `IMP-064` · Mapbox API Key Activation & MapTileConfig Layer
- **Date**: August 30, 2026
- **Target Files**:
  - [.env](file:///d:/Spencer/Downloads/tara_travel/.env) **[MODIFIED]**
  - [lib/core/constants/map_tile_config.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/constants/map_tile_config.dart) **[NEW]**
  - [lib/features/navigation/widgets/live_map_tab.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/live_map_tab.dart) **[MODIFIED]**
  - [lib/features/navigation/widgets/group_tracker_tab.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/group_tracker_tab.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/itinerary_map.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/itinerary_map.dart) **[MODIFIED]**
  - [lib/core/widgets/inputs/map_pin_picker_modal.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/map_pin_picker_modal.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - Activated user Mapbox Public Access Token (`MAPBOX_ACCESS_TOKEN`) in `.env`.
  - Built unified [`MapTileConfig`](file:///d:/Spencer/Downloads/tara_travel/lib/core/constants/map_tile_config.dart) provider supporting Mapbox Streets HD (`mapbox/streets-v12`) with automatic fallback to CartoDB Voyager.
  - Upgraded all map surfaces across the app (`LiveMapTab`, `GroupTrackerTab`, `ItineraryMap`, `MapPinPickerModal`) to consume `MapTileConfig.buildTileLayer()`.
- **Verification**:
  - `flutter analyze lib/` completed with **0 issues found**.

---

### `IMP-065` · Consolidate Trip Theme & Drop Redundant Cover Fields
- **Date**: August 31, 2026
- **Target Files**:
  - [supabase/migrations/020_consolidate_trip_theme_fields.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/020_consolidate_trip_theme_fields.sql) **[NEW]**
  - [supabase/migrations/000_master_schema.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/000_master_schema.sql) **[MODIFIED]**
  - [lib/core/models/trip_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/trip_model.dart) **[MODIFIED]**
  - [lib/core/repositories/trip_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/trip_repository.dart) **[MODIFIED]**
  - [lib/features/create_trip/models/new_trip_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/create_trip/models/new_trip_model.dart) **[MODIFIED]**
  - [lib/features/create_trip/create_trip_flow.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/create_trip/create_trip_flow.dart) **[MODIFIED]**
  - [lib/features/create_trip/steps/details_step.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/create_trip/steps/details_step.dart) **[MODIFIED]**
  - [lib/features/create_trip/steps/confirm_step.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/create_trip/steps/confirm_step.dart) **[MODIFIED]**
  - [lib/features/create_trip/widgets/trip_creation_loading_overlay.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/create_trip/widgets/trip_creation_loading_overlay.dart) **[MODIFIED]**
  - [lib/features/trip_detail/widgets/edit_trip_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trip_detail/widgets/edit_trip_sheet.dart) **[MODIFIED]**
  - [lib/features/trip_detail/trip_detail_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trip_detail/trip_detail_screen.dart) **[MODIFIED]**
  - [lib/features/home/widgets/trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/trip_card.dart) **[MODIFIED]**
  - [lib/features/home/widgets/next_trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/next_trip_card.dart) **[MODIFIED]**
  - [lib/features/home/widgets/quick_budget_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/quick_budget_sheet.dart) **[MODIFIED]**
  - [lib/features/home/widgets/starter_templates_carousel.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/starter_templates_carousel.dart) **[MODIFIED]**
  - [lib/features/home/widgets/trip_action_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/trip_action_sheet.dart) **[MODIFIED]**
  - [lib/features/trips/trips_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trips/trips_screen.dart) **[MODIFIED]**
  - [lib/features/home/home_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart) **[MODIFIED]**
  - [MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/MEMORY.md) **[MODIFIED]**
  - [.agents/rules/architecture-memory.md](file:///d:/Spencer/Downloads/tara_travel/.agents/rules/architecture-memory.md) **[MODIFIED]**
  - [IMPLEMENTATION_MEMORY.md](file:///d:/Spencer/Downloads/tara_travel/IMPLEMENTATION_MEMORY.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Single Source of Truth Consolidation**:
    - Unified trip type, theme accent color, and emoji under the canonical `tripType` property and [`AppTripTypes`](file:///d:/Spencer/Downloads/tara_travel/lib/core/constants/trip_types.dart) registry.
    - Updated `TripModel` to resolve `coverEmoji` (`AppTripTypes.getEmoji(tripType)`), `coverColor` (`AppTripTypes.getColor(tripType)`), and `tripTypeOption` dynamically without storing redundant strings.
  - **Database Migration & Schema Cleanup**:
    - Created migration `020_consolidate_trip_theme_fields.sql` to permanently drop redundant `cover_color` and `cover_emoji` columns from `public.trips`.
    - Cleaned up master schema and updated hallucination blacklists in architectural memory.
  - **Creation & Edit Flows Streamlined**:
    - Simplified `DetailsStep`, `EditTripSheet`, `CreateTripFlow`, `StarterTemplatesCarousel`, and `TripCreationLoadingOverlay` to remove manual color/emoji conversions and ARGB string serializations.
  - **UI Standardized**:
    - Streamlined `TripCard`, `NextTripCard`, `TripDetailScreen`, `TripsScreen`, `QuickBudgetSheet`, and `TripActionSheet` to consume unified `trip.coverColor` and `trip.coverEmoji` getters cleanly.
- **Verification**:
  - `flutter analyze` verified 0 compilation errors across the workspace.

---

### `IMP-066` · Shared TripTypeCarousel & Full-Spectrum Trip Types Support
- **Date**: August 31, 2026
- **Target Files**:
  - [lib/shared/widgets/trip_type_carousel.dart](file:///d:/Spencer/Downloads/tara_travel/lib/shared/widgets/trip_type_carousel.dart) **[NEW]**
  - [lib/features/create_trip/steps/details_step.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/create_trip/steps/details_step.dart) **[MODIFIED]**
  - [lib/features/trip_detail/widgets/edit_trip_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trip_detail/widgets/edit_trip_sheet.dart) **[MODIFIED]**
  - [lib/core/models/trip_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/trip_model.dart) **[MODIFIED]**
  - [lib/core/repositories/trip_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/trip_repository.dart) **[MODIFIED]**
  - [supabase/migrations/020_consolidate_trip_theme_fields.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/020_consolidate_trip_theme_fields.sql) **[MODIFIED]**
  - [supabase/migrations/000_master_schema.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/000_master_schema.sql) **[MODIFIED]**
- **Scope & Objectives**:
  - **Shared UI Component (DRY Principle)**:
    - Extracted the infinite-scroll card carousel from `details_step.dart` into a reusable, standalone [`TripTypeCarousel`](file:///d:/Spencer/Downloads/tara_travel/lib/shared/widgets/trip_type_carousel.dart) widget.
    - Integrated `TripTypeCarousel` into both `DetailsStep` (Create Trip) and `EditTripSheet` (Edit Trip), eliminating ~400 lines of duplicated carousel code.
  - **Full-Spectrum Trip Type Precision**:
### `IMP-067` · Auth Onboarding Bypass & Account State Guard
- **Date**: August 31, 2026
- **Files Modified**:
  - [lib/core/providers/profile_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/profile_provider.dart) **[MODIFIED]**
  - [lib/core/widgets/auth_gate.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/auth_gate.dart) **[MODIFIED]**
  - [lib/features/onboarding/onboarding_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/onboarding/onboarding_screen.dart) **[MODIFIED]**
- **Scope & Objectives**:
  - **Account Completeness Guard (`isAccountFullySet`)**: Added `isAccountFullySet` getter on `ProfileState` to check whether onboarding is flagged completed or if fundamental profile attributes (`homeCity` or configured `displayName`/`firstName`) are already present.
  - **Auto-Recovery on Hydration**: Updated `ProfileNotifier._loadProfile()` to automatically detect existing user accounts and normalize `hasCompletedOnboarding: true` during remote profile hydration, preventing false-negative onboarding redirection.
  - **AuthGate Robust Destination Routing**: Routed authenticated users using `profile.isAccountFullySet ? '/home' : '/onboarding'`.
  - **OnboardingScreen Post-Frame Interceptor**: Added early bypass check in `OnboardingScreen.didChangeDependencies()` to immediately transition authenticated existing users directly to `/home`.
- **Verification**:
  - `dart analyze lib/` passed with 0 errors and 0 warnings.

---

### `IMP-068` · Ultra-Simplified Stop Cards & Unified Presence Hub (IDEA-007)
- **Date**: August 31, 2026
- **Files Modified / Deleted**:
  - [lib/features/itinerary/widgets/stop_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_card.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/stop_detail_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_detail_sheet.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/roll_call_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/roll_call_sheet.dart) **[DELETED]**
- **Scope & Objectives**:
  - **Ultra-Simplified `StopCard`**:
    - Stripped competing and redundant action buttons (Check-In button, Roll Call pill button, Expense shortcut chip, Edit button) from the card surface.
    - Set single prominent CTA: `[ 🧭 Navigate ]` which launches Google Maps route navigation.
    - Cleaned up presence info to display a subtle read-only avatar stack and count (`3/5 present`) when companions have arrived.
  - **`StopDetailSheet` Presence & Action Hub Overhaul**:
    - Re-positioned `[ ✏️ Edit ]` button and dismiss `[ ✕ ]` to the top-right header.
    - Implemented Canonical "Mark as Arrived" hero button with reactive state (`[ 📍 Mark as Arrived (You) ]` / `[ ✓ You Arrived at ... · Tap to Undo ]`).
    - Added dedicated expandable "Members (X/Y Arrived)" presence card with companion avatar stack preview.
    - Created inline interactive `_MemberArrivalRoster` with per-member status indicators (`✓ Arrived` vs `⏳ Not yet arrived`), 1-tap toggles, formatted privacy-safe names, and batch `"Mark Everyone as Arrived"` button.
  - **Terminology Standardization**:
    - Completely retired legacy "Roll Call" terminology across all widgets, tooltips, and action handlers in favor of "Members" and "Mark as Arrived".
  - **Clean Code & Deprecation**:
    - Permanently removed obsolete standalone `roll_call_sheet.dart`.
- **Verification**:
  - `dart analyze lib/` passed with 0 errors and 0 warnings.
  - `flutter analyze` completed with 0 errors and 0 warnings.

---

### `IMP-069` · Retirement of Stop Votes & Legacy Status Lifecycle
- **Date**: September 1, 2026
- **Files Modified / Created**:
  - [supabase/migrations/021_drop_stop_votes_and_stop_status.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/021_drop_stop_votes_and_stop_status.sql) **[NEW]**
  - [supabase/migrations/000_master_schema.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/000_master_schema.sql) **[MODIFIED]**
  - [lib/core/models/itinerary_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/itinerary_model.dart) **[MODIFIED]**
  - [lib/core/repositories/itinerary_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/itinerary_repository.dart) **[MODIFIED]**
  - [lib/core/providers/itinerary_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/itinerary_provider.dart) **[MODIFIED]**
  - [lib/core/providers/realtime_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/realtime_provider.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/stop_detail_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_detail_sheet.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/stop_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_card.dart) **[MODIFIED]**
  - [lib/features/itinerary/itinerary_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/itinerary_screen.dart) **[MODIFIED]**
- **Scope & Objectives**:
  - **Database & Schema Deprecation**:
    - Created migration `021_drop_stop_votes_and_stop_status.sql` permanently dropping `public.stop_votes` table (cascade) and dropping `status` column from `public.itinerary_stops`.
    - Synchronized `000_master_schema.sql` by dropping `stop_votes` table, policies, indexes, and realtime publication.
  - **Domain Model Streamlining**:
    - Dropped `StopStatus` enum and `StopStatusX` extension.
    - Removed `status` and `votes` (and `voteScore`) fields from `ItineraryStop`.
    - Streamlined `isCompleted` getter to check `visitedAt != null || checkedInMemberIds.isNotEmpty`.
    - Streamlined `completedStops` on `ItineraryDay` to count `stops.where((s) => s.isCompleted).length`.
  - **Repository & State Layer Cleanup**:
    - Removed `updateStopStatus()`, `voteOnStop()`, `removeVote()`, `_fromDbStatus()`, and `_toDbStatus()` from `ItineraryRepository`.
    - Removed `updateStopStatus()`, `voteOnStop()` from `ItineraryNotifier`.
    - Removed `stopVotesRealtimeProvider` from `realtime_provider.dart`.
  - **UI Simplification**:
    - Removed `Group Vote` thumbs up/down voting row and vote score pill from `StopDetailSheet`.
    - Removed bottom status bar (`Approve` and `Mark Done` buttons) from `StopDetailSheet`.
    - Removed status badge renderer and references in `StopCard`.
- **Verification**:
  - `dart analyze lib/` completed with 0 errors and 0 warnings.
  - Verification confirmed zero remaining references to `StopStatus` or `stop_votes` across the entire project.

---

### `IMP-070` · Driver-Ready Slide to Confirm Arrival, Per-Member Arrival Timestamps & Full Supabase Persistence
- **Date**: September 1, 2026
- **Files Modified / Created**:
  - [supabase/migrations/022_add_arrival_tracking.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/022_add_arrival_tracking.sql) **[NEW]**
  - [supabase/migrations/000_master_schema.sql](file:///d:/Spencer/Downloads/tara_travel/supabase/migrations/000_master_schema.sql) **[MODIFIED]**
  - [lib/core/models/itinerary_model.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/models/itinerary_model.dart) **[MODIFIED]**
  - [lib/core/repositories/itinerary_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/itinerary_repository.dart) **[MODIFIED]**
  - [lib/core/providers/itinerary_provider.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/providers/itinerary_provider.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/slide_to_arrive_button.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/slide_to_arrive_button.dart) **[NEW]**
  - [lib/features/itinerary/widgets/stop_detail_sheet.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_detail_sheet.dart) **[MODIFIED]**
- **Scope & Objectives**:
  - **Database & Schema Updates**:
    - Created migration `022_add_arrival_tracking.sql` adding `visited_at` (`timestamptz`) and `checked_in_data` (`jsonb` map of `{userId: ISO_timestamp}`).
    - Updated `000_master_schema.sql` accordingly.
  - **Full Supabase Persistence & Mappers**:
    - Updated `ItineraryRepository.saveItineraryDay()` to serialize `visited_at` and `checked_in_data`.
    - Updated `_stopFromSupabaseRow()` with `_encodeCheckedInData()` and `_decodeCheckedInData()` helpers.
  - **Model & Provider Enhancements**:
    - Refactored `ItineraryStop` to store `Map<String, DateTime> checkedInMembers` for individual arrival timestamps.
    - Added `memberArrivedAtLabel(memberId)` for formatted per-member arrival times (e.g. `3:45 PM`).
    - Added `clearVisitedAt` flag to `copyWith` to reliably null out timestamps on undo.
    - Updated `toggleStopVisited()`, `checkInMember()`, and `updateCheckedInMembers()` to persist immediately to Supabase on arrival and undo.
  - **UI & Driver-Ready Bottom Dock**:
    - Added `SlideToArriveButton` in a fixed bottom dock of `StopDetailSheet`.
    - Displayed arrival time in Metadata Info rows when arrived (`✓ Arrived 3:45 PM (Stop Completed)`).
    - Displayed per-member arrival times in the companion roster (`✓ Arrived 3:45 PM`).
    - Added responsive `[ Undo ]` buttons on both the bottom dock and per-member items.
    - Integrated floating 6-second post-arrival confirmation banner on the main itinerary screen with an instant `[ Undo ]` action button.
- **Verification**:
  - `dart analyze lib/` completed with 0 errors and 0 warnings.

---

### `IMP-071` · Relocating Live Nav to Itinerary Floating Dock & Driver Navigation Optimization
- **Date**: September 1, 2026
- **Files Modified**:
  - [lib/features/home/widgets/next_trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/next_trip_card.dart) **[MODIFIED]**
  - [lib/features/home/widgets/trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/trip_card.dart) **[MODIFIED]**
  - [lib/features/itinerary/widgets/itinerary_bottom_dock.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/itinerary_bottom_dock.dart) **[MODIFIED]**
  - [lib/features/navigation/widgets/live_map_tab.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/navigation/widgets/live_map_tab.dart) **[MODIFIED]**
  - [DEV_IDEA.md](file:///d:/Spencer/Downloads/tara_travel/DEV_IDEA.md) **[MODIFIED]**
- **Scope & Objectives**:
  - **Home Screen Surface Decluttering**:
    - Removed `Live Nav` badge button from the top header row of `NextTripCard`.
    - Removed `Live Nav` action button from `TripCard` bottom action bar, balancing spacing for `Itinerary`, `Packing`, `Members`, `Expenses`, and `Chat`.
  - **Itinerary Floating Dock Redesign**:
    - Replaced the 2-button layout in `ItineraryBottomDock` with a 3-button tri-action bar:
      - Primary Hero Action: `[ 🧭 Live Nav ]` (Gradient coral button with medium impact haptics, opening in-app live navigation).
      - Secondary Action: `[ 🗺️ Day Map ]` (Frosted pill opening interactive route sheet).
      - Tertiary Action: `[ ＋ Stop ]` (Quick modal trigger for itinerary managers).
  - **Driver-Focused Navigation HUD**:
    - Added direct 1-tap **"Launch Google Maps Turn-by-Turn"** (`google.navigation:q=lat,lng&mode=d`) external handoff to `_TurnCard` in `LiveMapTab`.
    - Enhanced `_BottomStrip` with higher contrast `[ Exit Nav ]` button for ease of operation.
- **Verification**:
  - `dart analyze lib/` passed with 0 errors and 0 warnings.

---

### `IMP-072` · Trip Card & Trip Detail Date Abbreviation, Itinerary Stops Box & Budget Bar Decluttering
- **Date**: September 1, 2026
- **Files Modified**:
  - [lib/features/home/widgets/trip_card.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/trip_card.dart) **[MODIFIED]**
  - [lib/features/home/home_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart) **[MODIFIED]**
  - [lib/features/trip_detail/trip_detail_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/trip_detail/trip_detail_screen.dart) **[MODIFIED]**
- **Scope & Objectives**:
  - **Date Abbreviations**:
    - Converted home screen trip card and trip detail hero dates to use 3-letter month abbreviations (e.g. `Oct 12–15, 2026` or `Oct 28 – Nov 2, 2026`).
  - **Three Stat Boxes (DAYS/NIGHTS | ITINERARY | PEOPLE)**:
    - Replaced the redundant middle `BUDGET` stat box on both Home Trip Cards and Trip Detail Screen with an `ITINERARY` box displaying `${visitedStops}/${totalStops}` progress (e.g. `2/8` or `0/5`).
    - Configured the box as a clean informational box.
  - **Standalone Budget Bar**:
    - Converted the home card budget summary into a clean, informational progress bar.
    - Removed direct link/tap interaction on the home tracker bar and removed `"Manage >"`.
- **Verification**:
  - `flutter analyze lib/features/home/widgets/trip_card.dart lib/features/home/home_screen.dart lib/features/trip_detail/trip_detail_screen.dart` passed with 0 issues.

---

### Milestone: `IMP-073` — UI & Itinerary: Driver-Ready Touch Targets & Enriched Buttons
- **Date**: 2026-09-01
- **Status**: Production Verified
- **Components**: `lib/features/itinerary/widgets/stop_card.dart`, `lib/features/itinerary/widgets/stop_detail_sheet.dart`, `lib/features/itinerary/widgets/navigate_route_button.dart`, `lib/features/itinerary/widgets/itinerary_bottom_dock.dart`, `lib/features/itinerary/widgets/slide_to_arrive_button.dart`, `lib/features/itinerary/widgets/day_strip.dart`, `lib/features/itinerary/widgets/arrival_pill.dart`, `lib/features/itinerary/widgets/timeline_view.dart`
- **Architectural Rationale & Implementation Details**:
  - **StopCard Navigate Action Button**:
    - Replaced the subtle low-contrast `10x5` pill with a prominent, high-contrast, driver-ready solid primary button (`14x8` padding, size 16 icon, font 12.5 bold) with soft shadow and `HapticFeedback.lightImpact()`.
  - **StopDetailSheet Driver Actions**:
    - Scaled `Navigate Maps` primary button height from 46 to `54` with size 22 icon and 14.5 bold typography.
    - Scaled `Expense` action button height from 46 to `54` with size 19 icon and 13.5 bold typography.
    - Scaled top-right `Edit` header button to a generous `14x9` touch area with size 15 icon and 13 bold text.
    - Upgraded `SlideToArriveButton` default height to `60` with a 52px knob and size 24 vehicle icon.
    - Enriched Arrived Driver Status bar with height `62`, size 36 circle check, and a roomy `14x8` Undo button.
    - Scaled companion arrival toggles ("Mark Arrived" / "Undo") to `13x8` with size 15 icons and 12 bold text, and "Mark Everyone as Arrived" button to height `48`.
  - **NavigateRouteButton & Route Modal**:
    - Increased main multi-stop navigation button height from 52 to `58` with size 24 icon and 14.5 bold typography.
    - Expanded tune options button hit area to a minimum `44x44` touch target.
### `IMP-074` · 2026-09-02 · UI & Home / Quick-Action Red Notification Dot Indicator (IDEA-010)
- **Problem**:
  - The 5 quick action buttons on the home trip card (`Itinerary`, `Packing`, `Members`, `Expenses`, `Chat`) were static and did not provide visual change awareness when co-travelers added new stops, updated packing items, joined the trip, logged expenses, or sent unread messages.
- **Solution**:
  - Implemented **IDEA-010**: Lightweight, contextual **Red Notification Dot Indicator (`🔴`)** anchored to the top-right of each action button container.
  - Built `ModuleViewTrackerService` utilizing Android Keystore / iOS Keychain `FlutterSecureStorage` with in-memory sync cache for $O(1)$ timestamp diffing.
  - Implemented `tripQuickActionChangesProvider` which subscribes to real-time streams and queries `created_at` / `updated_at` timestamps against local `last_viewed:{module}:{tripId}` records.
  - Built **Self-Action Exemption**: modifications authored by the current logged-in user (`user_id == currentUserId` or `paid_by_user_id == currentUserId`) are filtered out so users do not see notifications for their own edits.
  - Integrated auto-dismissal on quick action tap and on-screen entry across all 5 destination screens (`ItineraryScreen`, `PackingScreen`, `MembersScreen`, `BudgetScreen`, `ChatScreen`).
- **Modified / Created Files**:
  - `lib/core/services/module_view_tracker_service.dart` [NEW]
  - `lib/features/home/models/trip_card_badge_data.dart` [NEW]
  - `lib/core/providers/trip_action_changes_provider.dart` [NEW]
  - `lib/features/home/widgets/trip_card.dart`
  - `lib/features/home/home_screen.dart`
  - `lib/features/itinerary/itinerary_screen.dart`
  - `lib/features/packing/packing_screen.dart`
  - `lib/features/members/members_screen.dart`
  - `lib/features/budget/budget_screen.dart`
  - `lib/features/chat/chat_screen.dart`
- **Verification**:
  - `dart analyze` and `flutter analyze` completed cleanly with zero warnings or errors.

---

### `IMP-075` · 2026-09-02 · Core & Services / Real-Time Live Weather Forecast & Severe Condition Alerts Engine (IDEA-013)
- **Problem**:
  - Trip weather forecasts in `trip_weather_provider.dart` returned static mock values (`WeatherData.mock()`), lacking live meteorological data, rainfall probabilities, UV index, and severe weather warnings for Philippine destinations.
- **Solution**:
  - Implemented **IDEA-013**: Elite, high-accuracy real-time `WeatherService` with dual-engine failover:
    1. **Primary High-Resolution Numerical Forecasts & Rain Engine**: Open-Meteo API (14-16 day multi-day forecast, ECMWF/GFS meteorological models, hourly/daily precipitation probability %, max/min temperatures, wind speed, UV index, WMO interpretation code translation, zero rate-limit friction).
    2. **Secondary Real-Time Station Telemetry**: OpenWeatherMap API (metric units, real-time live station conditions, 5-day / 3-hour forecasts with configured API key in `.env`).
    3. **Philippine Travel Hub Geocoder**: Instant $O(1)$ coordinate resolution for top travel hubs (Manila, Boracay, El Nido, Coron, Siargao, Cebu, Baguio, Bohol, Panglao, Batanes, Davao, Tagaytay, Puerto Princesa, La Union, Sagada, Iloilo, etc.) with automatic Open-Meteo geocoding fallback.
    4. **In-Memory & Local Cache Layer (3-Hour TTL)**: Caches weather responses to guarantee instant sub-millisecond loads on tab switching and resilient offline fallback during island/mountain travel.
  - Refactored `trip_weather_provider.dart` to provide `weatherServiceProvider`, `tripWeatherProvider` (family for trip-aligned day forecasts), and `tripCurrentWeatherProvider` (live station conditions).
### `IMP-076` · 2026-09-02 · Core & UI / 3-Layer Trip Schedule Conflict Management & Interactive Trip-Aware Calendar Picker
- **Problem**:
  - Travelers had no visual indication when multiple trips had overlapping dates on the Home Screen.
  - When creating or editing a trip, users could not see other scheduled trips on the calendar picker, risking accidental double-booking.
  - Lack of proactive conflict alerts allowed date overlaps without user awareness.
- **Solution**:
  - Implemented the **3-Layer Schedule Conflict Management Architecture**:
    1. **Layer 1: Home Screen Overlap Badging & Grouping**:
       - Built `TripConflictHelper` to detect interval intersections ($O(N)$ interval scan) between active trips.
       - Added amber overlap pill badges (`⚠️ Overlaps: [Trip Name]`) on both `TripCard.upcoming` and `TripCard.draft`.
       - Integrated conflict resolution in `home_screen.dart` via `_HomeTripCardItem`.
    2. **Layer 2: Interactive Trip-Aware Calendar Picker (`TaraDateRangePickerSheet`)**:
       - Custom brand-aligned modal bottom sheet (`Playfair Display`, `DM Sans`, `AppColors.primary`, `AppColors.amber`).
       - Highlights existing scheduled trip dates with soft amber dot badges ($\bullet$).
       - Prohibits picking past dates by enforcing `widget.firstDate` boundary (`DateTime.now()` normalized to midnight) and graying out previous days with `onTap: null`.
       - Renders live collision detection banner below calendar detailing conflicting trip names and date ranges.
       - Integrated into `DetailsStep` (Create Trip), `EditTripSheet` (Trip Detail), and `AppDatePicker`.
       - Added `JitGuard.checkDateOverlapGuard` confirmation dialog for creation/edit flows.
    3. **Layer 3: Itinerary Inter-Stop Collision Engine**:
       - Maintained and integrated with existing `TransitConflictHelper` and `InterStopTransitBadge` for stop-level tight buffers and direct overlaps.
- **Modified / Created Files**:
  - `lib/core/utils/trip_conflict_helper.dart` [NEW]
  - `lib/core/widgets/inputs/tara_date_range_picker.dart` [NEW]
  - `lib/core/utils/jit_guard.dart` [MODIFIED]
  - `lib/features/home/widgets/trip_card.dart` [MODIFIED]
  - `lib/features/home/home_screen.dart` [MODIFIED]
  - `lib/features/create_trip/steps/details_step.dart` [MODIFIED]
  - `lib/features/trip_detail/widgets/edit_trip_sheet.dart` [MODIFIED]
  - `lib/core/widgets/inputs/app_date_picker.dart` [MODIFIED]
- **Verification**:
  - `flutter analyze` completed with 0 errors/warnings.

---

### `IMP-075` · Itinerary Stop Detail Sheet: Real-Time ETA, Travel Time & Real Distance Engine
- **Date**: September 2, 2026
- **Scope & Objectives**:
  1. **Real-Time Estimated Time of Arrival (Live GPS ETA, Real Distance & Travel Time)**:
     - Implemented `_fetchLiveGpsForEta()` in `StopDetailSheet` using `Geolocator.getCurrentPosition(medium accuracy, 3s timeout)`.
     - Integrated `TransitConflictHelper.analyze` to dynamically compute geodesic distance and transit duration based on stop transport mode speed (`averageSpeedKmh`).
     - Added enhanced ETA card featuring:
       - Top row: Arrival clock (`"8:45 AM"`) with green `LIVE GPS` badge indicator.
       - Metrics grid: Dedicated **Real Distance** badge (`"3.2 km"` / `"850 meters"`) and **Estimated Travel Time** badge (`"18 mins"` / `"1h 15m"`).
       - Context label indicating calculation origin (live GPS position vs. predecessor stop).
     - Built completed stop state with green completion badge and scheduled fallback when coordinates are absent.
  2. **1-Tap Stop Details Sharing with Real Geodata**:
     - Added top header share icon button (`Icons.share_outlined`) invoking `_shareStopDetails()`.
     - Formatted structured plaintext payload including stop category, timings, location, real distance from user/previous stop, estimated travel time, Google Maps direct place URL, cost, booking ref, and notes via `SharePlus.instance.share`.
  3. **Contextual Inter-Stop Routing Integration**:
     - Extended `StopDetailSheet` and `ItineraryScreen._showStopDetail` with `previousStop` parameter across both timeline and list view modes.
- **Modified Files**:
  - `lib/features/itinerary/widgets/stop_detail_sheet.dart` [MODIFIED]
  - `lib/features/itinerary/itinerary_screen.dart` [MODIFIED]
### `IMP-076` · Trip Detail Dashboard: Collapsible Sticky Hero & Zero-Redundancy Rich Hub
- **Date**: September 2, 2026
- **Scope & Objectives**:
  1. **Collapsible Sticky Hero Header (`SliverAppBar`)**:
     - Built `_CollapsibleHeroHeader` with `pinned: true` and `expandedHeight: 270.0`.
     - Cross-fades from a rich gradient cover header with destination and dates into a slim, frosted glass mini-bar with single-line trip title, status dot, pinned back button, and popup menu on scroll.
  2. **Elimination of Navigation & Metric Redundancies**:
     - Removed duplicate vertical `_SectionLinks` list and repeated `_StatsRow` counts that caused metric clashing.
     - Established single, authoritative interactive cards for each core pillar.
  3. **Authoritative Itinerary Hub Card (`_ItineraryHubCard`)**:
     - Dynamically surfaces next upcoming unvisited stop with formatted start time, location, category icon, and 1-tap route to `/itinerary`.
     - Gracefully falls back to completed milestone status or itinerary planning prompt.
  4. **Logistics & Departure Card (`_LogisticsCard`)**:
     - Meetup point with 1-tap clipboard copy and transport mode tags (Flight, Van, Ferry, Bus, Car).
  5. **Authoritative Budget Card (`_BudgetCard`)**:
     - Spend progress bar, remaining balance, and split method tag (`Equal Split` / `Custom Split`) with 1-tap route to `/budget`.
  6. **Authoritative Squad Card (`_SquadPreviewCard`)**:
     - Overlapping avatar cluster, member count, and 1-tap route to `/members`.
  7. **2-Tile Utility Hub (`_QuickTile`)**:
     - Side-by-side balanced tiles for **Packing List** (with live progress indicator) and **Chat & Polls**.
- **Modified Files**:
  - `lib/features/trip_detail/trip_detail_screen.dart` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/features/trip_detail/trip_detail_screen.dart` passed with 0 issues.

---

### `IMP-077` · UI / Brand-Aligned Back Button Standardization
- **Date**: September 3, 2026
- **Scope & Objectives**:
  1. **Upgraded Core `AppBackButton`**:
     - Standardized on Tara Travel brand guidelines: `BorderRadius.circular(12)` conforming to the exact 12px button radius rule.
     - Added `AppBackButtonVariant` enum:
       - `glass`: Frosted backdrop filter (`sigma: 8`), 12% white opacity fill, 18% white border, white icon for dark/hero gradients.
       - `light`: Crisp white fill with 1px `AppColors.cardBorder` and ambient shadow for light pages (Friends, Notifications).
       - `brand`: Soft Sand (`#FAECE7`) fill with light coral border and primary coral icon (`#D85A30`).
       - `ghost`: Transparent fill with subtle coral border.
     - Integrated `Semantics(button: true, label: 'Back')`, `Material` ripple feedback with `InkWell`, and configurable `size` and `iconSize`.
  2. **Comprehensive Screen Adoption**:
     - `PackingScreen`: Replaced custom frosted container with `AppBackButton(variant: AppBackButtonVariant.glass)`.
     - `FriendsScreen`: Replaced ad-hoc white container with `AppBackButton(variant: AppBackButtonVariant.light)`.
     - `LiveNavigationScreen`: Replaced custom container with dynamic dark/light `AppBackButton`.
     - `NavigationScreen`: Replaced black circle container with `AppBackButton(variant: AppBackButtonVariant.glass, color: Colors.black45)`.
     - `ChatScreen`: Added `AppBackButton` to header when navigated to via route so travelers can return to previous screen.
     - `NotificationsScreen`: Integrated brand `AppBackButton(variant: AppBackButtonVariant.light)` as leading AppBar widget.
     - `ActivityLogScreen`: Integrated brand `AppBackButton(variant: AppBackButtonVariant.glass)` as leading AppBar widget.
     - `CreateTripFlow` (`TransportStep`, `BudgetStep`, `ConfirmStep`): Standardized back chevrons on `AppBackButton`.
     - `MapPinPickerModal`: Replaced generic `IconButton` with `AppBackButton(variant: AppBackButtonVariant.light)`.
- **Modified Files**:
  - `lib/core/widgets/buttons/app_back_button.dart` [MODIFIED]
  - `lib/features/trip_detail/trip_detail_screen.dart` [MODIFIED]
  - `lib/features/packing/packing_screen.dart` [MODIFIED]
  - `lib/features/friends/friends_screen.dart` [MODIFIED]
  - `lib/features/navigation/live_navigation_screen.dart` [MODIFIED]
  - `lib/features/navigation/navigation_screen.dart` [MODIFIED]
  - `lib/features/chat/chat_screen.dart` [MODIFIED]
  - `lib/features/notifications/notifications_screen.dart` [MODIFIED]
  - `lib/features/activity/activity_log_screen.dart` [MODIFIED]
  - `lib/features/create_trip/steps/transport_step.dart` [MODIFIED]
  - `lib/features/create_trip/steps/budget_step.dart` [MODIFIED]
  - `lib/features/create_trip/steps/confirm_step.dart` [MODIFIED]
  - `lib/core/widgets/inputs/map_pin_picker_modal.dart` [MODIFIED]
- **Verification**:
  - `flutter analyze` completed cleanly with 0 errors and 0 warnings.

---

### `IMP-078` · Feature / Personal Allowance & Dual-Scope Trip Budget Tracker
- **Date**: September 3, 2026
- **Scope & Objectives**:
  1. **Supabase Database Isolation (`023_personal_allowance_and_expenses.sql`)**:
     - Added `public.trip_personal_allowances` for personal budget target, 10% emergency buffer, and cash on hand.
     - Added `public.personal_expenses` for private solo purchases (souvenirs, personal snacks, solo rides).
     - Strict Row Level Security (`auth.uid() = user_id`) protecting personal pocket money privacy from other trip members and organizers.
  2. **Core Data & State Layer**:
     - Created `PersonalAllowanceModel` and `PersonalExpenseItem` in `lib/core/models/personal_allowance_model.dart`.
     - Created `PersonalAllowanceRepository` in `lib/core/repositories/personal_allowance_repository.dart` and registered in `repository_providers.dart`.
     - Created `personalAllowanceProvider`, `myGroupLiabilityProvider`, and `PersonalAllowanceController` in `lib/core/providers/personal_allowance_provider.dart`.
  3. **Dual-Scope Budget Dashboard**:
     - Upgraded `BudgetScreen` with top-level scope switcher: `[ 👥 Group Fund ]` vs `[ 👤 My Allowance ]`.
     - `PersonalAllowanceCard`: Hero widget showing personal allowance target, safe remaining, and 10% emergency lock badge.
     - `DailyPacingCard`: Dynamic burn-rate velocity tracker (`Safe-to-Spend Today = remainingOperational / daysRemaining`) with green/amber/red pacing status.
     - `CashVsDigitalCard`: Visual balance comparison between physical Cash on Hand and digital payments (GCash / Maya / Card) with instant ATM cash-in modal.
     - `PersonalExpenseList`: Private transaction list with category badges and instant deletion.
     - `SetAllowanceSheet`: Modal with quick presets (`₱3,000`, `₱5,000`, `₱10,000`, `₱15,000`, `₱25,000`), custom numeric input, and emergency buffer selector.
  4. **Expense Logging & Create Trip Integration**:
     - Added scope toggle (`Group Expense` vs `Personal Pocket`) in `AddExpenseForm` to route solo spending away from group debts.
     - Added optional `My personal allowance` input in `BudgetStep` and persisted upon trip confirmation in `CreateTripFlow`.
- **Modified / Created Files**:
  - `supabase/migrations/023_personal_allowance_and_expenses.sql` [NEW]
  - `lib/core/models/personal_allowance_model.dart` [NEW]
  - `lib/core/repositories/personal_allowance_repository.dart` [NEW]
  - `lib/core/providers/personal_allowance_provider.dart` [NEW]
  - `lib/core/providers/repository_providers.dart` [MODIFIED]
  - `lib/features/budget/widgets/set_allowance_sheet.dart` [NEW]
  - `lib/features/budget/widgets/personal_allowance_card.dart` [NEW]
  - `lib/features/budget/widgets/daily_pacing_card.dart` [NEW]
  - `lib/features/budget/widgets/cash_vs_digital_card.dart` [NEW]
  - `lib/features/budget/widgets/personal_expense_list.dart` [NEW]
  - `lib/features/budget/widgets/add_expense_form.dart` [MODIFIED]
  - `lib/features/budget/budget_screen.dart` [MODIFIED]
  - `lib/features/create_trip/models/new_trip_model.dart` [MODIFIED]
  - `lib/features/create_trip/steps/budget_step.dart` [MODIFIED]
  - `lib/features/create_trip/create_trip_flow.dart` [MODIFIED]
  - `test/core/personal_allowance_test.dart` [NEW]
- **Verification**:
  - `flutter analyze` completed with 0 issues across all modified modules and tests.

---

### `IMP-079` · Enhancement / Budget & Personal Allowance UX Polish
- **Date**: September 3, 2026
- **Scope & Objectives**:
  1. **Dynamic Daily Pacing Card UX**:
     - Upgraded with proportional animated burn-rate gauge and color-coded status badge with pulsing live indicator.
     - Added smart contextual budgeting tip footer with days-remaining countdown.
  2. **Multi-Segment Stacked Gauge in Hero Card**:
     - `PersonalAllowanceCard` now features a stacked horizontal bar showing exact ratios for Solo Spent, Group Share, Buffer Reserve, and Available Balance with a clean color legend.
  3. **Floating Quick-Add Bottom Sheet**:
     - Added persistent `FloatingActionButton.extended` on `BudgetScreen` switching between "Log Group Bill" and "Log Pocket Expense".
     - Opens a responsive modal bottom sheet to log purchases immediately without scrolling past existing expenses.
  4. **Live Breakdown Calculator in Set Allowance Sheet**:
     - Displays real-time calculations as the traveler types or selects presets (Spendable Budget vs. Emergency Reserve).
     - Enhanced full-width preset grid with active elevation styling.
  5. **Cash vs. Digital Balance Enhancements**:
     - Added proportional split bar and enhanced ATM Cash-In modal with current wallet balance reference.
  6. **Interactive Solo Expense List**:
     - Added swipe-to-delete with confirmation modal, category color coding, payment mode badges, and date formatting.
  7. **Quick Amount Chips in Expense Form**:
     - Added one-tap incremental chips (`+₱50`, `+₱100`, `+₱200`, `+₱500`, `+₱1,000`) for logging fares and street snacks.
  8. **My Allowance as Primary Landing View**:
     - Configured `👤 My Allowance` as the default first tab in `BudgetScreen` and `Personal Pocket` as the primary left option in `AddExpenseForm`.
- **Target Files**:
  - `lib/features/budget/widgets/daily_pacing_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/personal_allowance_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/cash_vs_digital_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/set_allowance_sheet.dart` [MODIFIED]
  - `lib/features/budget/widgets/personal_expense_list.dart` [MODIFIED]
  - `lib/features/budget/widgets/add_expense_form.dart` [MODIFIED]
  - `lib/features/budget/budget_screen.dart` [MODIFIED]
- **Verification**:
  - `flutter analyze` completed with 0 errors and 0 warnings.


### `IMP-080` · Trip Title Display & Universal Content Overflow Prevention
- **Date**: September 4, 2026
- **Scope & Objectives**:
  1. **Trip Title Presentation**:
     - Prominently integrated trip title (`trip.name`) into the header of `BudgetScreen`, replacing generic "Budget & Allowance" with the custom trip name (with fallback).
     - Added `tripName` to `BudgetOverviewCard` and `PersonalAllowanceCard` so both Group Fund and Personal Allowance hero cards explicitly showcase the trip title.
     - Enhanced the active trip badge (`📍 [Emoji] [Destination] ▾`) with trip switcher bottom sheet.
  2. **Universal Content Overflow Prevention**:
     - `budget_screen.dart`: Made destination pill text flexible with single-line ellipsis to prevent horizontal overflows.
     - `budget_overview_card.dart`: Wrapped title row in `Expanded`, large budget currency in `Flexible`, and remaining/spent descriptions with single-line ellipsis.
     - `personal_allowance_card.dart`: Added `Expanded` + `Flexible` to the header title row, `Flexible` to the large allowance amount, `Expanded` to the Emergency Buffer row, and `Wrap` to the legend dot indicators.
     - `daily_pacing_card.dart`: Made title and status pill in the header row flexible, and wrapped large safe-spend figure in `Flexible`.
     - `cash_vs_digital_card.dart`: Protected header row with `Expanded`/`Flexible`, and wrapped cash and digital currency values in `FittedBox` with `BoxFit.scaleDown`.
     - `set_allowance_sheet.dart`: Replaced rigid 5-column `Row` of `Expanded` preset buttons with a responsive `Wrap`, eliminating horizontal clipping, and protected live breakdown label rows with `Expanded`.
     - `personal_expense_list.dart`: Wrapped date string in `Flexible` and expense amounts in `FittedBox`.
     - `member_contribution_card.dart`: Added ellipsis to member names and roles, and spacing between columns.
     - `expense_log.dart`: Added ellipsis to descriptions and flexible wrapping to date/status pills.
- **Target Files**:
  - `lib/features/budget/budget_screen.dart` [MODIFIED]
  - `lib/features/budget/widgets/budget_overview_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/personal_allowance_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/daily_pacing_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/cash_vs_digital_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/set_allowance_sheet.dart` [MODIFIED]
  - `lib/features/budget/widgets/personal_expense_list.dart` [MODIFIED]

---

## 🚀 [IMP-078] In-Chat Real-Time Travel Polls, Pinned Announcements & Tara Brand UI/UX Overhaul
- **Date**: 2026-09-04
- **Motivation**:
  - Group travel planning suffered from chaotic disjointed decision-making (*"Where are we eating?"*, *"What time do we leave?"*, *"Boat rental consensus"*).
  - Chat screen was a basic text-only stream with no collaborative tools, no real-time poll voting, and no resolution back to the trip itinerary.
- **Architectural Implementation**:
  1. **Database Migration `024_trip_polls_and_chat_enhancements.sql`**:
     - Created `public.trip_polls` with JSONB options array, category (`food`, `departure`, `activity`, `budget`, `custom`), `is_closed`, `allow_multiple`, and `winner_option_id`.
     - Created `public.trip_poll_votes` with unique constraint `(poll_id, user_id, option_id)` for idempotent toggle-voting.
     - Added `is_pinned`, `poll_id`, and `message_type` (`text`, `poll`, `announcement`, `quick_travel`) to `public.trip_messages`.
     - Added `fcm_token` column to `public.users` for Firebase Cloud Messaging push notifications.
     - Enforced anti-recursive RLS policies via `public.is_trip_member(trip_id)`.
     - Published `trip_polls` and `trip_poll_votes` to `supabase_realtime`.
  2. **Core Domain & Repositories**:
     - `TripPoll` & `PollOption` models with immutable vote percentage calculation, privacy-preserving voter name formatting (`MemberModel.formatDisplayName(hideSurname: true)`), and winner detection.
     - Upgraded `ChatRepository` with Poll CRUD (`createPoll`, `castVote`, `removeVote`, `closePoll`), message pinning (`togglePinMessage`), and real-time streams (`pollsStream`, `pollVotesStream`).
  3. **Riverpod State Architecture**:
     - `poll_provider.dart`: `pollsProvider` combining real-time polls stream with live vote counts, toggle vote semantics, and automatic winner resolution.
     - `chat_provider.dart`: Optimistic local rendering on message dispatch and derived `pinnedMessagesProvider`.
  4. **Brand-Centric UI/UX Widgets**:
     - `PollCard`: In-chat interactive card with animated progress bars (Coral `#D85A30` / Amber `#EF9F27`), category badge, voter name previews, and **"Add to Itinerary" / "Add to Expenses"** one-tap resolution actions.
     - `CreatePollSheet`: Modal bottom sheet with quick travel presets (Dinner Spot, Departure Time, Afternoon Activity, Shared Rental), dynamic option list, and multi-choice toggle.
     - `ChatScreen`: Rebuilt with Playfair Display trip title, online status pulse, collapsible **Pinned Announcement Drawer**, travel **Quick Action Chips** (`📊 Create Poll`, `⏰ Running 10 mins late!`, `📍 Arrived at meeting spot`, `🍽️ Where are we eating?`), Coral gradient sender bubbles, and white companion cards.
  5. **Firebase Notification Service**:
     - Created `FirebaseNotificationService` singleton with permission requests, FCM token storage in Supabase `users.fcm_token`, and trip topic subscriptions (`trip_{tripId}`).
- **Target Files**:
  - `supabase/migrations/024_trip_polls_and_chat_enhancements.sql` [NEW]
  - `lib/core/models/trip_poll_model.dart` [NEW]
  - `lib/core/repositories/chat_repository.dart` [MODIFIED]
  - `lib/core/providers/poll_provider.dart` [NEW]
  - `lib/core/providers/chat_provider.dart` [MODIFIED]
  - `lib/core/services/firebase_notification_service.dart` [NEW]
  - `lib/features/chat/widgets/poll_card.dart` [NEW]
  - `lib/features/chat/widgets/create_poll_sheet.dart` [NEW]
  - `lib/features/chat/chat_screen.dart` [MODIFIED]
  - `lib/main.dart` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
- **Verification**:
  - `flutter analyze` completed with 0 errors and 0 warnings across all modified and new files.

---

## 📱 [IMP-079] Mobile Responsive Layout Standards, Strict Overflow Prevention & Canonical Component Reuse Guardrails
- **Date**: 2026-09-04
- **Motivation**:
  - Prevent visual degradation, `RenderFlex` overflow yellow-and-black stripes, and usability issues across varying mobile screen sizes (narrow 320px–360px devices, tall aspect ratio displays, notches, dynamic islands, accessibility zoom).
  - Eliminate code bloat and UI regressions caused by recreating one-off hardcoded widgets, colors, and dialogs when canonical design-system components already exist.
- **Architectural Standards Added to `docs/SOFTWARE_DESIGN_PATTERNS.md` & `docs/MEMORY.md`**:
  1. **Universal Screen Boundary Rule**:
     - All vertical and variable-length layouts must be scrollable (`SingleChildScrollView`, `ListView`, `CustomScrollView`).
     - Keyboard awareness: Ensure proper view insets handling (`Scaffold.resizeToAvoidBottomInset: true` + bottom padding).
  2. **Flexible & Bounded Constraints**:
     - In `Row` layouts, dynamic text and variable-width children must be wrapped in `Expanded` or `Flexible` with explicit text ellipsis.
     - Unbounded scrollable lists must never sit directly inside a `Column` without flex bounds.
  3. **Safe Dynamic Typography**:
     - Explicit `overflow: TextOverflow.ellipsis` and `maxLines` on single-line and bounded text elements.
     - Use `FittedBox` or allow multi-line wrapping on critical CTAs instead of hardcoded fixed container widths.
     - Text scale factor clamping for extreme system zoom levels (`MediaQuery.withClampedTextScaling(...)`).
  4. **Adaptive & Proportional Sizing**:
     - Leverage `LayoutBuilder` / `BoxConstraints` and dynamic column counts rather than fixed pixel widths.
  5. **Safe Area & Hardware Insets**:
     - Guard against hardware notches, camera cutouts, and bottom gesture pill bars via `SafeArea` and `MediaQuery.paddingOf(context)`.
     - Modal bottom sheets must be scroll-controlled (`isScrollControlled: true`) with explicit scroll views.
  6. **Dynamic Card & Content Wrapping**:
     - Dynamic chips, badge pills, and tag sets must use `Wrap` with `spacing` / `runSpacing` instead of horizontal `Row`.
  7. **Canonical Component Reuse & Anti-Duplication (DRY UI)**:
     - Mandatory pre-flight component audit: Check `lib/core/widgets/` before creating new widgets.
     - Reusable shared catalog: `AppBackButton`, `AppDialog`, `AppFeedback`, `AppBanner`, `AppTextField`, `AppNumericField`, `AppDropdown`, `TaraDateRangePicker`, `LocationPicker`, `ShimmerLoading`, `GlassCard`, `TripTypeCarousel`, `MultiMemberPickerSheet`.
     - Zero hardcoded styling: Colors, fonts, and corner radii strictly consume `AppColors`, `AppTextStyles`, and brand identity tokens.
- **Target Files**:
  - `docs/SOFTWARE_DESIGN_PATTERNS.md` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]

---

## 💬 [IMP-081] Chat Module UI/UX Overhaul, Keyboard Inset Fix & Group Decision Polish
- **Date**: 2026-09-04
- **Motivation**:
  - Eliminate the double-padding layout glitch above the software keyboard in `ChatScreen` that created an unsightly blank gap.
  - Upgrade message readability via consecutive sender grouping (suppressing duplicate avatars/names within 2 minutes), integrated timestamps with delivery status ticks, and high-visibility badges for `quickTravel` status alerts.
  - Introduce essential messaging capabilities: context action sheet with **Copy to Clipboard** (`Clipboard.setData`), pinned announcements top banner with modal viewer, and smart scroll-to-bottom floating action button.
  - Enhance group poll interactions with organizer close confirmation dialogs and duplicate resolution prevention.
- **Key Technical Enhancements**:
  1. **Keyboard & Safe Area Inset Normalization**:
     - Synchronized `_InputBar` padding with `MediaQuery.viewInsetsOf(context)` and `MediaQuery.paddingOf(context)` to prevent double insets under `Scaffold(resizeToAvoidBottomInset: true)`.
     - Replaced hardcoded status bar heights in `_ChatHeader` with `MediaQuery.paddingOf(context).top` for notch and dynamic island edge-to-edge responsiveness.
  2. **Message Bubble Grouping & Context Actions**:
     - Added consecutive message detection logic: groups messages from the same sender within 2 minutes with tighter vertical spacing (3px) and rounded bubble corners.
     - Added long-press context sheet: 1-tap emoji reactions (`❤️`, `👍`, `✈️`, `🌴`, `😂`, `🔥`), clipboard copy with toast confirmation, pin/unpin toggles, and deletion confirmation dialog.
  3. **Distinct Quick Travel Alert Styling**:
     - Messages with `ChatMessageType.quickTravel` are rendered with custom coral/amber borders, `TRAVEL ALERT` status pill, and highlighted card background to stand out from regular chatter.
  4. **Smart Scroll & Floating FAB**:
     - Added `_ScrollToBottomButton` that animates into view when scrolled > 240px from bottom.
     - Auto-scroll only triggers if user is already near bottom, preventing scroll disruptions while reading older messages.
  5. **Quick Travel Attachment Sheet (`+` Button)**:
     - Expandable bottom sheet exposing rich travel actions: Group Poll, Late Alert (10m), Meeting Spot Check-in, and Expense Split reminders.
  6. **Calm & Non-Intimidating Input Bar Aesthetics**:
     - Removed aggressive colored drop shadows (`BoxShadow` with coral/red glows) from the send button, attachment `+` button, quick chips, and message bubbles.
     - Implemented flat, friendly, and soft input pill styling with clean hairline border separation.
- **Target Files**:
  - `lib/features/chat/chat_screen.dart` [MODIFIED]
  - `lib/features/chat/widgets/poll_card.dart` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/features/chat/` executed with 0 errors and 0 warnings.
  - Verified keyboard inset avoidance, context menu clipboard copy, and poll finalization dialogs.

---

### `IMP-080` · Home Quick Actions Grid — Compact Card Refinement & Sizing Alignment
- **Date**: September 04, 2026
- **Scope & Objectives**:
  1. **Aspect Ratio & Card Proportion**:
     - Adjusted `GridView.count` `childAspectRatio` from `1.34` to `1.52`, eliminating awkward vertical bloat and giving tiles a balanced, sleek, modern travel card feel.
  2. **Internal Dimensions & Visual Balance**:
     - Tuned container padding to `EdgeInsets.symmetric(horizontal: 14, vertical: 11)`.
     - Scaled icon square badge to `30x30` with `BorderRadius.circular(9)` and `16px` icon size.
     - Adjusted card radius to `BorderRadius.circular(18)` for an organic fit alongside other card components.
     - Calibrated typography: `13.5px` bold for primary action labels, and `11px` medium with `1px` top offset for sublabels.
  3. **Pulsing First-Run Guide Outline Fix**:
     - Replaced the fixed `140x100` box in `_PulsingGuide` with `Positioned.fill` and `BorderRadius.circular(20)` to accurately wrap the rounded card bounds without awkward misaligned corners.
- **Target Files**:
  - `lib/features/home/home_screen.dart` [MODIFIED]
  - `lib/features/home/widgets/quick_action_tile.dart` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/features/home/` executed with 0 errors and 0 warnings (18.9s).

---

### `IMP-082` · Supabase Storage Avatar Pipeline & Multi-Screen Photo Rendering Unification
- **Date**: September 04, 2026
- **Scope & Objectives**:
  1. **Supabase Storage Upload Integration**:
     - Added `uploadAvatar(userId, localFilePath)` to `ProfileRepository` targeting Supabase Storage bucket `avatars` with path `{userId}/profile.{ext}` and cache-busting timestamp `?t={ms}`.
     - Updated `ProfileProvider.updatePhoto(pathOrUrl)` to asynchronously upload local picked files directly to Supabase Storage before persisting the resulting public HTTP URL into `public.users.avatar_url`.
     - Preserved direct assignment for OAuth/Google avatars (`http*`).
  2. **Shared Reusable Component (`MemberAvatarCircle`)**:
     - Created `lib/core/widgets/member_avatar_circle.dart` offering seamless hybrid resolution:
       - `CachedNetworkImage` with placeholder/error fallbacks for HTTP URLs (`avatar_url` from Supabase / Google).
       - `Image.file` for local un-synced file previews.
       - Initials fallback circle with deterministic member background color.
  3. **Multi-Screen Avatar Fixes**:
     - **Profile Screen**: Replaced `Image.file`-only rendering with `_buildProfileAvatar(profile)` supporting remote Supabase HTTP URLs (`CachedNetworkImage`), and ensured `_pickAndSavePhoto` awaits `updatePhoto`.
     - **Members Screen**: Replaced initials-only `Container` with `MemberAvatarCircle` utilizing `member.profilePhotoUrl`.
     - **Trip Detail Screen**: Replaced overlapping avatar cluster initials containers with `MemberAvatarCircle` per companion.
     - **Trip Cards & Home Screen**: Added `photoUrl` to `TravelerInfo`, passed `member.profilePhotoUrl` from `HomeScreen`, and rendered `MemberAvatarCircle` in `TripCard`.
     - **Multi-Member Picker Sheet**: Updated `MemberAvatarStack` and the list tile leading avatar to use `MemberAvatarCircle`.
     - **Navigation & Radar**: Added `photoUrl` to `NavMember` model & `copyWith`, passed `profile.profilePhotoUrl` / `member.profilePhotoUrl` in `NavigationProvider`, and updated `MemberAvatar` and `MapMemberPin` to render `MemberAvatarCircle`.
     - **Itinerary Sheets & Cards**: Updated `StopDetailSheet`, `StopCard`, and `ArrivalPill` avatar stacks to render `MemberAvatarCircle`.
- **Target Files**:
  - `lib/core/repositories/profile_repository.dart` [MODIFIED]
  - `lib/core/providers/profile_provider.dart` [MODIFIED]
  - `lib/core/widgets/member_avatar_circle.dart` [NEW]
  - `lib/features/profile/profile_screen.dart` [MODIFIED]
  - `lib/features/members/members_screen.dart` [MODIFIED]
  - `lib/features/trip_detail/trip_detail_screen.dart` [MODIFIED]
  - `lib/features/home/widgets/trip_card.dart` [MODIFIED]
  - `lib/features/home/home_screen.dart` [MODIFIED]
  - `lib/core/widgets/multi_member_picker_sheet.dart` [MODIFIED]
  - `lib/features/navigation/models/navigation_models.dart` [MODIFIED]
  - `lib/features/navigation/providers/navigation_provider.dart` [MODIFIED]
  - `lib/features/navigation/widgets/shared/member_avatar.dart` [MODIFIED]
  - `lib/features/itinerary/widgets/stop_detail_sheet.dart` [MODIFIED]
  - `lib/features/itinerary/widgets/stop_card.dart` [MODIFIED]
  - `lib/features/itinerary/widgets/arrival_pill.dart` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/` executed: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-083` · Interactive Trip Chat, Collaborative Polls & Contextual Activity Hub (IDEA-004)
- **Date**: September 04, 2026
- **Scope & Objectives**:
  1. **Supabase Migration 025 (`025_trip_chat_rich_embeds_and_reactions.sql`)**:
     - Added `metadata jsonb default '{}'::jsonb` and `reactions jsonb default '{}'::jsonb` columns to `public.trip_messages`.
     - Created RLS update policy allowing trip members to update `reactions` on messages without overriding message content.
     - Added RLS update policy on `public.trip_polls` allowing trip members to append crowdsourced options while poll is open.
  2. **Data & Repository Layer Expansion**:
     - In `lib/core/repositories/chat_repository.dart`:
       - Expanded `ChatMessageType` enum with `itinerarySnippet`, `expenseRequest`, `packingAlert`, `locationDrop`, `media`, and `taraBot`.
       - Added `metadata` and `reactions` parsing/serialization to `ChatMessage`.
       - Implemented `addPollOption(pollId, optionText, createdByName)` to append user options to active polls.
       - Implemented `toggleReaction(messageId, emoji, userId)` with atomic JSONB aggregation.
       - Implemented `uploadChatMedia(tripId, localFilePath)` targeting Supabase Storage bucket `avatars`.
     - In `lib/core/models/trip_poll_model.dart`:
       - Added `options` to `TripPoll.copyWith`.
  3. **Riverpod State Management**:
     - In `lib/core/providers/chat_provider.dart`:
       - Added `sendRichCard(...)` supporting structured metadata payloads for all new message types.
       - Added `sendMediaMessage(...)` with automatic storage upload and optimistic local bubble rendering.
       - Added `toggleReaction(...)` with instantaneous local optimistic toggle before remote Supabase write.
     - In `lib/core/providers/poll_provider.dart`:
       - Added `addOption(pollId, optionText, createdByName)` to `PollsNotifier`.
  4. **UI Components & Rich Embed Cards**:
     - Created `lib/features/chat/widgets/chat_embed_cards.dart`:
       - `ItineraryStopEmbed`: Visual stop card showing day number, title, category icon, notes, and direct Google Maps / in-app directions button.
       - `ExpenseRequestEmbed`: Financial card detailing expense description, category, amount in Philippine Pesos (₱), and one-tap "View in Budget" CTA.
       - `PackingAlertEmbed`: Urgent packing checklist ping with interactive "🙋‍♂️ I'll Bring This!" claim button that assigns the item to the user and notifies chat.
       - `LocationDropEmbed`: GPS coordinate pin card with "🗺️ Open in Google Maps" launch handler.
       - `MediaAttachmentEmbed`: Cached network photo preview with zoom-ready aesthetic container and rounded corners.
       - `TaraBotBriefingEmbed`: AI daily morning recap summary detailing scheduled stops, estimated costs, and travel tips.
       - `ReactionPillsRow`: Responsive wrap of active emoji reactions with active user state highlighting and tap-to-toggle haptics.
     - Created `lib/features/chat/widgets/chat_attachment_picker_sheet.dart`:
       - Clean modal bottom sheet replacing legacy action list: Itinerary Stops picker, Expenses picker, Unassigned Packing Items picker, Photo gallery picker, Live GPS Pin drop, and Tara Bot Daily Briefing generator.
     - Updated `lib/features/chat/widgets/poll_card.dart`:
       - Integrated crowdsourced option submission via `_showAddOptionDialog` ("Suggest an Option / Spot").
     - Updated `lib/features/chat/chat_screen.dart`:
       - Integrated rich embed cards and `ReactionPillsRow` into both `_MyBubble` and `_TheirBubble`.
       - Connected `_MessageActionSheet` quick reaction bar (❤️, 👍, 🏖️, 🚗, 🍽️, ⏰) to `chatNotifier.toggleReaction`.
       - Wired `_handleClaimPackingItem` using `PackingRepository.assignItem`.
- **Target Files**:
  - `supabase/migrations/025_trip_chat_rich_embeds_and_reactions.sql` [NEW]
  - `lib/core/repositories/chat_repository.dart` [MODIFIED]
  - `lib/core/models/trip_poll_model.dart` [MODIFIED]
  - `lib/core/providers/chat_provider.dart` [MODIFIED]
  - `lib/core/providers/poll_provider.dart` [MODIFIED]
  - `lib/features/chat/widgets/chat_embed_cards.dart` [NEW]
  - `lib/features/chat/widgets/chat_attachment_picker_sheet.dart` [NEW]
  - `lib/features/chat/widgets/poll_card.dart` [MODIFIED]
  - `lib/features/chat/chat_screen.dart` [MODIFIED]
  - `docs/DEV_IDEA.md` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
  - `docs/CHANGELOG.md` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/features/chat/` executed: **No issues found! (0 errors, 0 warnings)**.
  - `flutter analyze lib/core/` executed: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-084` · Polls & Votes / Bidirectional Vote Undo & Optimistic State Sync
- **Date**: September 04, 2026
- **Scope & Objectives**:
  1. **Synchronous Raw State Hydration**:
     - Added `getPollsAndVotesRaw(tripId)` to `ChatRepository` returning both polls and votes for immediate local cache seeding on provider build.
  2. **Optimistic Local Updates with Rollback**:
     - Updated `castVote` in `PollsNotifier` to optimistically append a synthetic vote into `_rawVotes` and rebuild state instantly before remote write. Reverts if Supabase rejects the write.
     - Updated `removeVote` in `PollsNotifier` to optimistically remove the user's vote from `_rawVotes` and rebuild state immediately with fallback restore on failure.
     - Enhanced `toggleVote` to pass `currentUserId` and properly unvote when tapping an already voted option.
     - Added `undoAllVotes({required TripPoll poll, required String currentUserId})` to retract all votes for a poll with a single tap.
  3. **Seamless Toggle-to-Undo UX in PollCard**:
     - Retained intuitive tap-to-toggle unvoting on the option bars without extra clutter or separate buttons.
     - Kept PollCard header minimal and clean (`by Creator · N votes`).
- **Target Files**:
  - `lib/core/repositories/chat_repository.dart` [MODIFIED]
  - `lib/core/providers/poll_provider.dart` [MODIFIED]
  - `lib/features/chat/widgets/poll_card.dart` [MODIFIED]
  - `lib/features/chat/chat_screen.dart` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
  - `docs/CHANGELOG.md` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/features/chat/ lib/core/providers/poll_provider.dart lib/core/repositories/chat_repository.dart` executed: **No issues found! (0 errors, 0 warnings)**.

### `IMP-085` · Polls / Winner Card & Detail Sheet
- **Date**: September 04, 2026
- **Scope & Objectives**:
  1. **Premium Winner Card (`_WinnerCard`)**:
     - Replaced the flat `_WinnerActions` resolve section with a visually striking, gradient-filled card (deep green → bright green).
     - Trophy badge pill, large percentage display (28px bold), winner text, vote count, category label, and voter name chips.
     - Decorative circles with `Clip.hardEdge` for premium glassmorphism effect.
     - Haptic feedback on tap, with "Tap for results & actions" hint text.
  2. **Winner Detail Bottom Sheet (`_WinnerDetailSheet`)**:
     - `DraggableScrollableSheet` (70% initial → 92% max) showing full poll results.
     - Header: centered trophy icon with gradient background, winner text in Playfair Display, total vote count.
     - Original question context card with category emoji and creator attribution.
     - Ranked results breakdown: numbered rank circles, option text, percentage, animated `TweenAnimationBuilder` progress bars, voter name lists.
     - Winner option highlighted with green background, green border, green rank circle, and 🏆 emoji.
     - Quick Actions section: "Add to Itinerary" (coral) and "Add to Expenses" (amber) buttons with colored shadow, auto-dismissing sheet before executing callback.
  3. **Voter Chips (`_VoterChips`)**:
     - Reusable `Wrap`-based voter name chip row showing up to 4 names with "+N more" overflow pill.
  4. **Detail Action Button (`_DetailActionButton`)**:
     - Upgraded from 10px to 14px vertical padding, 14px border radius, colored drop shadow for depth.
- **Target Files**:
  - `lib/features/chat/widgets/poll_card.dart` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
  - `docs/CHANGELOG.md` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/features/chat/widgets/poll_card.dart` executed: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-086` · Added Winning Option Rich Embed Card & Interactive Detail Sheets
- **Date**: September 04, 2026
- **Scope & Objectives**:
  1. **Rich Embed Message Generation**:
     - Upgraded `_handleWinnerToItinerary` and `_handleWinnerToExpense` in `ChatScreen` from plain text messages (`sendMessage`) to rich embed cards (`sendRichCard`).
     - Added full winner metadata (`is_poll_winner: true`, `poll_question`, `poll_category`, `winner_votes`, `total_votes`) to both `ChatMessageType.itinerarySnippet` and `ChatMessageType.expenseRequest`.
  2. **Interactive Embed Cards (`ItineraryStopEmbed` & `ExpenseRequestEmbed`)**:
     - Enhanced `ItineraryStopEmbed` with a prominent `🏆 WINNING POLL OPTION` header badge, green border and shadow styling when originated from a poll, and an interactive tap area via `InkWell`.
     - Enhanced `ExpenseRequestEmbed` with `🏆 WINNING POLL OPTION · DRAFT EXPENSE` header badge, amber styling, draft cost indicator (`₱0.00 · Draft`), and interactive tap area.
  3. **Full Detail Modal Sheets (`_ItineraryStopDetailSheet` & `_ExpenseDetailSheet`)**:
     - `_ItineraryStopDetailSheet`: Modal bottom sheet displaying the poll context hero banner, category, day number, stop title (Playfair Display 22px), location pin, notes, and direct actions ("Google Maps" external launcher + "View Itinerary" route navigation to `/itinerary`).
     - `_ExpenseDetailSheet`: Modal bottom sheet displaying the poll context hero banner, category pill, description (20px bold), large formatted currency amount, draft hint, and direct "View in Budget" CTA to `/budget`.
  4. **Poll Resolution State & Button Feedback**:
     - Updated `_DetailActionButton` in `poll_card.dart` to support disabled state gracefully with `Added to Itinerary ✓` / `Added to Expenses ✓` text and muted neutral tones when the poll has already been converted.
     - Wired `onAddToItinerary` and `onAddToExpenses` in `ChatScreen` to pass `null` when the poll ID is already in `_resolvedItineraryPollIds` or `_resolvedExpensePollIds`.
- **Target Files**:
  - `lib/features/chat/chat_screen.dart` [MODIFIED]
  - `lib/features/chat/widgets/chat_embed_cards.dart` [MODIFIED]
  - `lib/features/chat/widgets/poll_card.dart` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/CHANGELOG.md` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/features/chat` executed: **No issues found! (0 errors, 0 warnings)**.
  - `flutter analyze` full repo: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-087` · Scroll-to-Focused-Stop on "View Itinerary" from Poll Winner
- **Date**: September 04, 2026
- **Scope & Objectives**:
  1. **Route Arguments Forwarding** (`main.dart`):
     - Updated `/itinerary` named route handler to extract `targetStopId` (String?) and `targetDayNumber` (int?) from `ModalRoute.of(context)?.settings.arguments` and forward them as constructor parameters to `ItineraryScreen`.
  2. **Day Auto-Switching & Scroll Focus** (`itinerary_screen.dart`):
     - Added state fields: `_focusedStopId`, `_focusedDayNumber`, `_hasAttemptedScroll`, `_stopKeys` (Map<String, GlobalKey>).
     - `didChangeDependencies()` fallback: parses route arguments if not provided via constructor.
     - `_scrollToFocusedStop()`: Uses `Scrollable.ensureVisible(key.currentContext!, alignment: 0.25, duration: 700ms, curve: easeOutCubic)` with a 350ms post-frame delay to allow layout stabilization.
     - Day-switch logic: When `_focusedDayNumber` differs from `activeDay`, invokes `notifier.setActiveDay(targetIdx)` via `addPostFrameCallback`.
     - Each stop item wrapped in `Container(key: stopKey)` registered in `_stopKeys` map for scroll targeting.
  3. **Visual Highlight** (`stop_card.dart`):
     - `isHighlighted` parameter drives green glow background (`#F0FDF4`), green border (`#22C55E`, 2px), green drop shadow, and a `🏆 GROUP POLL WINNER · FOCUSED` gradient pill banner inside the card.
  4. **Navigation Sources** (`chat_embed_cards.dart`):
     - "Itinerary" quick-button on poll winner embed cards passes `targetStopId` + `targetDayNumber` via `Navigator.pushNamed` arguments.
     - "View Itinerary" button in `_ItineraryStopDetailSheet` passes the same arguments after `Navigator.pop(context)`.
- **Target Files**:
  - `lib/main.dart` [MODIFIED]
  - `lib/features/itinerary/itinerary_screen.dart` [MODIFIED]
  - `lib/features/itinerary/widgets/stop_card.dart` [MODIFIED]
  - `lib/features/chat/widgets/chat_embed_cards.dart` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
  - `docs/CHANGELOG.md` [MODIFIED]
- **Verification**:
  - `flutter analyze lib/features/itinerary lib/features/chat lib/main.dart` executed: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-088` · Typography & Brand Identity Font Tokens Standardization & Clean Code Refactor
- **Date**: September 04, 2026
- **Scope & Objectives**:
  1. **Brand Font Tokens & Semantic Typographic Scale in `AppTextStyles`** (`lib/core/theme/app_text_styles.dart`):
     - Standardized constants: `fontHeading` (`'Playfair Display'`), `fontBody` (`'DM Sans'`), and `fontSerifFallback` (`'Georgia'`).
     - Added semantic typography tokens: `titleLarge` (20px, bold), `titleMedium` (16px, bold), `headlineSmall` (18px, bold).
     - Wired `fontFamilyFallback: const ['Georgia', 'serif']` into all primary serif display styles (`headline1`, `headline2`, `headline3`, `headlineSmall`, `titleLarge`, `titleMedium`, `headlineWhite`, `tagline`).
  2. **App Theme Alignment** (`lib/core/theme/app_theme.dart`):
     - Set `fontFamilyFallback: ['Georgia', 'serif']` on `AppBarTheme.titleTextStyle` and `DialogTheme.titleTextStyle`.
  3. **Brand Display & Greeting Name Fallbacks**:
     - Added `fontFamilyFallback: ['Georgia', 'serif']` to `SplashScreen` brand wordmark ('Tara' and 'TRAVEL').
     - Added `fontFamilyFallback: const ['Georgia', 'serif']` to `AppBrandLogo` wordmark texts.
     - Added `fontFamilyFallback: ['Georgia', 'serif']` to `HomeScreen` personalized greeting name display.
  4. **Anti-Hardcoding Clean Code Refactor**:
     - Replaced scattered ad-hoc `TextStyle(fontFamily: ...)` instances across:
       - `lib/core/widgets/feedback/app_dialog.dart` (confirmation & alert dialog title and body tokens)
       - `lib/shared/widgets/trip_type_carousel.dart` (carousel card label, subtitle, and category badge)
       - `lib/features/trip_detail/trip_detail_screen.dart` (hero header title, dialogs, and collapsed bar title)
       - `lib/features/trips/trips_screen.dart` (header title and empty state headline)
       - `lib/features/trips/widgets/join_trip_modal.dart` (sheet header and description)
       - `lib/features/notifications/notifications_screen.dart` (app bar title)
       - `lib/features/navigation/live_navigation_screen.dart` (navigation destination title)
  5. **Architectural Memory Sync**:
     - Updated `docs/MEMORY.md`, `docs/SOFTWARE_DESIGN_PATTERNS.md`, `.agents/rules/brand-identity.md`, and `docs/IMPLEMENTATION_MEMORY.md`.
- **Target Files**:
  - `lib/core/theme/app_text_styles.dart` [MODIFIED]
  - `lib/core/theme/app_theme.dart` [MODIFIED]
  - `lib/core/widgets/feedback/app_dialog.dart` [MODIFIED]
  - `lib/shared/widgets/trip_type_carousel.dart` [MODIFIED]
  - `lib/features/trip_detail/trip_detail_screen.dart` [MODIFIED]
  - `lib/features/trips/trips_screen.dart` [MODIFIED]
  - `lib/features/trips/widgets/join_trip_modal.dart` [MODIFIED]
  - `lib/features/notifications/notifications_screen.dart` [MODIFIED]
  - `lib/features/navigation/live_navigation_screen.dart` [MODIFIED]
  - `lib/features/splash/splash_screen.dart` [MODIFIED]
  - `lib/features/home/home_screen.dart` [MODIFIED]
  - `lib/core/widgets/app_brand_logo.dart` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/SOFTWARE_DESIGN_PATTERNS.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - `flutter analyze`: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-084` — 2026-09-04: Comprehensive Budget & Expenses Module Revision
- **Description**: Fully revised the shared data layer, transactional CRUD, and client-side derived aggregation architecture across Budget and Expenses screens to align with ground-truth schema rules and the requested UI/UX design specifications.
- **Architectural Rationale**:
  1. **Shared Data Layer (`ExpenseModel`)**:
     - Standardized categories (`food`, `hotel`, `transport`, `activities`, `custom`) and statuses (`pending`, `approved`, `rejected`).
     - Added helper getters (`isApproved`, `isPending`, `isRejected`, `categoryColor`, `categoryIcon`, `categoryEmoji`, `categoryLabel`).
     - Maintained strict ground-truth schema compliance: only Supabase `expenses` columns (`id`, `trip_id`, `description`, `amount`, `category`, `paid_by_user_id`, `status`, `receipt_url`, `rejection_note`).
  2. **Receipt OCR & Attachment Engine (`ReceiptOcrService`)**:
     - Built cross-platform receipt image upload to Supabase Storage (`avatars` public bucket fallback) with cache-busting.
     - Implemented heuristic OCR extraction parsing peso currency tokens, totals, dates, and category keywords to pre-populate expense amounts and descriptions.
  3. **Transactional Expenses CRUD Flow (`AddExpenseForm` & `ExpenseLog`)**:
     - Updated `AddExpenseForm` with Camera and Gallery capture options, instant OCR detection prompts, split-member multi-select with per-person calculations, and dual-scope logging (Personal Pocket vs Group Fund).
     - Enhanced `ExpenseLog` with status filter chips (`All`, `Pending`, `Approved`, `Rejected`), interactive receipt modal viewer (`CachedNetworkImage`), and role-aware approval/rejection workflows (approving an expense commits it to the budget; rejecting supports optional rejection notes). Added pending count debt nudges.
  4. **Derived-State Budget Screen & Pacing (`BudgetScreen`, `BudgetOverviewCard`, `CategoryBudgetChart`)**:
     - Restyled hero card following the reference design: Deep Earth `#2C1A14` container, Playfair Display typography, large total budget readout, emerald green remaining badge, slim horizontal progress bar, and percentage usage indicators.
     - Implemented template pill navigation bar: `[Overview, Expenses, + Add, Debts]` with instant switcher tabs.
     - Revamped `CategoryBudgetChart` to render category dots, emojis, amounts, percentages, and segmented spent vs remaining indicators.
     - Context-switching trip selector carousel to switch between trips dynamically with pure client-side recomputation.
     - Preserved `SplitBillPanel` greedy creditor→debtor min-cash-flow matching graph with GCash QR / account copy and SharePlus integration.
- **Target Files**:
  - `lib/core/models/expense_model.dart` [MODIFIED]
  - `lib/core/services/receipt_ocr_service.dart` [NEW]
  - `lib/features/budget/widgets/add_expense_form.dart` [MODIFIED]
  - `lib/features/budget/widgets/category_budget_chart.dart` [MODIFIED]
  - `lib/features/budget/widgets/expense_log.dart` [MODIFIED]
  - `lib/features/budget/widgets/budget_overview_card.dart` [MODIFIED]
  - `lib/features/budget/budget_screen.dart` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - `dart analyze lib`: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-085` — 2026-09-04: Refined Budget (Personal + Trip Summary) vs Trip Expenses (Group Layout)
- **Description**: Realigned layout separation per user specification: "Budget" is dedicated to the traveler's personal budget & allowance with integrated trip expenses summary, while "Trip Expenses" preserves the exact previous classic group layout (ring chart, overview, transactional CRUD log, split bill panel).
- **Architectural Implementation**:
  1. **Trip Expenses Scope (`TripBudgetHeroCard`, `Overview`, `Expenses Log`, `Split Bill`)**:
     - Retained the exact previous hero card: Trip Name, Subtitle, Ring Chart with "% spent", large total budget, remaining amount, and "₱X spent by Y members".
     - Preserved the sub-tabs: `Overview` (Category breakdown & Member contributions), `Expenses` (Transactional CRUD log with approval workflow and receipt inspection), and `Split` (Greedy settlement plan & balances).
  2. **Budget Scope (`PersonalTripBudgetHeroCard`, `DailyPacingCard`, `CashVsDigitalCard`, `CategoryBudgetChart`, `PersonalExpenseList`)**:
     - Tailored hero card matching the clean template design with Deep Earth container, Playfair Display typography, prominent budget amount, Emerald remaining balance, slim spent bar, and an integrated **Trip Expenses Summary** pill row (Solo Spent, Group Liability share, and Trip Total).
     - Renders daily burn pacing, cash vs digital balances, itemized category breakdown, and personal pocket expense log.
- **Target Files**:
  - `lib/features/budget/widgets/trip_budget_hero_card.dart` [NEW]
  - `lib/features/budget/widgets/personal_trip_budget_hero_card.dart` [NEW]
  - `lib/features/budget/budget_screen.dart` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - `dart analyze lib`: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-089` — 2026-09-04: Numeric Typography & Readout Standardization to DM Sans
- **Description**: Standardized all numbers, percentages, countdowns, and financial readouts across the app to strictly use `AppTextStyles.fontBody` (`DM Sans`).
- **Architectural Implementation**:
  1. **Theme Tokens (`AppTextStyles`)**:
     - Added dedicated statistical/numeric tokens: `statNumberLarge` (34px bold), `statNumberMedium` (24px bold), `statNumberSmall` (18px bold) bound strictly to `AppTextStyles.fontBody`.
  2. **Countdown & Stat Cards**:
     - [NextTripCard](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/next_trip_card.dart): Switched big days countdown number from `fontHeading` (`Playfair Display`) to `fontBody` (`DM Sans`).
     - [PackingScreen](file:///d:/Spencer/Downloads/tara_travel/lib/features/packing/packing_screen.dart): Switched packing completion percentage (`$percent%`) from `fontHeading` to `fontBody`.
     - [StopDetailSheet](file:///d:/Spencer/Downloads/tara_travel/lib/features/itinerary/widgets/stop_detail_sheet.dart): Switched estimated time of arrival readout (`formattedEta`) from `fontHeading` to `fontBody`.
  3. **Financial & Budget Modules**:
     - [PersonalTripBudgetHeroCard](file:///d:/Spencer/Downloads/tara_travel/lib/features/budget/widgets/personal_trip_budget_hero_card.dart): Switched big total budget and remaining numbers to `fontBody`.
     - [BudgetOverviewCard](file:///d:/Spencer/Downloads/tara_travel/lib/features/budget/widgets/budget_overview_card.dart): Switched total budget and remaining numbers to `fontBody`.
     - [TripBudgetHeroCard](file:///d:/Spencer/Downloads/tara_travel/lib/features/budget/widgets/trip_budget_hero_card.dart): Switched total budget amount readout to `fontBody`.
     - [DailyPacingCard](file:///d:/Spencer/Downloads/tara_travel/lib/features/budget/widgets/daily_pacing_card.dart): Switched daily safe allowance readout to `fontBody`.
     - [PersonalAllowanceCard](file:///d:/Spencer/Downloads/tara_travel/lib/features/budget/widgets/personal_allowance_card.dart): Switched total allowance figure to `fontBody`.
     - [ChatEmbedCards](file:///d:/Spencer/Downloads/tara_travel/lib/features/chat/widgets/chat_embed_cards.dart): Switched formatted expense amounts in chat card and detail sheet to `fontBody`.
- **Target Files**:
  - `lib/core/theme/app_text_styles.dart` [MODIFIED]
  - `lib/features/home/widgets/next_trip_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/personal_trip_budget_hero_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/budget_overview_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/trip_budget_hero_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/daily_pacing_card.dart` [MODIFIED]
  - `lib/features/budget/widgets/personal_allowance_card.dart` [MODIFIED]
  - `lib/features/chat/widgets/chat_embed_cards.dart` [MODIFIED]
  - `lib/features/itinerary/widgets/stop_detail_sheet.dart` [MODIFIED]
  - `lib/features/packing/packing_screen.dart` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - Code review and verification completed. All numeric readouts confirmed on `AppTextStyles.fontBody` (`DM Sans`).

---

### `IMP-090` — 2026-09-05: TripStatus Enum, Dedicated Ongoing Section & Lifecycle Integration
- **Description**: Centralized dynamic trip status across the application with the introduction of the canonical `TripStatus` enum, added a dedicated `ONGOING` section to `TripsScreen`, introduced `tripStatusProvider`, prioritized ongoing trips in `activeTripProvider`, and enriched `NextTripCard` with real-time day counters.
- **Architectural Implementation**:
  1. **Canonical `TripStatus` Enum & Dynamic Getters (`TripModel`)**:
     - Introduced enum `TripStatus { draft, planning, ongoing, completed }` with human-readable `.label`.
     - Created `trip.status` getter evaluating `isDraft`, `isArchived`, `fromDate`, and `toDate` against current calendar day.
     - Added convenience boolean getters: `isPlanning`, `isOngoing`, and `isCompleted`.
  2. **Dedicated ONGOING Section (`TripsScreen`)**:
     - Upgraded trip list partitioning from 3 to 4 canonical categories: `DRAFTS`, `ONGOING`, `UPCOMING`, and `PAST TRIPS`.
     - Active ongoing trips are now pinned prominently at the top of the trips feed.
     - Enriched `_TripListCard` with a dedicated green `'Ongoing'` badge (`AppColors.greenBg` / `AppColors.green`) when `trip.isOngoing`.
     - Cleaned up unused variables and inline date math.
  3. **Reactive Providers (`trip_provider.dart`)**:
     - Added `tripStatusProvider = Provider.family<TripStatus, TripModel>((ref, trip) => trip.status)` for reactive status listening.
     - Updated `activeTripProvider` fallback ordering to prioritize `ongoing` trips first, then upcoming `planning` trips, ensuring travelers actively on vacation immediately see their ongoing trip on the Home screen.
  4. **Home Screen & Detail Integration**:
     - `NextTripCard`: Displays `ONGOING TRIP` pill badge with green dot and transforms the countdown into a live day counter (`Day X of Y days` / `Day of trip`), as well as in the collapsed app bar header.
     - `TripDetailScreen`: Replaced inline date calculations with `trip.isOngoing` and updated status badge label to `'Ongoing'`.
- **Target Files**:
  - `lib/core/models/trip_model.dart` [MODIFIED]
  - `lib/core/providers/trip_provider.dart` [MODIFIED]
  - `lib/features/trips/trips_screen.dart` [MODIFIED]
  - `lib/features/home/widgets/next_trip_card.dart` [MODIFIED]
  - `lib/features/trip_detail/trip_detail_screen.dart` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - `dart analyze lib`: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-091` — 2026-09-05: Universal Responsive Layout Engine & Zero-Overflow Architecture (Plan 19)
- **Description**: Dynamically adapted all screens, modal bottom sheets, and dialogs across Tara Travel to any mobile phone dimension (from compact ~4.7″ devices like iPhone SE / 320–360dp Androids to tall flagships, foldables, and tablets) and accessibility text scaling, eliminating hardcoded viewport arithmetic and UI overflow errors.
- **Architectural Implementation**:
  1. **Global Text Scaler Bounds (`AppResponsive.clampedTextScaleBuilder`)**:
     - Clamped `MediaQuery.textScaler` between `0.85` and `1.20` at the root `MaterialApp.builder` in `lib/main.dart` to prevent extreme font sizes from breaking fixed-height chips, pills, and action docks.
  2. **Centralized Responsive Tokens & Context Extensions (`lib/core/theme/app_responsive.dart`)**:
     - Standard logical breakpoints: `compactWidth = 360`, `standardWidth = 414`, `tabletWidth = 600`.
     - Syntactic sugar getters on `BuildContext`: `context.responsiveHPad`, `context.isCompactPhone`, `context.topInset`, `context.bottomInset`, `context.keyboardHeight`.
     - Inset-aware sheet bounds: `context.sheetMaxHeight(fraction)` prevents sheet headers from colliding with notch/status bars.
     - Keyboard & gesture safe insets: `context.safeBottomPadding(base)` and `context.keyboardBottomPadding(base)`.
  3. **Hardcoded MediaQuery Arithmetic Eradication**:
     - Audited and refactored hardcoded viewport multipliers and raw padding calculations across 20+ files:
       - `lib/features/itinerary/widgets/stop_detail_sheet.dart`
       - `lib/features/itinerary/widgets/itinerary_map_sheet.dart`
       - `lib/features/itinerary/widgets/navigate_route_button.dart`
       - `lib/features/itinerary/itinerary_screen.dart`
       - `lib/features/packing/widgets/packing_template_modals.dart`
       - `lib/features/packing/widgets/ai_packing_dialog.dart`
       - `lib/features/packing/packing_screen.dart`
       - `lib/features/profile/profile_screen.dart`
       - `lib/features/chat/widgets/create_poll_sheet.dart`
       - `lib/features/chat/widgets/chat_attachment_picker_sheet.dart`
       - `lib/features/chat/chat_screen.dart`
       - `lib/features/home/widgets/quick_budget_sheet.dart`
       - `lib/features/home/home_screen.dart`
       - `lib/features/navigation/navigation_screen.dart`
       - `lib/features/navigation/live_navigation_screen.dart`
       - `lib/features/navigation/widgets/nav_panels.dart`
       - `lib/features/navigation/widgets/group_tracker_tab.dart`
       - `lib/features/navigation/widgets/privacy_control_sheet.dart`
       - `lib/features/navigation/widgets/sos_emergency_modal.dart`
       - `lib/features/navigation/widgets/proximity_alert_tab.dart`
       - `lib/features/navigation/widgets/navigate_to_member_sheet.dart`
       - `lib/features/navigation/widgets/arrived_tab.dart`
       - `lib/features/explore/explore_screen.dart`
       - `lib/features/friends/friends_screen.dart`
       - `lib/features/friends/widgets/friend_list_item.dart`
       - `lib/features/members/members_screen.dart`
       - `lib/features/notifications/notifications_screen.dart`
       - `lib/features/trips/widgets/join_trip_modal.dart`
       - `lib/features/trip_detail/trip_detail_screen.dart`
       - `lib/features/create_trip/steps/transport_step.dart`
       - `lib/features/create_trip/steps/budget_step.dart`
       - `lib/features/budget/budget_screen.dart`
       - `lib/features/budget/widgets/set_allowance_sheet.dart`
       - `lib/core/widgets/inputs/map_pin_picker_modal.dart`
       - `lib/core/widgets/multi_member_picker_sheet.dart`
       - `lib/core/widgets/share/share_trip_modal.dart`
       - `lib/features/activity/activity_log_screen.dart`
- **Target Files**:
  - `lib/core/theme/app_responsive.dart` [NEW]
  - `lib/main.dart` [MODIFIED]
  - 37 UI feature and widget files [MODIFIED]
  - `docs/UPCOMING_PLANS.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - `flutter analyze --no-pub`: **No issues found! (0 errors, 0 warnings)**.

---

### `IMP-092` — 2026-09-05: Tri-Modal Land Transport Finalization (Private, Commute, Rental) & Air/Sea Elimination (Plan 6)
- **Description**: Formally finalized Tara Travel's transport specification and roadmap in `docs/UPCOMING_PLANS.md` and `docs/MEMORY.md` into a strictly land-first **Tri-Modal Transport Architecture** (`private`, `commute`, `rental`), while establishing a permanent architectural negative constraint against air (`plane`, flights, airport hubs) and sea (`ferry`, shipping lines, boat piers) modes.
- **Architectural Specification**:
  1. **Ground-Truth Negative Invariant ("No Sea or Plane")**:
     - Complete elimination of air and maritime travel concepts from Tara Travel's land-focused Philippines itinerary engine.
     - Deprecated and scheduled removal of airport presets (NAIA, Clark, MCIA) and seaport presets (Batangas Port, North Harbor, Cebu Pier 1) in favor of major land bus/transit hubs (PITX, Cubao Bus Port, Buendia Terminal, Dau Terminal, Baguio Grand Terminal).
     - Removed flight number (`_flightCtrl`), pier name (`_pierCtrl`), and airline metadata tracking.
  2. **Three Finalized Land Modes**:
     - **`private` (Personal Vehicle / Convoy)**: Own vehicle (car, SUV, motorcycle, bicycle) managed via User Profile "My Garage / My Vehicles", with real-time DOE fuel price monitoring via Supabase Edge Function (`fetch-fuel-prices`), automated $\text{Distance} / \text{km/L}$ fuel calculation, and group gas/toll splitting.
     - **`commute` (Public Transit)**: Public land transit (buses, jeepneys/e-jeeps, tricycles, UV Express) with land transit departure hubs and per-pax fare estimation ($\text{Fare} \times \text{Pax Count}$).
     - **`rental` (Hired / Chartered Vehicle)**: Tourist van hire (HiAce, Urvan) or car rental with daily contract rates ($\text{Rate} \times \text{Days}$), driver inclusion/allowance toggles, and fuel policy toggles (included vs group gas split).
  3. **Data Model & Schema Alignment**:
     - `trips.transport_mode` constrained to `'private' | 'commute' | 'rental'`.
     - `trips.transport_meta` defined with structured JSONB contracts per mode.
- **Target Files**:
  - `docs/UPCOMING_PLANS.md` [MODIFIED]
  - `docs/MEMORY.md` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
- **Verification**:
  - Text pattern scans confirmed zero active references to flights, ferries, or piers across the updated roadmap.

---

### `IMP-093` — 2026-09-05: Home Screen Trip Card Member Avatar Section Removal
- **Description**: Removed the member avatar stack section from the trip cards (`TripCard`) on the Home screen to declutter the card hierarchy and remove redundant avatar rendering in favor of the dedicated `PEOPLE` stat box and quick-action `Members` modal hub.
- **Architectural Specification**:
  1. **UI Clean-up & Decluttering**:
     - Removed the overlapping member avatars row (`MemberAvatarCircle` stack) located between the budget progress section and the quick action button bar in `TripCard._buildUpcoming`.
     - Standardized vertical spacing with a single `SizedBox(height: 14)` separating the budget bar from the action buttons.
  2. **Dead Code & Allocation Elimination**:
     - Removed `final List<TravelerInfo>? travelers;` from `TripCard` and its constructors (`upcoming`, `draft`).
     - Removed unused `MemberAvatarCircle` import from `trip_card.dart`.
     - Dropped local helper classes `TravelerInfo` and `TravelerData`.
     - Removed redundant `trip.members.map((member) => TravelerInfo(...))` object creation on every `_HomeTripCardItem` widget rebuild in `home_screen.dart`.
- **Target Files**:
  - `lib/features/home/widgets/trip_card.dart` [MODIFIED]
  - `lib/features/home/home_screen.dart` [MODIFIED]
  - `docs/IMPLEMENTATION_MEMORY.md` [MODIFIED]
  - `docs/CHANGELOG.md` [MODIFIED]
- **Verification**:
  - `flutter analyze --no-pub`: **No issues found! (0 errors, 0 warnings)**.








