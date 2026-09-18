# Tara Travel — System Architecture Index (INDEX.md)

> High-density, token-efficient system reference. Consult this index FIRST before scanning large documentation or codebase directories.

---

## 1. 📱 App Routes & Screen Map (`lib/main.dart`)

| Route | Widget | File Path | Key Subcomponents |
| :--- | :--- | :--- | :--- |
| `/` | `SplashScreen` | `lib/features/splash/splash_screen.dart` | Session rehydration, version check |
| `/onboarding` | `OnboardingScreen` | `lib/features/onboarding/onboarding_screen.dart` | 5-step setup, pure Google auth, NPC terms, profile |
| `/home` | `HomeScreen` | `lib/features/home/home_screen.dart` | `NextTripCard`, `FloatingNavBar`, `IndexedStack` |
| `/create-trip` | `CreateTripFlow` | `lib/features/create_trip/create_trip_flow.dart` | 4-step wizard, vehicle garage, transport |
| `/trip-detail` | `TripDetailScreen` | `lib/features/trip_detail/trip_detail_screen.dart` | `OngoingTripHud`, `DestinationWeatherWidget`, `PlanningRecommendationsCard`, `TripAnnouncementsCard`, `SmartDepartureAdvisoryCard`, `TaraCopilotSheet`, Dock |
| `/itinerary` | `ItineraryScreen` | `lib/features/itinerary/itinerary_screen.dart` | `DayStrip`, `StopCard`, `ItineraryBottomDock` |
| `/budget` | `BudgetScreen` | `lib/features/budget/budget_screen.dart` | `DailyPacingCard`, `CategoryBudgetChart`, Split |
| `/navigation` | `LiveNavigationScreen` | `lib/features/navigation/live_navigation_screen.dart` | `flutter_map`, convoy tracking, `SosModal` |
| `/packing` | `PackingScreen` | `lib/features/packing/packing_screen.dart` | Categorized list, smart AI suggestions |
| `/chat` | `ChatScreen` | `lib/features/chat/chat_screen.dart` | Realtime messaging, `PollCard`, embeds |
| `/members` | `MembersScreen` | `lib/features/members/members_screen.dart` | Role management, QR invite, permissions |
| `/friends` | `FriendsScreen` | `lib/features/friends/friends_screen.dart` | Friends / Requests / Find tabs, QR add |
| `/profile` | `ProfileScreen` | `lib/features/profile/profile_screen.dart` | `ProfileHeroHeader`, `ProfileHealthCard`, `ProfilePaymentCard`, `ProfileSecurityCard`, `ProfileAccountCard`, `NotificationSettingsScreen` |
| `/explore` | `ExploreScreen` | `lib/features/explore/explore_screen.dart` | Search, destination carousel, quick plan |
| `/notifications` | `NotificationsScreen` | `lib/features/notifications/notifications_screen.dart` | In-app alerts, deep-link triggers |
| `/activity` | `ActivityLogScreen` | `lib/features/activity/activity_log_screen.dart` | Audit trail, timeline cards |
| `/trips` | `TripsScreen` | `lib/features/trips/trips_screen.dart` | Active, planning, and past trip catalog |

---

## 2. ⚡ State Management Providers (`lib/core/providers/`)

| Provider Category | File | Key Exported Providers |
| :--- | :--- | :--- |
| **Auth & Session** | `auth_provider.dart` | `authNotifierProvider`, `currentUserProvider`, `isAuthenticatedProvider` |
| **Trips** | `trip_provider.dart` | `userTripsProvider`, `activeTripProvider`, `tripDetailProvider`, `tripStatusProvider` |
| **Selection** | `selected_trip_provider.dart` | `selectedTripIdProvider`, `selectedTripProvider` |
| **Itinerary** | `itinerary_provider.dart` | `itineraryStopsProvider(tripId)`, `itineraryDaysProvider(tripId)` |
| **Budget & Expense**| `expense_provider.dart` | `tripExpensesProvider(tripId)`, `expenseSummaryProvider(tripId)` |
| **Allowance** | `personal_allowance_provider.dart` | `personalAllowanceProvider(tripId)` |
| **Packing** | `packing_provider.dart` | `packingItemsProvider(tripId)`, `packingCategoryProgressProvider` |
| **Chat & Polls** | `chat_provider.dart`, `poll_provider.dart` | `chatMessagesProvider(tripId)`, `tripPollsProvider(tripId)`, `tripAnnouncementsProvider(tripId)` |
| **Weather** | `trip_weather_provider.dart` | `tripWeatherProvider(tripId)`, `destinationWeatherProvider` |
| **Friends & Squads** | `friend_provider.dart`, `friend_circle_provider.dart` | `friendsListProvider`, `pendingFriendRequestsProvider`, `friendCirclesProvider` |
| **Profile & Garage** | `profile_provider.dart`, `user_vehicles_provider.dart` | `userProfileProvider`, `profileNotifierProvider`, `userVehiclesProvider`, `primaryVehicleProvider` |
| **Activity** | `activity_provider.dart` | `tripActivitiesProvider(tripId)` |
| **Group Tracking** | `group_tracking_provider.dart` | `liveMembersLocationProvider(tripId)` |
| **Explore** | `explore_provider.dart` | `exploreProvider`, `exploreCategoryFilterProvider` |
| **Repositories** | `repository_providers.dart` | `tripRepositoryProvider`, `expenseRepoProvider`, `destinationRepositoryProvider`, etc. |

---

## 3. 🗄️ Repositories (`lib/core/repositories/`)

*All remote repositories talk directly to Supabase with RLS enforcement.*

| Repository | File | Primary Responsibility |
| :--- | :--- | :--- |
| `TripRepository` | `trip_repository.dart` | Remote single source of truth for trips & trip members |
| `DestinationRepository` | `destination_repository.dart` | Remote single source of truth for `public.destinations` with offline fallbacks |
| `ItineraryRepository`| `itinerary_repository.dart` | Itinerary stop ordering, day grouping, GPS coordinates |
| `ExpenseRepository` | `expense_repository.dart` | Group expenses, receipt images, approvals, settlements |
| `PackingRepository` | `packing_repository.dart` | Packing items, category assignments, pack toggles |
| `ChatRepository` | `chat_repository.dart` | Message persistence, poll creation, announcements & vote recording |
| `ProfileRepository` | `profile_repository.dart` | User profile data, avatars, emergency contacts, MPIN |
| `FriendRepository` | `friend_repository.dart` | `public.friends` friendship graph & requests |
| `FriendCircleRepository` | `friend_circle_repository.dart` | Partitioned local secure storage CRUD for squads & barkadas |
| `UserVehiclesRepository` | `user_vehicles_repository.dart` | Partitioned local secure storage CRUD for personal garage vehicles |
| `PersonalAllowanceRepository` | `personal_allowance_repository.dart` | Private personal expense tracking |
| `AuthRepository` | `auth_repository.dart` | Supabase auth integration, sign-in/up, OTP |

---

## 4. 📦 Domain Models (`lib/core/models/`)

| Model | File | Primary Database Table |
| :--- | :--- | :--- |
| `TripModel` | `trip_model.dart` | `public.trips` (never query dropped lat/lng/cover fields) |
| `DestinationModel` | `destination_model.dart` | `public.destinations` |
| `MemberModel` | `member_model.dart` | `public.trip_members` (use `MemberModel.formatDisplayName`) |
| `ItineraryStop` | `itinerary_model.dart` | `public.itinerary_stops` |
| `ExpenseModel` | `expense_model.dart` | `public.expenses` |
| `PackingItem` | `packing_model.dart` | `public.packing_items` |
| `FriendModel` | `friend_model.dart` | `public.friends` |
| `FriendCircle` / `CircleMember` | `friend_circle_model.dart` | Reusable travel squads & preset roles |
| `UserVehicle` | `user_vehicle_model.dart` | User personal garage vehicle specs & km/L rating |
| `TripPollModel` | `trip_poll_model.dart` | `public.trip_polls` & `poll_options` |
| `WeatherForecast`| `weather_model.dart` | In-memory & cached Open-Meteo payload |
| `ActivityModel` | `activity_model.dart` | `public.activity_logs` |
| `PersonalAllowance`| `personal_allowance_model.dart` | `public.personal_allowances` |

---

## 5. 🛠️ Key Services (`lib/core/services/`)

| Service | File | Purpose |
| :--- | :--- | :--- |
| `WeatherService` | `weather_service.dart` | Open-Meteo REST client with disk caching & severe condition parsing |
| `AppVersionService`| `app_version_service.dart` | Supabase Remote Config version validator & update triggers |
| `ApkDownloadInstaller`| `apk_download_installer.dart` | Supabase Storage release APK downloader & Android installer |
| `LocationTrackingService`| `location_tracking_service.dart`| GPS telemetry & geofence distance calculation |
| `ConnectivityService`| `connectivity_service.dart` | Online/offline detection & network state broadcasting |
| `PhilippineGeocodingService`| `philippine_geocoding_service.dart` | Offline PH region/province/city data & coordinates |
| `GoogleMapsParserService`| `google_maps_parser_service.dart` | Zero-cost Google Maps URL & coordinate resolver with stop inference |
| `DepartureAdvisoryService`| `departure_advisory_service.dart` | Meet-up assembly countdown, ETA buffer, grace period & departure detector |
| `GeminiAiService`| `gemini_ai_service.dart` | Dual-path generative AI travel copilot & action chip synthesis |
| `ReceiptOcrService`| `receipt_ocr_service.dart` | ML Kit client receipt text extraction |

---

## 6. 🗃️ Ground-Truth Database Schema Rules

- **`trips`**: Contains `departure_point`, `departure_lat`, `departure_lng`, `destination_details`, `transport_mode`, `transport_meta`. Dropped: `destination_lat`, `destination_lng`, `cover_image_url`, `cover_color`, `cover_emoji`.
- **`trip_members`**: Always use helper functions (`public.is_trip_member`, `public.user_owns_trip`) in RLS to prevent recursion.
- **`friends`**: Exclusively `public.friends` (never use legacy `friendships`).
- **`app_versions`**: Supabase table for version gating, force updates, and maintenance mode.

---

## 7. 📜 Architecture Governance & Workflow Index

- **Governance Reference**: [`docs/GOVERNANCE.md`](file:///d:/Spencer/Downloads/tara_travel/docs/GOVERNANCE.md) (Persona, security, rate limiting, mobile best practices, DevOps standards).
- **Available Workflows**:
  - `/run`: Local environment test, build, and run guidelines.
  - `/deploy-pipeline`: GitHub Actions CI/CD configuration generator.
  - `/secure-docker`: Hardened multi-stage Dockerfile generator.

