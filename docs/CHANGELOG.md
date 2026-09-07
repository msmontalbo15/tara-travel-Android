# Tara Travel - Version Changelog

> Auto-generated from IMPLEMENTATION_MEMORY.md + git log
> Last updated: **2026-09-07 23:42 PHT**

---

## 2026-07-13

- **IMP-001** (Core / UI Scaffold): Project genesis, directory architecture, Material 3 theme & Brand Design tokens.

## 2026-07-30

- **IMP-002** (Supabase Migration 001): Initial database schema (users, trips, members, stops, expenses, packing).

## 2026-08-03

- **IMP-003** (Supabase Migration 002): Real data support, `member_locations`, Google Maps live presence integration.

## 2026-08-07

- **IMP-004** (Supabase Migration 003): Dev seed data fixtures for Philippine destinations & sample itineraries.

## 2026-08-12

- **IMP-005** (Supabase Migration 005): Realtime group chat architecture with Sembast write-through caching.

## 2026-08-14

- **IMP-006** (Supabase Migration 006): Auth trigger automation (`handle_new_user`) & Google Sign-In token exchange.

## 2026-08-17

- **IMP-007** (Supabase Migration 007): Collaborative itinerary stop voting system (`public.stop_votes`).

## 2026-08-18

- **IMP-008** (Supabase Migration 008): 6-character alphanumeric invite code generator & `join_trip_by_code` RPC.

## 2026-08-19

- **IMP-010** (Supabase Migration 010): RLS anti-recursion engine & `is_trip_member` security definer.
- **IMP-009** (Supabase Migration 009): Error-resilient user auto-provisioning trigger with fallback metadata.

## 2026-08-20

- **IMP-011** (Supabase Migration 011): Transport metadata sync & edge-to-edge system navigation across 17 screens.

## 2026-08-21

- **IMP-012** (Supabase Migration 012): Surname privacy obfuscation (`hide_surname`) & `formatDisplayName` formatter.

## 2026-08-22

- **IMP-013** (Supabase Migration 013): Global RLS security definers (`user_owns_trip`, `user_can_access_trip`).

## 2026-08-23

- **IMP-014** (Supabase Migration 014): Column normalization (`booking_ref`, `departure_point/lat/lng`, member status).

## 2026-08-24

- **IMP-039** (UI / Empty-State): "No Trip Created" premium empty-state experience: `EmptyTripHeroCard`, `StarterTemplatesCarousel`, shared `showJoinTripModal`, prefill support in `CreateTripFlow`.
- **IMP-021** (Design Patterns / REST API): Created `SOFTWARE_DESIGN_PATTERNS.md` defining 10 Core API guidelines & Flutter architecture patterns.
- **IMP-020** (Architecture Memory): Master `MEMORY.md`, system flow specs & continuous memory synchronization protocol.
- **IMP-019** (Offline Engine): Offline-first sync queue (`OfflineSyncQueue`) & auto-flushing `SyncManager`.
- **IMP-018** (Auth / Session): Cold-start session hydration & per-user Sembast database partitioning.
- **IMP-017** (Security / Keystore): 3-Layer encryption engine (RSA-2048 + AES-256-GCM + TLS 1.3) for sensitive data.
- **IMP-016** (Supabase Migration 016): Complete CRUD RLS policies for `trips` and `trip_members`.
- **IMP-015** (Supabase Migration 015): Schema cleanup: dropped legacy/unused columns & consolidated `friends` table.

## 2026-08-25

- **IMP-047** (Itinerary Functional Add Day & Date Extension): Fully functional Add Day action via DayStrip (+ Day) and DayActionsSheet, with dynamic date calculation and trip end_date auto-extension.
- **IMP-047** (Itinerary / Supabase Sync): Permission-gated Itinerary Day Deletion (Organizers & Navigators), multi-day check, batch stop deletion (`deleteStops`), and remote day re-indexing synchronization.
- **IMP-046** (Multi-Member Assignment Suite): Multi-member assignments on packing items & itinerary stops, batch role assignments, and multi-member expense splitting.
- **IMP-045** (Comprehensive Itinerary Power Suite): Transit conflict detection, live roll call sheet, 1-tap cost-to-expense, and day schedule manipulation.
- **IMP-043** (Member Lifecycle / Notifications): Organizer approval workflow, member removal, voluntary trip departure, and automated notification triggers.
- **IMP-042** (UI / Responsiveness): Mobile Resolution & Layout Responsiveness Hardening across 7 core screens.
- **IMP-041** (Provider / State): Active Trip Archived Fallback Guard in `activeTripProvider`.

## 2026-08-26

- **IMP-051** (Real-time Friend Presence): `UserPresenceService` with heartbeat & lifecycle observer, `friendsRealtimePresenceProvider`, dynamic online calculation (`isCurrentlyOnline`, `presenceStatusText`), and interactive online friend filtering.
- **IMP-050** (Social Graph & Friend Module): 3-tab modern Friends UI (My Friends, Requests, Find Friends), bidirectional friend status resolution, live user preview search, QR sharing, request management, and trip invitation integration.
- **IMP-049** (Member Roles & Security RPC): Atomic member role assignment via `update_member_roles` RPC, `user_is_trip_organizer` RLS recursion helper, extended `trip_members_update` policy, and reactive UI state invalidation.
- **IMP-048** (Maps & Live Tracking): Complete open-source migration to `flutter_map` (OSM), PostGIS live tracking (`004_postgis_live_tracking.sql`), `LocationTrackingService` with offline queue, `GroupRideSyncService` with exponential backoff, and Philippine `Nominatim` geocoding.

## 2026-08-27

- **IMP-057** (Itinerary / Multi-Stop Route Engine): Advanced Multi-Stop Route Construction engine: smart Title+Location target geocoding, GPS origin prefill, remaining-vs-all stops scope selector, dynamic travel mode mapping (car, motorcycle, walking, transit, bike), interactive timeline preview sheet, and one-tap link sharing.
- **IMP-056** (Itinerary / Multi-Stop Navigation): Fixed `NavigateRouteButton` multi-stop navigation to directly launch Google Maps with all intermediate waypoints and final destination instead of single-point `geo:` fallback.
- **IMP-055** (UI / Home Hero Clean-up): Removed budget tracker section and unused imports from homepage header hero (`NextTripCard`), recalibrating `_HomeHeaderDelegate` max extent height.
- **IMP-054** (Itinerary / Next Destination Banner): Made `ItineraryFulfillmentBanner` (the progress % and N of N stops visited card) interactive to open Google Maps for the next uncompleted stop, with fallback search and visual 'Go' navigation CTA button.
- **IMP-053** (UI / Home Trip Budget Bar): Functional & interactive trip card budget bar, `QuickBudgetSheet` modal editor, dynamic warning states (Warning Amber 70%+, Exceeded Red 100%+), remaining/over budget calculation, and NextTripCard budget tracker integration.
- **IMP-052** (Packing / Custom Sub-Categories): Custom sub-categories pill/tab filter system in `_PackingCategoryCard`, `sub_category` schema sync in `PackingRepository`, preset suggestions, item tag chips & inline add integration.

## 2026-08-28

- **IMP-062** (Navigation / Live Location & Convoy Tracking): Real-Time Group Live Location Sharing, Convoy Tracking & Direct Member Navigation (IDEA-003): `LocationBroadcastService` over Supabase Realtime ephemeral broadcast channels, adaptive GPS polling (5s/15s/60s), `NavigateToMemberSheet` (in-app routing & external GPS launch), `ConvoyAlertBanner` separation warnings, `SosEmergencyModal` panic beacons, and `PrivacyControlSheet` (Ghost Mode & approximate location fuzzing).
- **IMP-061** (Itinerary / Progressive Disclosure & Action Hub): Streamlined Itinerary Architecture (IDEA-002): `DayInsightsHeader` collapsible accordion, `ItineraryActionSheet` unified "⋯" more hub, `ItineraryBottomDock` floating action bar, `StopDetailSheet`, `ItineraryMapSheet`, collapsible `SmartSuggestionChips`, and automated GPS arrival geofencing engine.
- **IMP-060** (UI / Standardized Feedback System): Unified Feedback System (IDEA-001): `AppFeedback`, `AppDialog`, `AppBanner`, semantic `FeedbackType`, brand token theme integration, and 100% migration across 11+ UI feature screens/widgets.
- **IMP-059** (Trips / Invite Code Join Flow): Hardened Join Trip by Invite Code workflow: regex sanitization in `InviteCodeGenerator`, FK pre-flight user row provision in `TripRepository`, resilient RPC parsing & direct fallback, `019_fix_join_trip_by_code.sql` migration, and reactive `_JoinTripSheet` (ConsumerStatefulWidget).
- **IMP-058** (Social / Camera QR & Profile ID): Live Camera QR Scanner modal (`QrScannerModal`) via `mobile_scanner`, point-and-shoot camera friend scanning with auto-lookup and prefill in `friends_screen.dart`, and User ID / Friend Code badge chips and QR modal launch in `profile_screen.dart`. [commit:e610c86](https://github.com/msmontalbo15/tara-travel-Android/commit/e610c86)

## 2026-08-31

- **IMP-068** (Itinerary / Ultra-Simplified Stop Cards & Presence Hub): Ultra-Simplified Itinerary Stop Cards & Unified "Mark as Arrived" Presence Hub (IDEA-007): stripped StopCard to single Navigate CTA, added top-right edit & hero self check-in to StopDetailSheet, built inline companion arrival roster with batch toggle, and retired RollCallSheet.
- **IMP-067** (Auth / Onboarding Bypass & Account State Guard): Fixed onboarding resurfacing for existing accounts by adding `isAccountFullySet` fallback checks, auto-recovering `hasCompletedOnboarding` in `ProfileNotifier`, and updating `AuthGate` & `OnboardingScreen` lifecycle guards.
- **IMP-066** (UI / Shared TripTypeCarousel & Type Precision): Extracted shared `TripTypeCarousel` widget (DRY) for both Create and Edit Trip flows; dropped PostgreSQL and Dart enum whitelists to support all 16 `AppTripTypes`.
- **IMP-065** (Trips / Theme & Visual Consolidation): Unified trip type, theme accent color, and emoji under canonical `tripType` and `AppTripTypes`. Dropped redundant `cover_color` and `cover_emoji` columns via migration 020.

## 2026-09-01

- **IMP-073** (UI & Itinerary / Driver-Ready Touch Targets & Enriched Buttons): Scaled up all itinerary interactive CTA buttons (StopCard Navigate button, StopDetailSheet Navigate Maps / Expense / Edit / Slide to Arrive / Member toggle, NavigateRouteButton, DayStrip tabs, and ItineraryBottomDock) for effortless driver and one-handed thumb tapping on the road.
- **IMP-072** (UI & Home / Trip Card Date Abbreviation & Budget Clean-up): Abbreviated date ranges on home trip cards, replaced middle stat box with non-clickable ITINERARY (visited/total), and converted budget tracker to an informational progress bar without Manage >.
- **IMP-071** (UI & Navigation / Floating Dock Live Nav Migration): Relocated Live Nav trigger to ItineraryBottomDock, decluttered NextTripCard/TripCard action bars, and optimized TurnCard with external Google Maps navigation handoff.
- **IMP-070** (UI & Itinerary / Driver-Ready Slide-to-Arrive Bottom Dock): Relocated arrival control to a fixed bottom dock in StopDetailSheet featuring SlideToArriveButton with spring physics, haptics, and high-contrast confirmed arrival status with Undo. [commit:9821ae6](https://github.com/msmontalbo15/tara-travel-Android/commit/9821ae6)
- **IMP-069** (Database & Itinerary / Stop Votes & Status Retirement): Dropped public.stop_votes table and status column on itinerary_stops (Migration 021). Removed StopStatus enum, voting models/repositories/providers, and status action bars.

## 2026-09-02

- **IMP-075** (UI & Itinerary / Stop Detail Sheet Live GPS ETA & Stop Sharing): Implemented real-time Estimated Time of Arrival (Live GPS ETA & inter-stop Haversine routing fallback) and 1-tap Stop Details Sharing (`share_plus`) inside `StopDetailSheet`, with 6-pillar information hierarchy and `previousStop` contextual routing handoff.
- **IMP-074** (UI & Home / Quick-Action Red Notification Dot Indicator): Implemented IDEA-010: Contextual Red Notification Dot Indicator (`🔴`) on TripCard quick action buttons for new or modified content inside (Itinerary, Packing, Members, Expenses, Chat) using Keystore-backed `ModuleViewTrackerService`, self-action exemption, and reactive Riverpod stream diffing.

## 2026-09-03

- **IMP-077** (UI / Brand-Aligned Back Button Standardization): Standardized and upgraded `AppBackButton` with Tara Travel brand tokens (12px radius, frosted glass, light, brand, and ghost variants) and replaced one-off back buttons across all screens (Packing, Friends, Navigation, Live Navigation, Chat, Notifications, Activity Log, Create Trip, and MapPinPicker). [commit:3e429ee](https://github.com/msmontalbo15/tara-travel-Android/commit/3e429ee)

## 2026-09-04

- **IMP-088** (Typography & Brand Identity Standardization): Formalized system branding font tokens in `AppTextStyles` (`fontHeading`, `fontBody`, `fontSerifFallback`), wired Georgia serif fallback for display headlines, splash "Tara TRAVEL" branding, and Home greeting name, aligned `AppTheme` light theme definitions, and synchronized `MEMORY.md`.
- **IMP-085** (Polls / Winner Card & Detail Sheet): Replaced flat `_WinnerActions` resolve section with premium gradient `_WinnerCard` (green gradient, trophy badge, vote %, voter chips) that opens `_WinnerDetailSheet` bottom sheet with ranked results breakdown, animated progress bars, voter lists, and quick-action resolution buttons.
- **IMP-084** (Polls & Votes / Bidirectional Vote Undo): Full vote undo engine: optimistic in-memory toggle and rollback in `PollsNotifier`, `getPollsAndVotesRaw` synchronous hydration, and clean tap-to-toggle unvoting on poll options without UI clutter.
- **IMP-083** (Chat, Polls & Activity Hub (IDEA-004)): Full rich travel chat hub: migration 025 (metadata & reactions jsonb), interactive rich embeds (Itinerary stops, Expense requests, Packing alerts, GPS location pin drops, Media photos, Tara Bot briefings), crowdsourced poll suggestions, emoji reactions bar with haptic toggle, and offline outbox queue. [commit:721da0a](https://github.com/msmontalbo15/tara-travel-Android/commit/721da0a)
- **IMP-082** (Profile & Avatars / Storage Pipeline): Full unification of user profile photos and companion avatars across 8+ screens via Supabase Storage bucket `avatars` and `MemberAvatarCircle`.
- **IMP-080** (UI & Home / Quick Actions Grid): Refined Quick Actions Grid layout, card dimensions, and aesthetics: calibrated `childAspectRatio` from 1.34 to 1.52, compact padding, 30x30 icon containers, crisp typography, and responsive `_PulsingGuide` border alignment.
- **IMP-079** (Architecture & UI Standards): Formalized Mobile Responsive Layout Standards and Strict Overflow Prevention Patterns in `SOFTWARE_DESIGN_PATTERNS.md` & `MEMORY.md` (bounded flex, scrollable viewports, dynamic font ellipsis, and zero RenderFlex overflow tolerance).
- **IMP-078** (Chat, Polls & Firebase FCM): Interactive In-Chat Travel Polls, real-time live vote sync, one-tap winner resolution to itinerary, pinned announcements drawer, quick travel action chips, branded Coral gradient UI, and Firebase FCM notification service.

## 2026-09-05

- **IMP-094** (Architecture & DevOps / Supabase Versioning, Direct OTA & CI/CD Pipeline (Plan 17)): Supabase `app_versions` remote config, 3-tier update modals (`ForceUpdateScreen`, `SoftUpdateSheet`, `MaintenanceModeScreen`), Settings update checker tile with notification pill, `ApkDownloadInstaller`, and automated GitHub Actions CI/CD release workflow (`auto_release.yml`).
- **IMP-093** (UI / Home Trip Card Avatar Removal): Removed the overlapping member avatar section (`MemberAvatarCircle` stack row) from `TripCard` on the Home screen, eliminating redundant `travelers` mapping and dead code.
- **IMP-091** (Architecture & UI / Universal Responsive Layout Engine (Plan 19)): Dynamic screen-size adaptation (iPhone SE to large foldables), global textScaler clamp (0.85-1.20), centralized AppResponsive tokens/extensions, zero hardcoded MediaQuery arithmetic across 37+ files.

## 2026-09-07

- **IMP-100** (Documentation / Token Limit Optimization & Redundant File Consolidation): Consolidated redundant Markdown files across repository to maximize AI agent token efficiency: merged `DEV_IDEA.md` into `UPCOMING_PLANS.md`, merged `SOFTWARE_DESIGN_PATTERNS.md` and `Analyze.md` into `MEMORY.md` (Section 30), removed redundant empty root `CHANGELOG.md`, updated `.agents/workflows/run.md`, saving ~42,000+ tokens (~172 KB).
- **IMP-099** (Trip Detail / 5-Tab Floating Nav Dock): Frosted-glass floating bottom dock (Itinerary, Packing, Members, Expenses, Chat), removed redundant in-scroll quick actions grid, pruned unused providers and listeners.
- **IMP-098** (Trip Detail / Command Center & HUD): OngoingTripHud hero card with next stop navigation & check-in, DestinationWeatherWidget with smart municipality extraction, PrivacyInviteCodeWidget, and OfflineReadOnlyBanner.

*Generated by tools/generate_changelog.ps1*

