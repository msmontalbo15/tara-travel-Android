# Tara Travel — Codebase Analysis & Agent Memory Index

> **Purpose**: Pre-indexed codebase map for agent consumption. Read this file
> first to avoid re-scanning files and burning tokens. Last synced:
> **2026-09-01**.

---

## 1. Project Metadata

| Key               | Value                                          |
| ----------------- | ---------------------------------------------- |
| **Package**       | `tara_travel`                                  |
| **Version**       | 1.0.0+1                                       |
| **SDK**           | Dart ≥3.2.0 <4.0.0                            |
| **State Mgmt**    | `flutter_riverpod` ^3.3.1                      |
| **Backend**       | Supabase (PostgreSQL + RLS + Edge Functions)   |
| **Auth**          | `supabase_flutter` + `google_sign_in`          |
| **Encryption**    | 3-Layer: RSA-2048 + AES-256-GCM + TLS 1.3     |
| **Maps**          | `flutter_map` ^7.0.2 + `latlong2` + `geolocator` |
| **Total Files**   | 185 Dart files                                 |
| **Total Size**    | ~2.47 MB source code                           |
| **Entry Point**   | `lib/main.dart`                                |

---

## 2. Dependency Manifest (pubspec.yaml)

### Runtime Dependencies

| Package                 | Version  | Purpose                                    |
| ----------------------- | -------- | ------------------------------------------ |
| `supabase_flutter`      | ^2.12.2  | Backend client (auth, DB, realtime, storage) |
| `flutter_riverpod`      | ^3.3.1   | State management (Notifier/FutureProvider)  |
| `flutter_map`           | ^7.0.2   | OpenStreetMap tile rendering               |
| `latlong2`              | ^0.9.1   | Lat/Lng coordinate model                   |
| `geolocator`            | ^14.0.1  | GPS position stream                        |
| `location`              | ^8.0.1   | Location permissions + background tracking |
| `dio`                   | ^5.9.2   | HTTP client (gateway interceptor)          |
| `flutter_dotenv`        | ^6.0.0   | .env secrets loader                        |
| `google_sign_in`        | ^6.2.1   | Google OAuth                               |
| `flutter_secure_storage`| ^10.3.1  | AES-256 keystore (EncryptedSharedPrefs)     |
| `local_auth`            | ^2.3.0   | Biometric auth (Face ID / fingerprint)     |
| `encrypt`               | ^5.0.3   | AES-256-GCM / RSA encryption              |
| `pointycastle`          | ^3.9.1   | Cryptographic primitives                   |
| `crypto`                | ^3.0.6   | SHA-256 hashing                            |
| `image_picker`          | ^1.2.3   | Camera / gallery photo selection           |
| `share_plus`            | ^13.0.0  | Native share sheet                         |
| `qr_flutter`            | ^4.1.0   | QR code rendering                          |
| `mobile_scanner`        | ^7.4.0   | QR/barcode camera scanner                  |
| `url_launcher`          | ^6.3.2   | External URL open                          |
| `cached_network_image`  | ^3.4.1   | Cached avatar/photo loading                |
| `connectivity_plus`     | ^6.1.3   | Network state detection                    |
| `uuid`                  | ^4.5.1   | UUID generation                            |
| `intl`                  | ^0.20.2  | Date/number formatting                     |
| `lottie`                | ^3.3.3   | Lottie animation playback                  |
| `font_awesome_flutter`  | ^11.0.0  | FA icon pack                               |
| `path_provider`         | ^2.1.5   | App document directory                     |
| `path`                  | ^1.9.0   | Path manipulation                          |
| `permission_handler`    | ^11.3.1  | Runtime permission requests                |
| `http`                  | ^1.6.0   | Simple HTTP client                         |
| `logger`                | ^2.7.0   | Structured logging                         |
| `add_2_calendar`        | 3.0.1    | System calendar event insertion            |

### Dev Dependencies

| Package                  | Purpose                      |
| ------------------------ | ---------------------------- |
| `flutter_native_splash`  | Splash screen generation     |
| `flutter_launcher_icons` | App icon generation          |
| `build_runner`           | Code generation runner       |
| `flutter_lints`          | Lint rules                   |

---

## 3. Architecture Overview

```
lib/
├── main.dart                    # App bootstrap (env → Supabase → session → encryption → runApp)
├── core/                        # Shared infrastructure (no feature imports)
│   ├── auth/                    # Auth layer (session, biometric, MPIN)
│   ├── config/                  # Feature flags
│   ├── constants/               # Trip types, map tiles
│   ├── data/                    # PH location data (offline geocoding)
│   ├── database/                # (reserved — no Sembast for trips)
│   ├── logic/                   # Settlement calculator
│   ├── middleware/               # Gateway Dio client, interceptor, audit logger, token service
│   ├── models/                  # 8 domain models
│   ├── providers/               # 15 Riverpod providers
│   ├── repositories/            # 8 Supabase repositories
│   ├── security/                # ThreeLayerEncryptionService
│   ├── services/                # 6 platform services
│   ├── theme/                   # AppColors, AppTextStyles, AppTheme
│   ├── utils/                   # Currency, invite codes, share formatting, JIT guard
│   └── widgets/                 # 20+ reusable widgets
├── features/                    # 17 feature modules (screen-level)
│   ├── activity/                # Activity log
│   ├── budget/                  # Budget & expenses
│   ├── chat/                    # Trip group chat
│   ├── create_trip/             # 4-step trip creation wizard
│   ├── explore/                 # Explore nearby/featured
│   ├── friends/                 # Friend list & requests
│   ├── home/                    # Home dashboard
│   ├── itinerary/               # Day-by-day itinerary planner
│   ├── members/                 # Trip member management
│   ├── navigation/              # Live GPS navigation & group tracking
│   ├── notifications/           # Push/local notifications
│   ├── onboarding/              # 7-step onboarding flow
│   ├── packing/                 # Packing checklist with AI suggestions
│   ├── profile/                 # User profile & settings
│   ├── splash/                  # Splash / Get Started screen
│   ├── trip_detail/             # Trip detail view & edit
│   └── trips/                   # All trips list
└── shared/                      # Cross-feature shared widgets
    └── widgets/
        └── trip_type_carousel.dart
```

---

## 4. Routing Table

All routes defined in `lib/main.dart` → `MaterialApp.routes`:

| Route            | Screen Class             | File                                                |
| ---------------- | ------------------------ | --------------------------------------------------- |
| `/`              | `SplashScreen`           | `features/splash/splash_screen.dart`                |
| `/onboarding`    | `OnboardingScreen`       | `features/onboarding/onboarding_screen.dart`        |
| `/home`          | `HomeScreen`             | `features/home/home_screen.dart`                    |
| `/create-trip`   | `CreateTripFlow`         | `features/create_trip/create_trip_flow.dart`         |
| `/notifications` | `NotificationsScreen`    | `features/notifications/notifications_screen.dart`   |
| `/budget`        | `BudgetScreen`           | `features/budget/budget_screen.dart`                |
| `/itinerary`     | `ItineraryScreen`        | `features/itinerary/itinerary_screen.dart`          |
| `/navigation`    | `LiveNavigationScreen`   | `features/navigation/live_navigation_screen.dart`   |
| `/packing`       | `PackingScreen`          | `features/packing/packing_screen.dart`              |
| `/members`       | `MembersScreen`          | `features/members/members_screen.dart`              |
| `/explore`       | `ExploreScreen`          | `features/explore/explore_screen.dart`              |
| `/profile`       | `ProfileScreen`          | `features/profile/profile_screen.dart`              |
| `/trip-detail`   | `TripDetailScreen`       | `features/trip_detail/trip_detail_screen.dart`      |
| `/activity`      | `ActivityLogScreen`      | `features/activity/activity_log_screen.dart`        |
| `/chat`          | `ChatScreen`             | `features/chat/chat_screen.dart`                    |
| `/trips`         | `TripsScreen`            | `features/trips/trips_screen.dart`                  |
| `/friends`       | `FriendsScreen`          | `features/friends/friends_screen.dart`              |

**Navigation Pattern**: `ref.read(selectedTripIdProvider.notifier).select(tripId)` → then `Navigator.pushNamed(context, '/trip-detail')`.

---

## 5. Domain Models

### 5.1 `TripModel` — `core/models/trip_model.dart` (239 lines)

| Field                | Type                        | DB Column           |
| -------------------- | --------------------------- | ------------------- |
| `id`                 | `String`                    | `id`                |
| `name`               | `String`                    | `name`              |
| `destination`        | `String`                    | `destination`       |
| `fromDate`           | `DateTime`                  | `start_date`        |
| `toDate`             | `DateTime`                  | `end_date`          |
| `tripType`           | `String`                    | `type`              |
| `totalBudget`        | `double`                    | `budget`            |
| `splitEqually`       | `bool`                      | `split_method`      |
| `members`            | `List<MemberModel>`         | `trip_members` join |
| `expenses`           | `List<ExpenseModel>`        | `expenses` join     |
| `isArchived`         | `bool`                      | `status`            |
| `isDraft`            | `bool`                      | `status`/`is_draft` |
| `inviteCode`         | `String`                    | `invite_code`       |
| `ownerId`            | `String?`                   | `owner_id`          |
| `departurePoint`     | `String?`                   | `departure_point`   |
| `departureLat`       | `double?`                   | `departure_lat`     |
| `departureLng`       | `double?`                   | `departure_lng`     |
| `departureMapUrl`    | `String?`                   | `departure_map_url` |
| `destinationDetails` | `Map<String, dynamic>?`     | `destination_details` (jsonb) |
| `transportMode`      | `String?`                   | `transport_mode`    |
| `transportMeta`      | `Map<String, dynamic>?`     | `transport_meta` (jsonb) |

**Computed**: `coverEmoji` / `coverColor` / `tripTypeOption` → resolved from `AppTripTypes.getOption(tripType)`.
**Methods**: `fromMap()`, `toMap()`, `toSupabaseInsert(ownerId)`, `copyWith()`.

### 5.2 `MemberModel` — `core/models/member_model.dart` (276 lines)

| Field                      | Type                  |
| -------------------------- | --------------------- |
| `id`                       | `String`              |
| `name`                     | `String`              |
| `initials`                 | `String`              |
| `color`                    | `Color`               |
| `roles`                    | `List<MemberRole>`    |
| `profilePhotoUrl`          | `String?`             |
| `isOnline`                 | `bool`                |
| `lastSeen`                 | `DateTime?`           |
| `isLocationSharingPaused`  | `bool`                |
| `gcashNumber`              | `String?`             |
| `gcashQrUrl`               | `String?`             |
| `status`                   | `MemberStatus`        |
| `hideSurname`              | `bool`                |

**Enums**: `MemberStatus { pending, approved, rejected }`, `MemberRole { organizer, treasurer, navigator, buyer, documenter, member }`.
**Extensions**: `MemberRoleDetails` (displayName, description, color), `MemberRolePermissions` (granular permission checks).
**Privacy**: `MemberModel.formatDisplayName(name, hideSurname:)` → "Juan Dela Cruz" → "Juan D."

### 5.3 `ItineraryStop` / `ItineraryDay` — `core/models/itinerary_model.dart` (395 lines)

**ItineraryStop fields**:

| Field                | Type                          |
| -------------------- | ----------------------------- |
| `id`                 | `String`                      |
| `title`              | `String`                      |
| `notes`              | `String?`                     |
| `type`               | `StopType`                    |
| `startTime`          | `TimeOfDay?`                  |
| `endTime`            | `TimeOfDay?`                  |
| `estimatedCost`      | `double?`                     |
| `assignedMemberIds`  | `List<String>`                |
| `location`           | `String?`                     |
| `lat`                | `double?`                     |
| `lng`                | `double?`                     |
| `confirmationNumber` | `String?`                     |
| `transportMode`      | `TransportMode?`              |
| `photoUrls`          | `List<String>`                |
| `attachmentUrls`     | `List<String>`                |
| `checkedInMembers`   | `Map<String, DateTime>`       |
| `visitedAt`          | `DateTime?`                   |
| `checkInPhotoUrls`   | `List<String>`                |

**Enums**: `StopType { hotel, activity, food, transport, custom }`, `TransportMode { car, motorcycle, commute, jeepney, tricycle, bus, vanHire, ferry, plane, bike, other }`, `TransportCategory { land, air, sea, eco }`.

**ItineraryDay**: `dayNumber`, `date`, `transport: TransportDetail?`, `stops: List<ItineraryStop>`.
**TransportDetail**: `mode`, `vehicleCount`, `departurePoint`, `departureLat/Lng`, `flightNumber`, `pierName`, `operatorName`, `bookingReference`, `estimatedDuration`, `gasCostShare`, `estimatedCost`, `splitGas`, `notes`.

### 5.4 `ExpenseModel` — `core/models/expense_model.dart` (75 lines)

| Field             | Type              | DB Column        |
| ----------------- | ----------------- | ---------------- |
| `id`              | `String`          | `id`             |
| `description`     | `String`          | `description`    |
| `amount`          | `double`          | `amount`         |
| `category`        | `ExpenseCategory` | `category`       |
| `paidById`        | `String`          | `paid_by_user_id`|
| `date`            | `DateTime`        | `created_at`     |
| `status`          | `ExpenseStatus`   | `status`         |
| `receiptPhotoUrl` | `String?`         | `receipt_url`    |
| `rejectionNote`   | `String?`         | `rejection_note` |

**Enums**: `ExpenseCategory { hotel, food, activities, transport, custom }`, `ExpenseStatus { pending, approved, rejected }`.

### 5.5 `PackingItem` / `PackingCategory` / `PackingTemplate` — `core/models/packing_model.dart` (541 lines)

**PackingItem**: `id`, `name`, `isChecked`, `isAiSuggested`, `isCritical`, `subCategory`, `assignedMemberIds: List<String>`, legacy single-member fields.
**PackingCategory**: `id`, `name`, `icon`, `color`, `items`, `isExpanded`, `isCustom`. Computed: `packedCount`, `progress`, `allPacked`, `subCategories`.
**PackingTemplate**: `id`, `name`, `description`, `icon`, `itemsByCategory: Map<String, List<String>>`, `isPrebuilt`. Has 4 prebuilt templates (Beach, Mountain, City, Road Trip).
**AiPackingEngine**: `generateSuggestions()` — weather-aware + destination-aware + transport-aware + duration-aware smart suggestions.

### 5.6 Other Models

| Model               | File                              | Fields                                         |
| -------------------- | --------------------------------- | ---------------------------------------------- |
| `FriendModel`        | `core/models/friend_model.dart`   | `id`, `name`, `email`, `initials`, `color`, `profilePhotoUrl`, `isOnline`, `lastSeen`, `status: FriendStatus`, `hideSurname` |
| `FriendshipModel`    | `core/models/friendship_model.dart`| `id`, `requesterId`, `receiverId`, `status: FriendshipStatus`, `createdAt` |
| `ActivityItem`       | `core/models/activity_model.dart` | `id`, `type: ActivityType`, `actorName`, `actorInitials`, `actorColor`, `description`, `timestamp` |
| `WeatherData`        | `core/models/weather_model.dart`  | `temperature`, `condition`, `conditionIcon`, `humidity`, `uvIndex`, `rainProbability`, `windSpeed`, `forecast: List<DayForecast>`, `hasAlert`, `alertMessage` |
| `DayForecast`        | `core/models/weather_model.dart`  | `date`, `tempMin`, `tempMax`, `condition`, `conditionIcon`, `rainProbability`, `uvIndex` |
| `ChecklistItemModel` | `core/models/checklist_model.dart`| `id`, `title`, `category`, `isPacked`, `assignedMemberId`, `isAiSuggested` |
| `NotificationModel`  | `features/notifications/models/notification_model.dart` | Push notification model |
| `NewTripModel`       | `features/create_trip/models/new_trip_model.dart` | Create trip wizard state |
| `NavigationModels`   | `features/navigation/models/navigation_models.dart` | Navigation state models |

---

## 6. Riverpod Provider Registry

### 6.1 Repository Providers (`core/providers/repository_providers.dart`)

| Provider                     | Type                  | Instance             |
| ---------------------------- | --------------------- | -------------------- |
| `authRepositoryProvider`     | `Provider<AuthRepository>`       | `AuthRepository()`   |
| `tripRepositoryProvider`     | `Provider<TripRepository>`       | `TripRepository()`   |
| `expenseRepositoryProvider`  | `Provider<ExpenseRepository>`    | `ExpenseRepository()` |
| `itineraryRepositoryProvider`| `Provider<ItineraryRepository>`  | `ItineraryRepository()` |
| `profileRepositoryProvider`  | `Provider<ProfileRepository>`    | `ProfileRepository()` |
| `packingRepositoryProvider`  | `Provider<PackingRepository>`    | `PackingRepository()` |
| `connectivityServiceProvider`| `Provider<ConnectivityService>`  | singleton            |

### 6.2 State Providers

| Provider                    | File                               | Type / Description                                  |
| --------------------------- | ---------------------------------- | --------------------------------------------------- |
| `selectedTripIdProvider`    | `core/providers/selected_trip_provider.dart` | `NotifierProvider<SelectedTripIdNotifier, String?>` — which trip is "open" |
| `selectedTripProvider`      | `core/providers/selected_trip_provider.dart` | `FutureProvider<TripModel?>` — resolved trip model   |
| `authNotifierProvider`      | `core/providers/auth_provider.dart`| Auth state notifier (wraps `AuthState`)              |
| `tripProvider`              | `core/providers/trip_provider.dart`| Trip list state                                      |
| `expenseProvider`           | `core/providers/expense_provider.dart` | Expense state                                    |
| `itineraryProvider`         | `core/providers/itinerary_provider.dart` | Itinerary state (days/stops CRUD)                |
| `profileProvider`           | `core/providers/profile_provider.dart` | User profile state                               |
| `packingProvider`           | `core/providers/packing_provider.dart` | Packing list state                               |
| `friendProvider`            | `core/providers/friend_provider.dart` | Friends list state                               |
| `chatProvider`              | `core/providers/chat_provider.dart` | Chat messages state                               |
| `activityProvider`          | `core/providers/activity_provider.dart` | Activity log state                              |
| `exploreProvider`           | `core/providers/explore_provider.dart` | Explore/discover state                           |
| `realtimeProvider`          | `core/providers/realtime_provider.dart` | Supabase realtime subscription                  |
| `groupTrackingProvider`     | `core/providers/group_tracking_provider.dart` | Group GPS tracking state                    |
| `tripWeatherProvider`       | `core/providers/trip_weather_provider.dart` | Weather forecast for trip                     |
| `navigationProvider`        | `features/navigation/providers/navigation_provider.dart` | Live navigation state          |

---

## 7. Repository Layer

| Repository              | File                                          | Supabase Tables Hit                |
| ----------------------- | --------------------------------------------- | ---------------------------------- |
| `AuthRepository`        | `core/repositories/auth_repository.dart`      | `auth.users`                       |
| `TripRepository`        | `core/repositories/trip_repository.dart`      | `trips`, `trip_members`            |
| `ExpenseRepository`     | `core/repositories/expense_repository.dart`   | `expenses`                         |
| `ItineraryRepository`   | `core/repositories/itinerary_repository.dart` | `itinerary_stops`                  |
| `ProfileRepository`     | `core/repositories/profile_repository.dart`   | `users` (public)                   |
| `PackingRepository`     | `core/repositories/packing_repository.dart`   | `packing_items`                    |
| `FriendRepository`      | `core/repositories/friend_repository.dart`    | `friends`                          |
| `ChatRepository`        | `core/repositories/chat_repository.dart`      | `trip_messages`                    |

---

## 8. Services Layer

| Service                        | File                                              | Purpose                               |
| ------------------------------ | ------------------------------------------------- | ------------------------------------- |
| `SecureSessionRepository`      | `core/auth/data/secure_session_repository.dart`   | Encrypted session persist/restore     |
| `BiometricService`             | `core/auth/services/biometric_service.dart`       | Face ID / fingerprint auth            |
| `MpinService`                  | `core/auth/services/mpin_service.dart`            | Mobile PIN authentication             |
| `ThreeLayerEncryptionService`  | `core/security/three_layer_encryption_service.dart` | RSA-2048 + AES-256-GCM key mgmt    |
| `ConnectivityService`          | `core/services/connectivity_service.dart`         | Network state monitoring              |
| `SupaService`                  | `core/services/supa_service.dart`                 | Supabase helper utilities             |
| `LocationTrackingService`      | `core/services/location_tracking_service.dart`    | GPS position stream management        |
| `LocationBroadcastService`     | `core/services/location_broadcast_service.dart`   | Broadcast location to group           |
| `GroupRideSyncService`         | `core/services/group_ride_sync_service.dart`      | Convoy / group ride synchronization   |
| `PhilippineGeocodingService`   | `core/services/philippine_geocoding_service.dart` | Offline PH reverse geocoding          |
| `UserPresenceService`          | `core/services/user_presence_service.dart`        | Online/offline heartbeat              |
| `AuditLogger`                  | `core/middleware/audit_logger.dart`               | Encrypted audit trail                 |
| `GatewayDioClient`             | `core/middleware/gateway_dio_client.dart`          | Dio HTTP client with interceptor      |
| `GatewayInterceptor`           | `core/middleware/gateway_interceptor.dart`         | Auth token injection / refresh        |
| `TokenService`                 | `core/middleware/token_service.dart`               | JWT token management                  |

---

## 9. Theme System

### Colors (`core/theme/app_colors.dart`)

| Token               | Hex         | Usage                    |
| -------------------- | ----------- | ------------------------ |
| `primary`            | `#D85A30`   | Coral — primary CTA      |
| `primaryLight`       | `#F0997B`   | Light Coral — secondary  |
| `sand`               | `#FAECE7`   | Sand — backgrounds       |
| `amber`              | `#EF9F27`   | Sunset — accents         |
| `deepEarth`          | `#2C1A14`   | Deep Earth — dark        |
| `surfaceLight`       | `#F7F4F0`   | Warm White — page bg     |
| `textPrimary`        | `#1A1A1A`   | Primary text             |
| `textSecondary`      | `#888888`   | Secondary text           |
| `cardBorder`         | `#E8E8E8`   | Card/input border        |
| `green`              | `#3B6D11`   | Success                  |
| `red`                | `#EF4444`   | Error/danger             |
| `blue`               | `#3B82F6`   | Info                     |
| `purple`             | `#8B5CF6`   | Accent                   |

### Typography (`core/theme/app_text_styles.dart`)

| Style         | Font             | Size | Weight | Usage            |
| ------------- | ---------------- | ---- | ------ | ---------------- |
| `headline1`   | Playfair Display | 32   | Bold   | Page titles      |
| `headline2`   | Playfair Display | 26   | Bold   | Section headers  |
| `headline3`   | Playfair Display | 22   | Bold   | Card titles      |
| `tagline`     | Playfair Display | 15   | Italic | Taglines         |
| `sectionLabel`| DM Sans          | 10   | W600   | Section labels   |
| `bodyLarge`   | DM Sans          | 16   | W500   | Body text        |
| `bodyMedium`  | DM Sans          | 14   | W400   | Secondary body   |
| `bodySmall`   | DM Sans          | 13   | W400   | Small body       |
| `caption`     | DM Sans          | 11   | W500   | Captions         |
| `button`      | DM Sans          | 14   | W600   | Button labels    |
| `buttonSmall` | DM Sans          | 12   | W600   | Small buttons    |
| `badge`       | DM Sans          | 11   | W600   | Badges/chips     |
| `navLabel`    | DM Sans          | 10   | W500   | Bottom nav       |

---

## 10. Feature Modules — File Index

### 10.1 Home (`features/home/`)

| File                          | Size   | Purpose                                  |
| ----------------------------- | ------ | ---------------------------------------- |
| `home_screen.dart`            | 47.9KB | Main dashboard with trip cards, actions   |
| `home_route_args.dart`        | 160B   | Route arguments model                    |
| `widgets/trip_card.dart`      | 26.4KB | Trip card component                      |
| `widgets/next_trip_card.dart` | 16.9KB | Upcoming trip hero card                  |
| `widgets/empty_trip_hero_card.dart` | 16.4KB | Empty state CTA card              |
| `widgets/quick_budget_sheet.dart` | 11.7KB | Quick expense entry bottom sheet     |
| `widgets/trip_action_sheet.dart` | 9.9KB | Trip context menu                      |
| `widgets/starter_templates_carousel.dart` | 9.6KB | Template trip carousel       |
| `widgets/quick_action_tile.dart` | 6.1KB | Quick action button tile              |

### 10.2 Create Trip (`features/create_trip/`)

| File                               | Size   | Purpose                          |
| ---------------------------------- | ------ | -------------------------------- |
| `create_trip_flow.dart`            | 10.5KB | Stepper flow orchestrator        |
| `models/new_trip_model.dart`       | 2.2KB  | Wizard state model               |
| `steps/details_step.dart`          | 32.9KB | Step 1: Name, destination, dates |
| `steps/transport_step.dart`        | 45.6KB | Step 2: Transport mode & details |
| `steps/budget_step.dart`           | 38.4KB | Step 3: Budget & split method    |
| `steps/confirm_step.dart`          | 57.4KB | Step 4: Review & confirm         |
| `widgets/step_indicator.dart`      | 711B   | Progress dots                    |
| `widgets/trip_creation_loading_overlay.dart` | 12.3KB | Loading animation    |

### 10.3 Itinerary (`features/itinerary/`)

| File                                  | Size   | Purpose                            |
| ------------------------------------- | ------ | ---------------------------------- |
| `itinerary_screen.dart`               | 36.3KB | Main itinerary planner screen      |
| `utils/transit_conflict_helper.dart`  | 3.4KB  | Transit time conflict detection    |
| `widgets/add_stop_form.dart`          | 15.5KB | Add new stop form                  |
| `widgets/arrival_pill.dart`           | 17.3KB | Arrival/check-in status pill       |
| `widgets/day_actions_sheet.dart`      | 13.9KB | Day context menu                   |
| `widgets/day_budget_bar.dart`         | 2.8KB  | Per-day budget progress bar        |
| `widgets/day_insights_header.dart`    | 8.5KB  | Day stats header                   |
| `widgets/day_strip.dart`              | 5.2KB  | Horizontal day selector strip      |
| `widgets/day_summary_card.dart`       | 6.1KB  | Day summary card                   |
| `widgets/edit_stop_form.dart`         | 13.4KB | Edit existing stop form            |
| `widgets/inter_stop_transit_badge.dart` | 3.1KB | Transit badge between stops      |
| `widgets/itinerary_action_sheet.dart` | 21.7KB | Itinerary-level actions            |
| `widgets/itinerary_bottom_dock.dart`  | 9.0KB  | Bottom action dock                 |
| `widgets/itinerary_fulfillment_banner.dart` | 11.6KB | Fulfillment progress banner  |
| `widgets/itinerary_map_sheet.dart`    | 7.6KB  | Full-screen map bottom sheet       |
| `widgets/itinerary_map.dart`          | 11.4KB | Embedded itinerary map             |
| `widgets/navigate_route_button.dart`  | 34.3KB | Route navigation button            |
| `widgets/slide_to_arrive_button.dart` | 8.6KB  | Slide-to-arrive gesture button     |
| `widgets/smart_suggestion_chips.dart` | 6.5KB  | AI stop suggestion chips           |
| `widgets/stop_card.dart`              | 23.6KB | Individual stop card               |
| `widgets/stop_detail_sheet.dart`      | 39.9KB | Stop detail bottom sheet           |
| `widgets/timeline_view.dart`          | 11.7KB | Timeline visual layout             |
| `widgets/transport_badge.dart`        | 2.0KB  | Transport mode badge               |

### 10.4 Budget (`features/budget/`)

| File                                    | Size   | Purpose                     |
| --------------------------------------- | ------ | --------------------------- |
| `budget_screen.dart`                    | 51.1KB | Budget overview & management |
| `widgets/expense_log.dart`              | 6.1KB  | Expense history list        |
| `widgets/member_contribution_card.dart` | 5.8KB  | Per-member contribution     |
| `widgets/split_bill_panel.dart`         | 41.4KB | Bill splitting interface    |

### 10.5 Navigation (`features/navigation/`)

| File                                         | Size   | Purpose                          |
| -------------------------------------------- | ------ | -------------------------------- |
| `live_navigation_screen.dart`                | 15.3KB | Main live nav screen             |
| `navigation_screen.dart`                     | 6.7KB  | Nav overview                     |
| `models/navigation_models.dart`              | 12.4KB | Nav state models                 |
| `providers/navigation_provider.dart`         | 13.6KB | Nav state management             |
| `widgets/arrived_tab.dart`                   | 14.6KB | Arrived members tab              |
| `widgets/convoy_alert_banner.dart`           | 5.3KB  | Convoy separation alert          |
| `widgets/group_tracker_tab.dart`             | 20.8KB | Group tracker tab                |
| `widgets/live_map_tab.dart`                  | 36.3KB | Live map view                    |
| `widgets/nav_map_view.dart`                  | 11.7KB | Map rendering                    |
| `widgets/nav_panels.dart`                    | 27.1KB | Navigation info panels           |
| `widgets/navigate_to_member_sheet.dart`      | 15.4KB | Navigate to member sheet         |
| `widgets/privacy_control_sheet.dart`         | 11.1KB | Location sharing controls        |
| `widgets/proximity_alert_tab.dart`           | 16.8KB | Proximity alerts                 |
| `widgets/shared/member_avatar.dart`          | 4.6KB  | Shared member avatar             |
| `widgets/shared/mock_map_painter.dart`       | 7.1KB  | Mock map painter                 |
| `widgets/sos_emergency_modal.dart`           | 12.0KB | SOS emergency modal              |

### 10.6 Packing (`features/packing/`)

| File                                     | Size    | Purpose                     |
| ---------------------------------------- | ------- | --------------------------- |
| `packing_screen.dart`                    | 132.0KB | Packing checklist (largest) |
| `widgets/ai_packing_dialog.dart`         | 12.5KB  | AI suggestion dialog        |
| `widgets/member_assignment_sheet.dart`   | 1.7KB   | Assign item to member       |
| `widgets/packing_template_modals.dart`   | 25.8KB  | Template save/load modals   |

### 10.7 Other Features

| Feature        | File(s)                                        | Size   | Notes                        |
| -------------- | ---------------------------------------------- | ------ | ---------------------------- |
| Profile        | `features/profile/profile_screen.dart`         | 119.7KB| Settings, theme, privacy     |
| Friends        | `features/friends/friends_screen.dart` + widget | 85.9KB | Friend list & requests       |
| Members        | `features/members/members_screen.dart`         | 51.9KB | Trip member management       |
| Trip Detail    | `features/trip_detail/trip_detail_screen.dart` + widget | 70.9KB | Trip overview & edit    |
| Onboarding     | `features/onboarding/` (8 files)               | ~135KB | 7-step onboarding            |
| Trips List     | `features/trips/trips_screen.dart` + widget    | 43.2KB | All trips + join modal       |
| Chat           | `features/chat/chat_screen.dart`               | 18.8KB | Trip group messaging         |
| Explore        | `features/explore/explore_screen.dart`         | 23.7KB | Discover nearby/featured     |
| Notifications  | `features/notifications/notifications_screen.dart` | 20.2KB | Push notification list   |
| Activity       | `features/activity/activity_log_screen.dart`   | (part of home) | Activity timeline  |
| Splash         | `features/splash/splash_screen.dart`           | 13.0KB | Get Started / splash         |

---

## 11. Core Widgets Library

| Widget                       | File                                               | Purpose                          |
| ---------------------------- | -------------------------------------------------- | -------------------------------- |
| `AuthGate`                   | `core/widgets/auth_gate.dart`                      | Route guard + session lifecycle  |
| `AppBrandLogo`               | `core/widgets/app_brand_logo.dart`                 | Brand logo variant renderer      |
| `FloatingNavBar`             | `core/widgets/navigation/floating_nav_bar.dart`    | Bottom navigation bar            |
| `GlassCard`                  | `core/widgets/glass_card.dart`                     | Glassmorphism card               |
| `ShimmerLoading`             | `core/widgets/shimmer_loading.dart`                | Skeleton loading states          |
| `DynamicIslandPill`          | `core/widgets/dynamic_island_pill.dart`            | iOS-style dynamic island         |
| `ProfileCompletionBanner`    | `core/widgets/profile_completion_banner.dart`      | Profile setup prompt             |
| `NpcPrivacyPolicySheet`      | `core/widgets/npc_privacy_policy_sheet.dart`       | NPC privacy policy display       |
| `TripColorCarousel`          | `core/widgets/trip_color_carousel.dart`            | Trip theme color picker          |
| `MultiMemberPickerSheet`     | `core/widgets/multi_member_picker_sheet.dart`      | Multi-select member picker       |
| `PhLocationPicker`           | `core/widgets/ph_location_picker.dart`             | Philippine location picker       |
| `ShareTripModal`             | `core/widgets/share/share_trip_modal.dart`         | Share via QR/link/social         |
| `QrScannerModal`             | `core/widgets/scanner/qr_scanner_modal.dart`       | QR code scanner                  |
| **Inputs**                   |                                                    |                                  |
| `AppTextField`               | `core/widgets/inputs/app_text_field.dart`           | Branded text input               |
| `AppDatePicker`              | `core/widgets/inputs/app_date_picker.dart`          | Date picker                      |
| `AppDropdown`                | `core/widgets/inputs/app_dropdown.dart`             | Dropdown selector                |
| `AppNumericField`            | `core/widgets/inputs/app_numeric_field.dart`        | Numeric input                    |
| `LocationPicker`             | `core/widgets/inputs/location_picker.dart`          | Map-based location picker        |
| `MapPinPickerModal`          | `core/widgets/inputs/map_pin_picker_modal.dart`     | Pin-drop map modal               |
| **Feedback**                 |                                                    |                                  |
| `AppBanner`                  | `core/widgets/feedback/app_banner.dart`             | Top banner notifications         |
| `AppDialog`                  | `core/widgets/feedback/app_dialog.dart`             | Styled dialog                    |
| `AppFeedback`                | `core/widgets/feedback/app_feedback.dart`           | Feedback utilities               |
| **Buttons**                  |                                                    |                                  |
| `AppBackButton`              | `core/widgets/buttons/app_back_button.dart`         | Styled back button               |

---

## 12. Utilities

| Utility                  | File                                         | Purpose                              |
| ------------------------ | -------------------------------------------- | ------------------------------------ |
| `CurrencyInputFormatter` | `core/utils/currency_input_formatter.dart`   | ₱ formatted input mask               |
| `CurrencyUtils`          | `core/utils/currency_utils.dart`             | PHP currency formatting              |
| `InviteCodeGenerator`    | `core/utils/invite_code_generator.dart`      | 6-char invite code generator         |
| `ShareFormatHelper`      | `core/utils/share_format_helper.dart`        | Trip share text formatting           |
| `JitGuard`               | `core/utils/jit_guard.dart`                  | Debounce/throttle guard              |
| `SettlementCalculator`   | `core/logic/settlement_calculator.dart`      | Expense settlement algorithm         |
| `PhLocationData`         | `core/data/ph_location_data.dart`            | Offline PH province/city data (36KB) |
| `MapTileConfig`          | `core/constants/map_tile_config.dart`        | OSM tile URL config                  |

---

## 13. Supabase Schema (Migrations)

23 migration files in `supabase/migrations/`:

| Migration                               | Purpose                                |
| --------------------------------------- | -------------------------------------- |
| `000_master_schema.sql`                 | Complete consolidated schema (52KB)    |
| `001_initial_schema.sql`                | Initial tables setup                   |
| `002_real_data_support.sql`             | Real data columns                      |
| `003_dev_seed.sql`                      | Dev seed data                          |
| `004_postgis_live_tracking.sql`         | PostGIS live location tracking         |
| `005_trip_messages.sql`                 | Chat messages table                    |
| `006_multi_user_fixes.sql`             | Multi-user RLS fixes                   |
| `007_stop_votes.sql`                   | Stop voting (later dropped)            |
| `008_join_trip_by_code.sql`            | Join trip by invite code RPC           |
| `009_fix_new_user_trigger.sql`         | User creation trigger fix              |
| `010_fix_trip_members_rls_recursion.sql`| RLS infinite recursion fix            |
| `011_sync_missing_fields.sql`          | Missing column sync                    |
| `012_privacy_hide_surname.sql`         | Name privacy (hide_surname)            |
| `013_fix_rls_recursion.sql`            | RLS helper functions                   |
| `014_ensure_columns.sql`              | Column existence safety checks         |
| `015_drop_unused_columns.sql`          | Drop permanently unused columns        |
| `016_fix_crud_rls.sql`                | CRUD RLS policy corrections            |
| `017_member_approval_and_notifications.sql` | Member approval + notification system |
| `018_update_member_roles.sql`          | Role system update                     |
| `019_fix_join_trip_by_code.sql`        | Join trip RPC rewrite                  |
| `020_consolidate_trip_theme_fields.sql`| Drop legacy theme columns              |
| `021_drop_stop_votes_and_stop_status.sql` | Remove stop_votes + stop status     |
| `022_add_arrival_tracking.sql`         | Arrival tracking columns               |

### Core DB Tables

| Table              | Key Columns                                                     |
| ------------------ | --------------------------------------------------------------- |
| `trips`            | `id`, `name`, `destination`, `start_date`, `end_date`, `budget`, `split_method`, `owner_id`, `status`, `invite_code`, `type`/`trip_type`, `departure_point`, `departure_lat`, `departure_lng`, `departure_map_url`, `destination_details`, `transport_mode`, `transport_meta` |
| `trip_members`     | `trip_id`, `user_id`, `roles`, `status`, `location_sharing`, GCash fields |
| `itinerary_stops`  | `id`, `trip_id`, `name`, `description`, `stop_date`, `start_time`, `end_time`, `location_name`, `latitude`, `longitude`, `cost`, `stop_type`, `status`, `booking_ref`, `order_index` |
| `expenses`         | `id`, `trip_id`, `description`, `amount`, `category`, `paid_by_user_id`, `status`, `receipt_url`, `rejection_note` |
| `packing_items`    | `id`, `trip_id`, `item_name`, `category`, `is_packed`, `is_custom`, `assigned_to_user_id` |
| `friends`          | Friend relationships (use `public.friends` exclusively)         |
| `trip_messages`    | Chat messages per trip                                          |
| `users`            | Public user profile data                                        |
| `notifications`    | Push notification records                                       |

### Forbidden Columns (NEVER query/insert)

- **trips**: `destination_lat`, `destination_lng`, `invite_expires_at`, `cover_image_url`, `discord_channel_id`, `cover_color`, `cover_emoji`
- **itinerary_stops**: `duration_min`, `google_place_id`, `photo_url`, `created_by`
- **packing_items**: `quantity`, `notes`, `created_by`, `checked_by`, `checked_at`
- **expenses**: `split_meta`, `rejected_by`

### RLS Helper Functions

- `public.is_trip_member(trip_id)` — check trip membership
- `public.user_owns_trip(trip_id)` — check trip ownership
- `public.user_can_access_trip(trip_id)` — combined access check

**⚠️ NEVER** write `SELECT 1 FROM trip_members WHERE trip_id = ...` inside a `trip_members` RLS policy.

---

## 14. Edge Functions

| Function            | Directory                            | Purpose                |
| ------------------- | ------------------------------------ | ---------------------- |
| `expense-approved`  | `supabase/functions/expense-approved/` | Webhook on expense approval |
| `send-notification` | `supabase/functions/send-notification/` | Push notification dispatch |

---

## 15. Auth Flow

```
main() → dotenv.load() → Supabase.initialize() → SecureSessionRepository.restoreSession()
  → ThreeLayerEncryptionService.init() → runApp(ProviderScope(TaraApp()))

TaraApp → AuthGate (wraps MaterialApp)
  → checks Supabase.currentUser (in-memory)
  → OR checks SecureSessionRepository.hasStoredSession()
  → if authenticated → profileProvider.refreshProfile()
    → if profile.isAccountFullySet → /home
    → else → /onboarding
  → if not authenticated → / (splash)

Auth events: signedIn → start presence, refresh profile
             tokenRefreshed → persist new token
             signedOut → stop presence, flush audit, invalidate profile, → /
```

---

## 16. Trip Type System (`core/constants/trip_types.dart`)

16 built-in trip types across 4 categories:

| Category              | Types                                              |
| --------------------- | -------------------------------------------------- |
| **Popular**           | Beach 🏖️, City 🏙️, Road Trip 🚗, Foodie 🍕      |
| **Outdoors**          | Adventure 🏕️, Nature 🌿, Cruise 🚢, Backpacking 🎒 |
| **Lifestyle**         | Wellness 🧘‍♀️, Cultural 🏛️, Festival 🎟️, Solo 🧭 |
| **Leisure**           | Family 👨‍👩‍👧‍👦, Romantic 💖, Business 💼, Luxury 💎   |

Each type resolved via `AppTripTypes.getOption(typeStr)` → returns `TripTypeOption { id, label, emoji, subtitle, category, accentColor }`.

---

## 17. Assets

| Path                     | Contents                                      |
| ------------------------ | --------------------------------------------- |
| `assets/logo.png`        | App logo (1.1MB)                              |
| `assets/icon.png`        | App icon (765KB)                              |
| `assets/adaptive-icon.png`| Adaptive icon (765KB)                        |
| `assets/favicon.png`     | Web favicon (2KB)                             |
| `assets/splash.png`      | Splash screen image                           |
| `assets/animations/`     | Lottie animation files                        |
| `assets/fonts/`          | DM Sans (4 weights) + Playfair Display (4 weights) |
| `.env`                   | Runtime secrets (3.3KB)                       |

---

## 18. Config Files

| File                  | Purpose                               |
| --------------------- | ------------------------------------- |
| `pubspec.yaml`        | Dependencies, assets, fonts, splash config |
| `analysis_options.yaml`| Dart lint rules (1.4KB)              |
| `.env`                | Supabase URL, anon key, Google client IDs |
| `.env.example`        | Template env (2.9KB)                  |
| `devtools_options.yaml`| DevTools preferences                 |

---

## 19. Key Architectural Invariants

1. **Remote-First**: `TripRepository` is direct Supabase — no local Sembast caching for trips.
2. **State**: `flutter_riverpod` exclusively. No Bloc, GetX, or legacy Provider.
3. **Session**: `SecureSessionRepository` restores session on startup.
4. **Encryption**: RSA-2048 (Keystore) + AES-256-GCM (payload) + TLS 1.3 (transport).
5. **Name Privacy**: Always use `MemberModel.formatDisplayName(name, hideSurname:)`.
6. **Trip Theme**: Emoji/color derived from `tripType` via `AppTripTypes` — no stored `cover_color`/`cover_emoji`.
7. **RLS Safety**: Use helper functions (`is_trip_member`, `user_owns_trip`, `user_can_access_trip`), never inline membership queries in RLS policies.
8. **Friends Table**: Use `public.friends` exclusively — `friendships` table is dropped.

---

## 20. File Size Hot Spots (Largest Files)

| File                              | Size    | Refactor Candidate? |
| --------------------------------- | ------- | -------------------- |
| `packing_screen.dart`             | 132.0KB | ⚠️ Yes — consider splitting |
| `profile_screen.dart`             | 119.7KB | ⚠️ Yes               |
| `friends_screen.dart`             | 59.0KB  | Moderate              |
| `confirm_step.dart`               | 57.4KB  | Moderate              |
| `trip_detail_screen.dart`         | 53.3KB  | Moderate              |
| `members_screen.dart`             | 51.9KB  | Moderate              |
| `budget_screen.dart`              | 51.1KB  | Moderate              |
| `home_screen.dart`                | 47.9KB  | Moderate              |
| `transport_step.dart`             | 45.6KB  | Moderate              |
| `split_bill_panel.dart`           | 41.4KB  | Moderate              |
| `stop_detail_sheet.dart`          | 39.9KB  | OK                    |
| `itinerary_screen.dart`           | 36.3KB  | OK                    |
| `live_map_tab.dart`               | 36.3KB  | OK                    |
| `ph_location_data.dart`           | 35.8KB  | Data file (OK)        |
| `choose_mode_step.dart`           | 35.4KB  | Moderate              |
| `trips_screen.dart`               | 34.4KB  | OK                    |
| `navigate_route_button.dart`      | 34.3KB  | OK                    |
| `details_step.dart`               | 32.9KB  | OK                    |
| `shimmer_loading.dart`            | 31.1KB  | OK                    |

---

*End of Analyze.md — agent memory index for Tara Travel codebase.*
