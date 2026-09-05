# Tara Travel — Master Feature & Implementation Roadmap

This document serves as our compiled repository master plan, organized hierarchically from **Minor Updates (UI Polish, Guards & Privacy)** through **Medium Features (Domain Models & Local Services)** to **Major Architectural & Platform Upgrades (End-to-End Systems, AI & Middleware)**.

---

## 📋 Table of Contents & Status Summary (Organized Minor → Major)

### 🟢 Tier 1: Minor Updates (UI Polish, Guards & Privacy Controls)
| # | Plan / Feature | Status | Key Focus |
|---|---|---|---|
| **1** | [Role-Aware Trip Exit: "Leave Trip" vs "Delete Trip"](#plan-1-role-aware-trip-exit-leave-trip-vs-delete-trip) | 🟡 **Drafted / Queued** | Non-owners/members leave trip instead of delete; owner retains delete privilege |
| **2** | [Invite Code Privacy & Safe Area Gesture Clearance](#plan-2-invite-code-privacy-safe-area-gesture-clearance) | 🟡 **Drafted / Queued** | Masked codes (`******`), auto-hide timer, bottom sheet `MediaQuery` insets & gesture clearance |
| **3** | [Offline Read-Only Guard & Action Freezing](#plan-3-offline-read-only-guard-action-freezing) | 🟡 **Drafted / Queued** | Disables/locks write actions when disconnected, prevents stale sync errors, visual offline badges |
| **4** | [Cloud-Native Avatar Storage & CDN Cache Architecture](#plan-4-cloud-native-avatar-storage-cdn-cache-architecture) | 🟡 **Drafted / Queued** | Supabase Storage bucket (`avatars`), WebP compression, RLS policies & CachedNetworkImage integration |

### 🟡 Tier 2: Medium Features (Domain Tools, Local Logic & Services)
| # | Plan / Feature | Status | Key Focus |
|---|---|---|---|
| **5** | [Google Maps & Pin Location Integration](#plan-5-google-maps-link-resolver-pin-location-applicable) | 🟡 **Approved / Ready to Implement** | Paste GMap link, auto-fill itinerary, pin-drop flying, zero-cost resolution |
| **6** | [Tri-Modal Land Transport (Private, Commute, Rental) & Vehicle Garage Fuel Estimator](#plan-6-tri-modal-land-transport-private-commute-rental--vehicle-garage-fuel-estimator) | 🟡 **Drafted / Queued** | Finalized 3 land modes (Private, Commute, Rental; strictly no sea/plane), user garage, live fuel prices & rental splitting |
| **7** | [Travel Circles (Squads & Barkada Presets) for Multi-Member Trip Creation](#plan-7-travel-circles-squads-barkada-presets-for-multi-member-trip-creation) | 🟡 **Drafted / Queued** | Friend circles/squad presets, 1-tap batch addition, smart co-traveler suggestions & deduplication |
| **8** | [Real-Time Live Weather Forecast & Severe Condition Alerts Engine](#plan-8-real-time-live-weather-forecast-severe-condition-alerts-engine) | 🟡 **In Progress / Core Complete** | Open-Meteo API integration, offline caching, itinerary day-strip weather & severe storm alerts |
| **9** | [Dual-Lens Budget & Expense Hub (Personal Pocket Tracker + Group Trip Summary)](#plan-9-dual-lens-budget-expense-hub-personal-pocket-tracker-group-trip-summary) | 🟡 **Drafted / Queued** | Private personal expenses, "My True Trip Cost", cash/GCash tracking & daily burn pace meter |
| **10** | [Flexible & Optional Trip Map: Adventure, Multi-Point & Off-Grid Mode](#plan-10-flexible-optional-trip-map-adventure-multi-point-off-grid-mode) | 🟡 **Drafted / Queued** | Optional map tracking, multi-point waypoints, adventure trail roaming, battery-saving mapless mode |
| **11** | [Meet-up Assembly, Smart Countdown & Automatic Departure Detection](#plan-11-meet-up-assembly-smart-countdown-automatic-departure-detection) | 🟡 **Drafted / Queued** | Day 1 Stop 0 auto-insertion, meet-up grace period, GPS distance countdown & auto departure |
| **12** | [Floating Travel Bubble & System Overlay HUD (PiP / Chathead Mode)](#plan-12-floating-travel-bubble-system-overlay-hud-pip-chathead-mode) | 🟡 **Drafted / Queued** | System-wide floating bubble overlay, live convoy/next stop glance, quick expense note & PiP |

### 🔴 Tier 3: Major Architecture & Platform (End-to-End Systems, AI & Middleware)
| # | Plan / Feature | Status | Key Focus |
|---|---|---|---|
| **13** | [Trip Detail Screen: Ongoing Command Center, HUD & Quick Action Hub](#plan-13-trip-detail-screen-ongoing-command-center-hud-quick-action-hub) | 🟡 **Drafted / Queued** | Active Quick Stop HUD, persistent bottom bar, telemetry, officers, announcements & weather |
| **14** | [Day Map Intelligent Route Optimization & Arrival Geofence](#plan-14-day-map-intelligent-route-optimization-best-way-routing) | 🟡 **Drafted / Queued** | Street-network routing, best order optimization, arrival geofence pop-up & notification |
| **15** | [Comprehensive Mobile Notifications Architecture (Push, In-App Banners & Deep-Link Routing)](#plan-15-comprehensive-mobile-notifications-architecture-push-in-app-banners-deep-link-routing) | 🟡 **Drafted / Queued** | Local scheduled alerts, FCM push, Island in-app banners, swipe dismissal & contextual tap routing |
| **16** | [Gemini Embedded AI Travel Copilot & Assistant](#plan-16-gemini-embedded-ai-travel-copilot-assistant) | 🟡 **Drafted / Queued** | Natural language trip planner, smart itinerary recommendations, budget optimization & packing generator |
| **17** | [Supabase & Middleware App Versioning & OTA Updates](#plan-17-supabase-middleware-app-versioning-ota-updates) | 🟡 **Drafted / Queued** | Version gatekeeper, Shorebird OTA code push, Supabase storage APK download & force/soft update dialogs |
| **18** | [Tara Laravel Middleware & SuperAdmin Dashboard (Universal Links, CMS & Ops)](#plan-18-tara-laravel-middleware-superadmin-dashboard-universal-links-cms-ops) | 🟡 **Drafted / Queued** | Web-to-app deep linking gateway, Filament v3 CMS, trip templates, feedback helpdesk & remote config |
| **19** | [Universal Responsive Layout Engine & Zero-Overflow Architecture](#plan-19-universal-responsive-layout-engine--zero-overflow-architecture) | 🟢 **Complete** | Breakpoints, clamped text scaler, safe padding/insets, zero hardcoded MediaQuery dimensions |

---

## Plan 1: Role-Aware Trip Exit: "Leave Trip" vs "Delete Trip"

### Goal
Ensure that users who did not create the trip or do not possess owner/admin privileges cannot see or trigger "Delete Trip". Instead, they are presented with a **"Leave Trip"** option across all trip action surfaces.

### Core Capabilities
1. **Ownership & Role Detection**:
   - Inspect `currentUserId == trip.ownerId` or member role via `tripMembersProvider(trip.id)`.
   - **Trip Creator / Owner**: Retains **"Delete Trip"** (which deletes or archives the trip for everyone via Supabase RPC/RLS policies).
   - **Non-Owner / Joined Member**: Replaces "Delete Trip" with **"Leave Trip"** (uses `TripRepository.leaveTrip(tripId)` which invokes Supabase `leave_trip` RPC).
2. **Unified Surface Enforcement**:
   - **Trip Action Sheet (`TripActionSheet`)**: Shows "Leave Trip" (door icon, red/amber text) with subtitle *"Remove yourself from this trip"* for members, and "Delete Trip" only for the owner.
   - **Trip Details Menu (`TripDetailScreen`)**: Overflow menu dynamically swaps `"Delete Trip"` for `"Leave Trip"` based on user ownership.
   - **Trips List Screen (`TripsScreen`)**: Context menus or swipe actions respect role-based exit.
3. **Graceful State Invalidation & Feedback**:
   - When a member leaves:
     - Confirms via `AppDialog.showDestructive(title: 'Leave Trip', message: 'Are you sure you want to leave "[Trip Name]"? You will need an invite code to rejoin.', confirmLabel: 'Leave')`.
     - Calls `leaveTrip(tripId)`.
     - Clears `selectedTripIdProvider`.
     - Invalidates `allTripsProvider`, `activeTripProvider`, and `selectedTripProvider`.
     - Navigates back safely and displays confirmation toast: *"You left [Trip Name]"*.

### Impacted Files & Architecture
- `lib/features/home/widgets/trip_action_sheet.dart` *(MODIFY)*
- `lib/features/trip_detail/trip_detail_screen.dart` *(MODIFY)*
- `lib/features/trips/trips_screen.dart` *(MODIFY)*
- `lib/core/repositories/trip_repository.dart` *(VERIFY RPC leaveTrip integration)*
- `test/features/trips/role_aware_trip_exit_test.dart` *(NEW)*

---

---

## Plan 2: Invite Code Privacy & Safe Area Gesture Clearance

### Goal
Prevent shoulder-surfing, unwanted join leaks, and accidental gesture navigation dismissals across trip sharing and action surfaces: masking trip invite codes (`******` / `••••••`) with a 1-tap reveal and auto-hide timer, while ensuring modal bottom sheets dynamically compute system navigation insets (`MediaQuery.paddingOf(context).bottom`) so destructive actions (like "Leave Trip" or "Delete Trip") remain ergonomic and completely clear of gesture navigation bars.

### Core Capabilities
1. **Masked Display State (`••••••` / `******`)**:
   - By default (or via tap toggle), the alphanumeric trip invite code is concealed using bullet/asterisk privacy glyphs (`••••••`) in monospace font and equal tracking.
   - Prevents bystanders or screen recordings from exposing sensitive trip codes in public terminals, vehicles, or cafes.
2. **Tap-to-Reveal & Eye Toggle (`IconButton` / `GestureDetector`)**:
   - Tapping the code card or visibility toggle icon reveals plain text code with a subtle fade animation.
   - Tapping again immediately re-masks the code back to dots.
3. **Auto-Re-Mask Security Timer**:
   - When revealed, an auto-mask timer (10–15 seconds) automatically reverts the code back to masked mode (`******`).
4. **Copy & Share Safe Flow**:
   - **Tap-to-Copy**: Tapping "Copy" copies the unmasked code to the clipboard with haptic feedback and privacy-safe notification toast.
   - **Direct Share**: External share sheets pass the invite link directly without requiring manual unmasking.
5. **Dynamic System Navigation Insets Clearance (`TripActionSheet`)**:
   - Replaces static bottom padding with responsive system-aware edge insets:
     - `EdgeInsets.only(bottom: 16 + MediaQuery.paddingOf(context).bottom)` or wrapping with bottom `SafeArea`.
   - Ensures the final action button (Delete / Leave Trip) is positioned comfortably above gesture pill bars and 3-button navigation.
6. **Scrollable Action Insets for Small Devices (`SingleChildScrollView`)**:
   - Wraps sheet items in `Flexible` + `SingleChildScrollView(physics: BouncingScrollPhysics())` to eliminate `RenderFlex` overflow warnings across small screens, landscape orientation, and expanded accessibility font scales.

### Impacted Files & Architecture
- `lib/core/widgets/privacy_invite_code_widget.dart` *(NEW — reusable masked code component with eye toggle, copy action, and auto-timeout)*
- `lib/features/home/widgets/trip_action_sheet.dart` *(MODIFY — replace static bottom padding with `MediaQuery.paddingOf(context).bottom` / `SafeArea`, add scroll safeguard & masked code preview)*
- `lib/features/trip_detail/trip_detail_screen.dart` *(MODIFY — integrate privacy invite toggle in `_InviteCard`)*
- `lib/features/members/members_screen.dart` *(MODIFY — integrate privacy masking in `_buildInviteCard`)*
- `test/core/widgets/privacy_invite_code_widget_test.dart` *(NEW)*
- `test/features/home/widgets/trip_action_sheet_test.dart` *(NEW)*

---

---

## Plan 3: Offline Read-Only Guard & Action Freezing

### Goal
Enforce a consistent, transparent **Read-Only Mode** across the entire application when the device is offline or loses connection: allowing travelers to view all cached trips, schedules, maps, and details freely while disabling/freezing mutations (adding stops, editing details, deleting trips, logging expenses, voting on polls) to prevent failed remote calls, state conflicts, or lost unsaved changes.

### Core Capabilities
1. **Global Reactive Offline State via `ConnectivityService`**:
   - Leverage `ConnectivityService.instance.onlineStream` and create a global Riverpod provider `isOnlineProvider`.
   - Any screen or widget can instantly react to internet disconnection without manual polling.
2. **Action Freezing & Read-Only Locks**:
   - **Mutation Buttons & FABs**:
     - Automatically disable "Add Stop", "Create Trip", "Log Expense", "Edit Trip", "Delete Trip", and "Invite Members" when offline.
     - Visually dims buttons with an informative lock icon or muted color style.
   - **Informative Disconnection Toast / SnackBar**:
     - Tapping any disabled action displays a clear, gentle feedback banner: *"You are currently offline. Actions are in read-only mode to prevent data loss."*
   - **Non-Destructive Navigation Stays Active**:
     - Viewing offline-cached itinerary stops, packing checklists, offline map polylines, and stored guides remains 100% functional.
3. **Persistent Top-Level Offline Banner**:
   - A subtle, sleek amber/gray pill banner at the top of the active trip screen: *"⚡ Offline Mode — Viewing saved trip data (Read-Only)"*.
   - Automatically slides away with a green toast (*"Back online! All actions restored 🌐"*) as soon as connectivity resumes.
4. **Form Submit Guarding & Fail-Safe Protection**:
   - Even if a modal form is already open when the connection drops, form submission buttons disable gracefully and display an offline hint instead of crashing or throwing network timeout exceptions.

### Impacted Files & Architecture
- `lib/core/services/connectivity_service.dart` *(VERIFY & enhance)*
- `lib/core/providers/connectivity_provider.dart` *(NEW - Riverpod boolean provider)*
- `lib/core/widgets/offline_read_only_banner.dart` *(NEW)*
- `lib/core/widgets/buttons/app_button.dart` *(MODIFY - optional requiresOnline guard)*
- `lib/features/trip_detail/trip_detail_screen.dart` *(MODIFY - bind read-only mode)*
- `lib/features/itinerary/itinerary_screen.dart` *(MODIFY - freeze add/edit/reorder FABs when offline)*
- `lib/features/expenses/expenses_screen.dart` *(MODIFY - freeze expense creation when offline)*
- `test/core/services/offline_read_only_guard_test.dart` *(NEW)*

---

---

## Plan 4: Cloud-Native Avatar Storage & CDN Cache Architecture

*(Referenced from `DEV_IDEA.md` IDEA-006)*

### Goal
Eliminate device isolation and local storage bloat by replacing local file path avatars with a cloud-native avatar storage pipeline: **Client Compression (WebP $\le 60\text{KB}$) + Supabase Storage Bucket (`avatars`) + PostgreSQL Public CDN URL Persistence + `CachedNetworkImage`**.

### Core Capabilities
1. **Dedicated Supabase Storage Bucket (`avatars`)**:
   - Standardized path: `avatars/{user_id}/avatar.webp` (upsert enabled).
   - Strict RLS policies: public read access, authenticated insert/update/delete restricted to `auth.uid()`.
2. **Client-Side Image Optimization**:
   - Resizes and compresses picked gallery/camera photos to $512 \times 512\text{px}$ WebP at 85% quality ($\le 60\text{KB}$).
   - Automatically cleans up temporary files from device cache after upload.
3. **Database Synchronization & Riverpod State**:
   - Stores public CDN URL with cache-busting timestamp in `public.users.avatar_url` and `auth.users` metadata.
   - Propagates changes instantly across trip members, friends, and chat cards via Riverpod.
4. **Unified `AppAvatar` Component**:
   - Renders CDN images via `CachedNetworkImage` with memory/disk caching.
   - Gracefully falls back to stylized brand initials when offline or when no photo is set.

### Database Schema
```sql
-- Storage RLS Policies
create policy "Public Avatar Read Access"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "User Avatar Write Access"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars' 
    and (storage.foldername(name))[1] = auth.uid()::text
  );
```

### Impacted Files & Architecture
- `supabase/migrations/021_storage_avatars_bucket.sql` *(NEW — bucket creation and RLS policies)*
- `lib/core/services/storage_service.dart` *(NEW — upload avatar with WebP compression)*
- `lib/core/repositories/profile_repository.dart` *(MODIFY — update avatar URL persistence)*
- `lib/core/widgets/app_avatar.dart` *(NEW — unified avatar widget with CachedNetworkImage & initial fallbacks)*
- `lib/features/profile/profile_screen.dart` *(MODIFY — use `StorageService` for photo pick)*
- `test/widgets/app_avatar_test.dart` *(NEW)*

---

---

## Plan 5: Google Maps Link Resolver & Pin Location Applicable

### Goal
Make Google Maps directly applicable as a way to get places, pin locations on the map, and auto-fill itinerary stops when pasting links (`maps.app.goo.gl`, place links, or coordinates).

### Core Capabilities
1. **Google Maps Link Paste**:
   - Accepts shortened links (`https://maps.app.goo.gl/...`), web links (`google.com/maps/place/...`), or raw lat/long coordinates.
   - Follows HTTP redirects safely via Dio without requiring paid Google Maps API keys.
   - Extracts coordinates (`lat`, `lng`) and location keywords via regex.
2. **Reverse Geocoding & Name Resolution**:
   - Integrates with `PhilippineGeocodingService` to retrieve clean place titles, barangays, municipalities, and provinces.
3. **Interactive Pinning in `MapPinPickerModal`**:
   - Pasting a Google Maps link or coordinates into the map pin search bar immediately flies the camera (`_mapController.move`) and pins the exact location.
   - Includes an "Open in Google Maps" action to view the native pin for validation.
4. **Itinerary Auto-Fill in `AddStopForm`**:
   - Pasting a link fills:
     - **Location & Coordinates** (`lat`, `lng`).
     - **Stop Title** (if empty).
     - **Stop Type Guessing** (Hotel, Food, Transport, Activity) based on place naming patterns.

### Impacted Files
- `lib/core/services/google_maps_parser_service.dart` *(NEW)*
- `lib/core/widgets/inputs/location_picker.dart` *(MODIFY)*
- `lib/core/widgets/inputs/map_pin_picker_modal.dart` *(MODIFY)*
- `lib/features/itinerary/widgets/add_stop_form.dart` *(MODIFY)*
- `test/services/google_maps_parser_service_test.dart` *(NEW)*

---

---

## Plan 6: Tri-Modal Land Transport (Private, Commute, Rental) & Vehicle Garage Fuel Estimator

### Goal
Establish a finalized, strictly land-based **Tri-Modal Transport Architecture** for Tara Travel, categorizing all trips into three distinct modes: **`private` (Personal Vehicle / Convoy)**, **`commute` (Public Transit)**, and **`rental` (Hired / Chartered Vehicle)**. Permanently eliminate all air (`plane`, flights, airport hubs) and sea (`ferry`, shipping lines, boat piers) transport from models, creation wizards, and preset databases. Decouple vehicle configuration into the **User Profile / Settings ("My Garage / My Vehicles")**, while providing tailored travel intelligence: real-time Philippine fuel prices (DOE weekly monitoring) & km/L consumption for private vehicles, land transit terminal hubs (PITX, Cubao, Buendia) & per-pax fare calculators for commute, and daily contract rates with driver fee and fuel policy toggles for rental vans.

### Ground-Truth Schema & Invariants
- **`trips` Table**: Persists high-level `transport_mode` (`'private' | 'commute' | 'rental'`) and mode-specific payload `transport_meta` (JSONB).
- **Strict Prohibition ("No Sea or Plane")**: Tara Travel is anchored on land journeys across Philippine highways and scenic routes. Never query, store, or display air or maritime fields (`flight_number`, `pier`, `airline`, `airport_code`, `ferry_line`).

---

### Core Capabilities

#### 1. Tri-Modal Land Transport Classification (Strictly No Sea or Plane)
- **Eliminate Air & Maritime Transport**:
  - Remove all flight tracking, PNR/booking reference inputs, airline labels, shipping lines, pier names, and airport codes.
  - Drop airport presets (NAIA, Clark, MCIA) and seaport presets (Batangas Port, North Harbor, Cebu Pier 1).
  - Streamline `TransportCategory` to land-only.
- **The Three Land Transport Types**:
  1. **`private`**: Own vehicle (Car, SUV, AUV, Motorcycle, Bicycle) driven by trip participants or traveling in convoy.
  2. **`commute`**: Public land transportation (Provincial/City Bus, Jeepney / E-Jeep, Tricycle, UV Express / FX).
  3. **`rental`**: Chartered or leased private vehicle (Van Hire e.g. HiAce/Urvan, Car Rental, Tourist Coaster).

---

#### 2. Mode A: Private Vehicle (`private`) & User Garage
- **Zero Friction Creation Flow**:
  - Trip setup requires only selecting "Private Vehicle" without entering license plates, vehicle models, or fuel efficiency specs upfront.
- **User Profile "My Garage / My Vehicles"**:
  - Dedicated vehicle manager in user profile/settings:
    - **Nickname / Model**: (e.g. *Toyota Vios 1.5G*, *Yamaha NMAX 155*, *Mitsubishi Montero*).
    - **Vehicle Type**: `sedan`, `suv`, `auv`, `van`, `motorcycle`, `bicycle`.
    - **License Plate / Conduction Sticker**: (optional, for coding notifications).
    - **Fuel Efficiency**: Rated in **km/L** (e.g. `14.2 km/L`).
    - **Fuel Type**: `gasoline`, `diesel`, `electric`.
  - Supports multiple vehicles and a designated primary default.
- **Trip-Level Assignment & Convoy Radar**:
  - Link a saved garage vehicle to the trip in 1 tap (or specify ad-hoc specs).
- **Real-Time DOE Fuel Prices via Edge Function (`fetch-fuel-prices`)**:
  - Deno Edge Function aggregates weekly Philippine Department of Energy (DOE) fuel advisories across Metro Manila, Luzon, Visayas, and Mindanao (Gasoline, Diesel). Caches prices with 24-hour TTL.
  - Users can optionally override with their exact gas station pump receipt price.
- **Automatic Route Fuel Calculation**:
  - Uses Day Map route distance (km), assigned vehicle's km/L, and live regional fuel price:
    $$\text{Liters Needed} = \frac{\text{Total Route Distance (km)}}{\text{Vehicle Efficiency (km/L)}}$$
    $$\text{Estimated Fuel Cost} = \text{Liters Needed} \times \text{Live Fuel Price per Liter (PHP)}$$
- **Gas & Toll Expense Splitting**:
  - When `split_gas` is enabled:
    - Auto-generates an itemized fuel proposal in the Expenses tab.
    - Divides fuel + tollway costs fairly among designated passengers:
      $$\text{Cost Per Passenger} = \frac{\text{Estimated Fuel Cost} + \text{Estimated Tolls}}{\text{Passenger Count}}$$

---

#### 3. Mode B: Public Commute (`commute`) & Land Transit Hubs
- **Tailored for Public Transit Travelers**:
  - Eliminates fuel, km/L, and vehicle maintenance overhead.
- **Philippine Land Transit Departure Hubs (Preset Library)**:
  - Replaces all airport/port presets with major land bus and commute hubs:
    - **PITX**: Parañaque Integrated Terminal Exchange (South/Bicol/Cavite/Batangas routes).
    - **Cubao Bus Port / Araneta Terminal**: Central bus hub (North/Central Luzon & Bicol routes).
    - **Buendia / Gil Puyat Terminal**: Pasay bus stations (Laguna, Batangas, Quezon).
    - **Dau Central Bus Terminal**: Mabalacat, Pampanga (North Luzon hub).
    - **Baguio Grand Terminal**: Gov. Pack Road (Cordillera routes).
    - **Cebu South / North Bus Terminals**: Central Visayas regional land hubs.
- **Per-Pax Fare Estimation**:
  - Direct input for ticket/fare cost per person (e.g., ₱450.00 bus fare per head).
  - Automatically calculates total group transit commitment:
    $$\text{Total Transit Cost} = \text{Fare Per Pax} \times \text{Traveler Count}$$
- **Transit Guidance**:
  - Route / liner operator name (e.g., *Victory Liner Deluxe*, *Genesis Transit*, *UV Express Megamall-Clark*), route code, and drop-off waypoint.

---

#### 4. Mode C: Vehicle Rental (`rental`) & Chartered Van Sharing
- **Tailored for Barkada Van Hire & Leased Vehicles**:
  - Designed specifically for rented tourist vans (HiAce Grandia, NV350 Urvan), self-drive cars, or chartered coasters.
- **Comprehensive Rental Pricing Model**:
  - **Rental Rate Structure**:
    - Daily rental rate (e.g., ₱3,500/day) $\times$ trip duration (days), or flat lump-sum charter fee.
  - **Driver Fee & Allowance Toggle**:
    - Option to declare driver inclusion:
      - *Driver Provided with Rental* vs *Self-Drive*.
      - Add driver daily allowance / meals (e.g., ₱500/day driver per diem).
  - **Fuel Policy Toggle**:
    - **Option 1: Fuel Included**: Rental company covers fuel (no additional gas calculation).
    - **Option 2: Fuel Excluded (Group Splits Gas)**: Integrates with the fuel estimator using standard van fuel consumption (e.g., `9.5 km/L` for Toyota HiAce).
  - **Toll Policy Toggle**: *Tolls Included in Package* vs *Group Splits RFID / Tollways*.
- **Automatic Budget & Shared Expense Insertion**:
  - Automatically posts the total van rental commitment into the group expense pool:
    $$\text{Total Rental Commitment} = (\text{Daily Rate} \times \text{Days}) + (\text{Driver Allowance} \times \text{Days}) + \text{Fuel/Tolls (if excluded)}$$
    $$\text{Individual Share} = \frac{\text{Total Rental Commitment}}{\text{Total Members}}$$

---

### Database Schema & `transport_meta` JSONB Structure

```sql
-- trips table columns remain:
-- transport_mode text check (transport_mode in ('private', 'commute', 'rental')),
-- transport_meta jsonb

-- 1. Private Mode transport_meta JSON:
{
  "mode": "private",
  "vehicle_id": "uuid-optional",
  "vehicle_name": "Toyota Vios 1.5G",
  "vehicle_type": "sedan",
  "fuel_type": "gasoline",
  "kml": 14.5,
  "split_gas": true,
  "split_tolls": true,
  "estimated_toll_cost": 480.00
}

-- 2. Commute Mode transport_meta JSON:
{
  "mode": "commute",
  "commute_type": "bus", -- 'bus', 'jeepney', 'tricycle', 'uv_express'
  "transit_hub_name": "PITX Terminal 1",
  "route_name": "Victory Liner Express to Baguio",
  "fare_per_pax": 520.00,
  "boarding_time": "05:00 AM",
  "drop_off_point": "Baguio Grand Terminal"
}

-- 3. Rental Mode transport_meta JSON:
{
  "mode": "rental",
  "rental_type": "van_hire", -- 'van_hire', 'car_rental', 'coaster'
  "vehicle_model": "Toyota HiAce Grandia 2023",
  "daily_rate": 3500.00,
  "rental_days": 3,
  "has_driver": true,
  "driver_fee_per_day": 500.00,
  "fuel_included": false,
  "tolls_included": false,
  "total_rental_cost": 12000.00
}
```

---

### UI Flow & Refactored `TransportStep` Component

1. **3-Way Hero Mode Selector**:
   - Clean, elevated cards displaying:
     - 🚗 **Private Vehicle** (*"Own car, motorcycle, or squad convoy"*)
     - 🚌 **Public Commute** (*"Bus, jeepney, tricycle, or UV Express"*)
     - 🚐 **Vehicle Rental** (*"Van hire, rented car, or chartered coaster"*)
2. **Contextual Adaptive Sub-Forms**:
   - Selecting **Private**: Shows Garage quick-select dropdown/chips, departure point, and `split_gas` toggle.
   - Selecting **Commute**: Shows land transit hub chips (PITX, Cubao, etc.), departure point, and fare per pax input.
   - Selecting **Rental**: Shows daily rental rate, rental days counter, driver fee toggle, and fuel inclusion switch.
3. **Responsive Safe Insets**:
   - Adheres to `AppResponsive`: wraps in `SingleChildScrollView(physics: BouncingScrollPhysics())`, uses `context.safeBottomPadding(base: 16)` and clamped text scales.

---

### Impacted Files & Architecture
- `lib/core/models/itinerary_model.dart` *(MODIFY — streamline `TransportMode` & `TransportCategory` to land modes, deprecate plane/ferry)*
- `lib/core/models/user_vehicle_model.dart` *(NEW — garage vehicle domain model)*
- `lib/core/models/fuel_price_model.dart` *(NEW — Philippine DOE fuel price model)*
- `lib/core/services/fuel_price_service.dart` *(NEW — Edge Function client with local cache)*
- `supabase/functions/fetch-fuel-prices/index.ts` *(NEW — Deno Edge Function fetching DOE data)*
- `lib/features/create_trip/steps/transport_step.dart` *(REFACTOR — eliminate airport/pier presets & flight/pier inputs; implement 3-mode card selector)*
- `lib/features/profile/profile_screen.dart` *(MODIFY — add "My Vehicles / Garage" entry tile)*
- `lib/features/profile/widgets/user_vehicles_sheet.dart` *(NEW — vehicle CRUD bottom sheet)*
- `lib/features/trip_detail/widgets/transport_summary_card.dart` *(MODIFY — adapt rendering for Private, Commute, or Rental)*
- `test/models/user_vehicle_model_test.dart` *(NEW)*
- `test/services/fuel_price_service_test.dart` *(NEW)*
- `test/features/create_trip/transport_step_test.dart` *(NEW)*

---

---

## Plan 7: Travel Circles (Squads & Barkada Presets) for Multi-Member Trip Creation

*(Referenced from `DEV_IDEA.md` IDEA-009)*

### Goal
Accelerate group trip creation for frequent friend circles, family barkadas, or recurring travel groups. Instead of manually selecting and inviting friends one by one on every trip, users can create and manage reusable **"Travel Circles" (Squads)** in their profile or friends tab, and add the entire roster to a new trip in **1 tap**.

### Core Capabilities
1. **1-Tap Batch Addition with Smart Deduplication**:
   - Tapping a Circle chip instantly adds all circle members into `widget.trip.travelers`.
   - Prevents duplicate insertions if individual members were already selected.
   - Shows progressive badge counter (e.g., *"5/5 from Barkada added"*).
2. **Zero-Maintenance Smart Circles**:
   - **Frequent Co-Travelers**: Automatically computed dynamic cohort based on co-membership in $\ge 2$ completed trips.
   - **Trip Clone Roster**: One-tap action to *"Re-invite roster from [Recent Trip Name]"*.
3. **Default Squad Roles & Expense Presets**:
   - Circle members can have preset roles (e.g., *Treasurer*, *Convoy Driver*).
   - In Step 2 (*Budget Setup*), preset equal split weights and default payer suggestions are automatically prepared.
4. **Single-Action Circle Onboarding (Invite Code / Link)**:
   - Circle owners can share a unique `circle_invite_code` across chat apps (Messenger/Viber/Telegram) to onboard members in one flow.
5. **Strict Privacy Invariant**:
   - All friend display names rendered within Circle cards adhere to `MemberModel.formatDisplayName(name, hideSurname: profile.hideSurname)`.

### Database Schema
```sql
-- 1. Travel Circles
CREATE TABLE public.friend_circles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(name) >= 1 AND char_length(name) <= 50),
    emoji TEXT DEFAULT '👥',
    color_hex TEXT DEFAULT '#D85A30',
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Circle Members Junction Table
CREATE TABLE public.friend_circle_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    circle_id UUID NOT NULL REFERENCES public.friend_circles(id) ON DELETE CASCADE,
    friend_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    default_role TEXT DEFAULT 'member', -- 'member', 'driver', 'treasurer'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (circle_id, friend_user_id)
);
```

### Impacted Files & Architecture
- `supabase/migrations/026_travel_circles.sql` *(NEW — tables, RLS policies, and index definitions)*
- `lib/core/models/friend_circle_model.dart` *(NEW)*
- `lib/core/repositories/friend_repository.dart` *(MODIFY — add circle CRUD & smart suggestions)*
- `lib/core/providers/friend_circles_provider.dart` *(NEW)*
- `lib/features/create_trip/steps/details_step.dart` *(MODIFY — integrate Circle chips into `_showSelectFriendsBottomSheet`)*
- `lib/features/friends/friends_screen.dart` *(MODIFY — add "Circles" management tab)*
- `test/models/friend_circle_model_test.dart` *(NEW)*
- `test/features/friends/friend_circles_test.dart` *(NEW)*

---

---

## Plan 8: Real-Time Live Weather Forecast & Severe Condition Alerts Engine

*(Referenced from `DEV_IDEA.md` IDEA-013)*

### Goal
Replace static mock weather data with an accurate, high-reliability, zero-cost weather forecasting engine powered by **Open-Meteo API**. Provides 10–14 day forecasts, WMO condition interpretation, precipitation probability, UV index, and offline caching for Philippine destinations, while hooking into severe weather alerts and dynamic packing recommendations.

### Core Capabilities
1. **Real-Time Weather Integration via Open-Meteo**:
   - Free, privacy-friendly, zero API key required.
   - Fetches hourly and daily parameters: weather code, high/low temperatures, precipitation probability, UV index, wind speed.
   - WMO interpretation codes mapped to local travel recommendations (Clear, Cloudy, Drizzle, Heavy Rain, Thunderstorm).
2. **Destination Geocoding & Coordinate Resolution**:
   - Uses `trip.departure_lat/lng` or stop coordinates directly ($O(1)$ lookup).
   - Fallback to Open-Meteo Geocoding API with Philippine travel hub fast table and local caching.
3. **Local Cache & Offline Resiliency Layer**:
   - 3-hour TTL with local memory/disk cache.
   - Offline fallback returns cached forecasts tagged `"Offline forecast"`.
4. **UI Integration Across Tara Travel**:
   - **Itinerary DayStrip & DayInsightsHeader**: Real temperatures, rain chance percentage, and severe weather warnings.
   - **AI Packing Assistant**: Pre-fills packing essentials based on forecast (rain gear, sunscreen SPF50+, warm clothing).
   - **Severe Weather Notifications**: Local scheduled alerts for heavy rainfall, typhoons, or gale warnings before departure.

### Impacted Files & Architecture
- `lib/core/services/weather_service.dart` *(CORE COMPLETE — Open-Meteo client, WMO code mapper, and local cache)*
- `lib/core/providers/trip_weather_provider.dart` *(CORE COMPLETE — `tripWeatherProvider` & `tripCurrentWeatherProvider`)*
- `lib/features/itinerary/widgets/day_insights_bar.dart` *(MODIFY — connect live forecast telemetry)*
- `lib/features/packing/widgets/ai_packing_dialog.dart` *(MODIFY — pre-select weather forecast)*
- `lib/core/services/notification_service.dart` *(MODIFY — hook severe weather notifications)*
- `test/services/weather_service_test.dart` *(NEW)*

---

---

## Plan 9: Dual-Lens Budget & Expense Hub (Personal Pocket Tracker + Group Trip Summary)

*(Referenced from `DEV_IDEA.md` IDEA-012)*

### Goal
Transform the Budget screen into a comprehensive **Dual-Lens Financial Hub** that separates and harmonizes **Shared Group Expenses** (split meals, Airbnb, shared vans) with **Private Personal Expenses** (souvenirs, snacks, individual shopping, private transport). Calculates the traveler's **"True Trip Cost"** while providing daily spending pace meters and cash/GCash tracking.

### Core Capabilities
1. **Lens 1: "My Personal Pocket" (Private Expense & Cash Tracker)**:
   - Dedicated private spending budget (e.g., *"₱10,000 personal spending money"*).
   - Private expenses logged with 1 tap (strictly private to user via Supabase RLS, never split or visible to group).
   - **"My True Trip Cost"**: Sum of `(My Personal Out-of-Pocket) + (My Fair Share of Group Expenses)`.
   - Cash vs. GCash/Maya wallet balance tracking (essential for Philippine islands with limited ATMs).
2. **Lens 2: "Group Trip Finances" (Deep Trip Summary & Settlement)**:
   - Master shared expenses with category breakdown charts, split matrix, and debt settlement.
   - Group remaining runway & burn rate.
3. **Daily Budget Burn Gauge (Pace Meter)**:
   - Visual speedometer showing whether the traveler is *Under Budget*, *On Track*, or *Overspending* for the current day.
4. **Philippine Travel Quick Categories**:
   - Preset quick tags: *Tricycle/Jeepney*, *Pasalubong/Souvenirs*, *Island Environmental Fees*, *Street Food/Snacks*, *Activity/Tour Guide Tips*.

### Database Schema
```sql
-- 1. Personal trip budget in trip_members
ALTER TABLE public.trip_members 
ADD COLUMN IF NOT EXISTS personal_budget NUMERIC(12,2) DEFAULT 0.00;

-- 2. is_personal & payment_method in expenses
ALTER TABLE public.expenses 
ADD COLUMN IF NOT EXISTS is_personal BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash'; -- 'cash', 'gcash', 'card', 'maya'

-- 3. RLS Policy for Personal Expenses
CREATE POLICY "Personal expenses visible only to owner"
ON public.expenses FOR SELECT
USING (
    (is_personal = FALSE AND public.user_can_access_trip(trip_id))
    OR (is_personal = TRUE AND paid_by_user_id = auth.uid())
);
```

### Impacted Files & Architecture
- `lib/core/models/expense_model.dart` *(MODIFY — add `isPersonal`, `paymentMethod`)*
- `lib/core/providers/personal_budget_provider.dart` *(NEW — compute personal spent, group share, and pace meter)*
- `lib/features/budget/budget_screen.dart` *(MODIFY — add segmented switch: Personal Pocket vs Group Summary)*
- `lib/features/budget/widgets/personal_pocket_card.dart` *(NEW)*
- `lib/features/budget/widgets/daily_pace_gauge.dart` *(NEW)*
- `lib/features/expenses/widgets/add_expense_form.dart` *(MODIFY — add private expense toggle & payment method)*
- `test/providers/personal_budget_provider_test.dart` *(NEW)*

---

---

## Plan 10: Flexible & Optional Trip Map: Adventure, Multi-Point & Off-Grid Mode

### Goal
Decouple rigid map requirements so trips can be created and managed without requiring a fixed destination coordinate or mandatory map pins. Tailor the experience for **Adventure Trips** (spontaneous roaming, hikes, off-roading, camping) and **Multi-Point Journeys** (road trips hopping across multiple provinces, islands, or stops) without getting locked into a single fixed point on the map.

### Core Capabilities
1. **Optional Map & Destination Coordinates**:
   - Allows users to toggle **"Map Tracking / Route Visualizer"** ON or OFF during trip creation or within Trip Settings.
   - For relaxed staycations, retreat gatherings, or spontaneous exploration, trips do not force lat/long geocoding or show empty/broken map placeholders when coordinates are omitted.
2. **Adventure / Free-Roam Mode**:
   - Designed for treks, island hopping, trail hikes, and unpaved adventures where conventional street navigation is not applicable.
   - Replaces highway turn-by-turn routing with breadcrumb waypoint tracking, compass bearing heading, and elevation/waypoint milestone checklists.
   - Saves battery and cellular data by suspending persistent background tile fetching when off-grid or when offline.
3. **Multi-Point Waypoint Architecture**:
   - Extends trip itinerary routing to support journeys with multiple sequential hubs (e.g., Manila → Tagaytay → Batangas → Puerto Galera) rather than a single destination anchor.
   - The primary map adapts from a single destination pin into a multi-hub route overview connecting all major destination points.
4. **Adaptive UI & Bottom Dock Transformation**:
   - In `ItineraryBottomDock`, if map tracking is disabled:
     - The "Day Map" or "Live Nav" button gracefully adapts into a simplified **"Day Checklist / Timeline"** or **"Adventure Compass"** mode.
     - When stops do have pins, map actions remain optionally accessible on-demand rather than being forced as the primary hero CTA.
5. **Schema & Architectural Invariant Compliance**:
   - Strictly conforms to the Ground-Truth Schema (`trips` table uses `departure_point`, `departure_lat`, `departure_lng`, `destination_details`, and stop-level `itinerary_stops(latitude, longitude)` without referencing forbidden columns like `destination_lat`/`lng`).
   - Stores user map preferences (e.g. `is_map_enabled: false`, `journey_mode: 'adventure' | 'multi_point' | 'standard'`) safely inside `destination_details` JSONB without requiring database migrations.

### Impacted Files & Architecture
- `lib/features/create_trip/steps/details_step.dart` *(MODIFY — add toggle for Optional Map / Adventure / Multi-point mode)*
- `lib/features/itinerary/widgets/itinerary_bottom_dock.dart` *(MODIFY — dynamically adapt dock buttons when map is disabled or in adventure mode)*
- `lib/features/itinerary/widgets/itinerary_map_sheet.dart` *(MODIFY — support multi-point waypoints and graceful empty-coordinate handling)*
- `lib/features/trip_detail/widgets/trip_detail_quick_actions.dart` *(MODIFY — condition Map View action based on trip mode)*
- `test/features/itinerary/itinerary_map_optional_test.dart` *(NEW — verify UI and provider behavior with map enabled vs disabled)*

---

---

## Plan 11: Meet-up Assembly, Smart Countdown & Automatic Departure Detection

### Goal
Automatically insert the trip's specified **Meet-up Point / Departure Point** as the initial itinerary stop (**Day 1, Stop 0: "Meet-up & Assembly"**) and power it with real-time countdowns, customizable grace periods, smart preparation advisories, and automatic departure detection without requiring manual user input.

### Core Capabilities
1. **Automatic Day 1 Stop 0 Generation & Sync**:
   - When a trip is created with a `departure_point` (or updated with one), the system automatically provisions an itinerary stop:
     - **Name**: *"Meet-up & Assembly"* (or custom label e.g., *"Shell SLEX Northbound Assembly"*).
     - **Stop Type**: `transport` (or dedicated `meetup` icon 📍🤝).
     - **Location & Coordinates**: Populated with `departure_lat`, `departure_lng`, and `departure_point`.
     - **Stop Date / Time**: Set to Trip `start_date` at scheduled assembly time.
     - **Order Index**: `0` (guaranteed first stop before all subsequent destinations).
   - If the departure point is edited in Trip Details, the Stop 0 coordinates and location name automatically synchronize.
2. **Meet-up Time with Customizable Grace Period**:
   - **Target Assembly Time**: Set exact target meet-up time (e.g., `05:30 AM`).
   - **Configurable Grace Period**: Optional grace period buffer (e.g., `15 mins`, `30 mins`, or custom minutes).
   - **Wheels-Up / Hard Departure Time**:
     $$\text{Wheels Up Time} = \text{Assembly Time} + \text{Grace Period}$$
     (e.g., Assembly: `05:30 AM` • Grace Period: `15 mins` $\rightarrow$ Wheels Up: `05:45 AM`).
   - Clear visual countdown in Travel HUD & Stop Detail:
     - *"Assembly: 05:30 AM (15 min grace period until 05:45 AM departure)"*.
     - Dynamic urgency chips: *"On Time"*, *"Within Grace Period"*, or *"Late / Rolling Out"*.
3. **Live Countdown & Smart Preparation/Departure Advisory**:
   - Calculates distance between traveler's live GPS position and the departure point / upcoming stop:
     - Recommends preparation time (e.g. *"Prepare to leave by 7:15 AM (35 mins travel time + 15 min buffer)"*).
     - Live indicator: *"On Time"*, *"Leave in 10 mins"*, or *"Running Late"*.
4. **Full Companion Check-In & Arrival Support**:
   - Reuses `StopDetailSheet` companion roster: members mark themselves arrived at the meet-up point with live headcount (*"5/8 arrived at assembly point"*).
5. **Automatic Departure Detection**:
   - **Navigation Launch Trigger**: Opening navigation (*"Navigate"* or *"Open Navigation"* to in-app nav, Google Maps, or Waze) automatically flags departure and logs timestamp.
   - **GPS Movement & Velocity Trigger**: Exiting the departure geofence (>100–200m) or moving at transit speed (>15–20 km/h) automatically registers departure.
   - **Automated Convoy Notification**: Dispatches update to co-travelers: *"Juan has departed for [Stop Name]"*.
6. **Day Map & Street Navigation Integration**:
   - Day Map routing polyline starts directly from the Meet-up Point to Stop 1, ensuring the first driving/transit leg has complete street navigation and accurate total kilometer calculation.

### Impacted Files & Architecture
- `lib/core/services/departure_advisory_service.dart` *(NEW)*
- `lib/features/create_trip/create_trip_flow.dart` *(MODIFY - auto-insert Stop 0 upon trip creation)*
- `lib/core/repositories/trip_repository.dart` *(MODIFY - sync departure point edits with Stop 0)*
- `lib/core/models/itinerary_model.dart` *(VERIFY stop_type meetup support)*
- `lib/features/trip_detail/widgets/smart_departure_advisory_card.dart` *(NEW)*
- `test/services/departure_advisory_service_test.dart` *(NEW)*
- `test/features/itinerary/meetup_stop_auto_creation_test.dart` *(NEW)*

---

---

## Plan 12: Floating Travel Bubble & System Overlay HUD (PiP / Chathead Mode)

### Goal
Allow travelers, drivers, and convoy riders to minimize Tara Travel into a draggable **Floating App Overlay Bubble** (similar to Facebook Messenger chatheads or Google Maps navigation PiP/bubbles). The bubble hovers over other apps (such as Waze, Google Maps, Spotify, or Camera) to provide instant 1-tap access to live trip stats, next stop ETA, convoy companion distances, SOS alerts, and quick expense logging without switching apps.

### Core Capabilities
1. **Draggable Floating Bubble (System-Wide Overlay / PiP)**:
   - Floating circular badge with Tara Travel logo / dynamic active status icon (car, pin, or ETA).
   - Drags smoothly across screen edges with magnetic snap-to-edge docking and flick-to-dismiss target at the bottom.
   - Built with Android `SYSTEM_ALERT_WINDOW` permission or native Android Picture-in-Picture (PiP) / `flutter_overlay_window`.
2. **Compact Travel HUD Mini-Window (Tap to Expand)**:
   - Tapping the bubble expands a lightweight semi-transparent floating card over whatever app the user is currently using:
     - **Next Stop & ETA**: Destination name, remaining distance, and ETA clock.
     - **Convoy Radar**: Real-time distance to the closest squad member / tail car.
     - **Quick Expense Log**: 1-tap button to quickly input a toll fee or gas expense without leaving navigation.
     - **Full App Restore**: Single tap to maximize Tara Travel back to full screen.
3. **In-App Floating Bubble Mode (Zero Extra Permissions Required)**:
   - In addition to system-wide overlay, provides a lightweight in-app floating bubble that floats over the Itinerary and Chat screens, so users can roam different tabs while keeping their Live Navigation / Convoy HUD pinned.
4. **Android Background Safety & Play Store Compliance**:
   - Complies with Android battery and foreground service guidelines by running via a designated `ForegroundService` with persistent low-priority status bar notification (*"Tara Travel Convoy Active — Tap to open bubble"*).
   - Graceful permission check flow: checks for `Settings.canDrawOverlays(context)` with an intuitive onboarding explanation dialog (*"Enable Overlay to view trip stats over Waze & Google Maps"*).

### Impacted Files & Architecture
- `android/app/src/main/AndroidManifest.xml` *(MODIFY — add `SYSTEM_ALERT_WINDOW` and `FOREGROUND_SERVICE`)*
- `pubspec.yaml` *(MODIFY — add `flutter_overlay_window` or native platform channel)*
- `lib/core/services/floating_bubble_service.dart` *(NEW — overlay lifecycle management, state synchronization, and permission handling)*
- `lib/features/navigation/widgets/floating_travel_bubble.dart` *(NEW — draggable in-app and system-overlay UI card)*
- `lib/features/trip_detail/widgets/trip_detail_quick_actions.dart` *(MODIFY — add "Pop out Bubble" trigger)*
- `test/core/services/floating_bubble_service_test.dart` *(NEW — test bubble launch, dismiss, and state stream)*

---

---

## Plan 13: Trip Detail Screen: Ongoing Command Center, HUD & Quick Action Hub

### Goal
Transform the Trip Detail screen when a trip is **ongoing** into an active, actionable Travel Cockpit: replacing the scattered feature grid with an organized **Quick Action Hub**, anchoring a **persistent Full Bottom Navigation Bar**, and displaying an actionable **Quick Stop HUD**, urgent announcements/polls, vehicle telemetry, live destination weather, officer cards, and individual budget tracking.

### Core Capabilities
1. **"Quick Stop Detail" HUD (Replacing Static Stop List)**:
   - Instead of a long scrollable stop list, highlights the **Current Active Stop** & **Next Upcoming Stop**:
     - Large legible stop card with photo/emoji, ETA, time remaining, booking reference, and direct "Navigate" & "Slide to Arrive" actions.
     - **Tap to Open Full Stop Detail**: Tapping anywhere on the quick stop card pops up the standard **`StopDetailSheet`** modal (ETA calculation, booking refs, member arrival roster, expense logging shortcut, and share).
     - Collapsible/compact tray for remaining stops of the day.
2. **Replace Feature Navigation Grid with Quick Action Hub**:
   - Consolidate and replace scattered tiles into a unified, clean **Quick Action Grid**:
     - **Itinerary & Day Route**: Direct shortcut with stop counter badge.
     - **Budget & Split Bill**: Fast GCash/split bill entry with live expense tally.
     - **Squad & Members**: Member avatar circles with organizer badges.
     - **Packing Checklist**: Checklist completion progress chip.
     - **Chat & Polls**: Unread message indicator and active poll tags.
     - **Trip Settings & Invite**: Fast code copying and permission settings.
3. **Full Bottom Navigation Bar (Persistent CTA Dock)**:
   - Permanent, prominent **Full Bottom Navigation Bar**:
     - Fixed at the bottom with safe-area padding and zero obstruction.
     - Features an authoritative primary travel action (e.g. **"Start Live Navigation & Convoy"** when active, or **"Open Itinerary / Day Schedule"** when in planning mode).
     - Includes quick companion buttons (e.g., SOS Emergency, Map View toggle, or 1-tap quick expense log).
   - Preserves proper bottom scroll clearance (`SizedBox(height: 100)`) so all content remains fully legible above the fixed bottom bar.
4. **Urgent Group Announcements & Active Polls**:
   - Dynamic banner for pinned announcements and active group polls (e.g., *"Active Poll: Where to eat lunch? Vote immediately before 12:00 PM"*).
   - Direct 1-tap voting bottom sheet.
5. **Trip Officers & Roles In-Charge**:
   - Highlights designated trip officers for quick communication:
     - **Trip Leader / Coordinator**: Fast call/message button.
     - **Finance Officer / Treasurer**: Budget & cash advances.
     - **Lead Driver / Navigator**: Convoy coordination.
     - **Medic / First Aider**: Emergency contact.
6. **Vehicle Details & Convoy Status**:
   - Shows active vehicle info (Model, Plate, Fuel Status, km/L rating, Passenger roster).
7. **Total Trip Telemetry (Hours & Distance)**:
   - Live odometer metrics: Total elapsed trip hours, remaining travel hours, completed distance (km), and remaining distance (km).
8. **Today's Live Weather Widget**:
   - Real-time forecast for current stop and destination (temperature, condition icon, rain probability, heat index).
9. **Estimated Individual Budget Breakdown**:
   - Personal financial snapshot:
     - Total individual budget share vs. actual spent so far.
     - Remaining personal allowance for the rest of the trip.
     - Shared pool status & pending expense approvals.

### Impacted Files & Architecture
- `lib/features/trip_detail/trip_detail_screen.dart` *(MODIFY - dynamic Ongoing Mode switcher, replace grid with Quick Actions, anchor full bottom navigation bar)*
- `lib/features/trip_detail/widgets/ongoing_trip_hud.dart` *(NEW - Cockpit/HUD view)*
- `lib/features/trip_detail/widgets/trip_quick_actions_grid.dart` *(NEW)*
- `lib/features/trip_detail/widgets/trip_detail_bottom_bar.dart` *(NEW)*
- `lib/features/trip_detail/widgets/active_poll_announcement_banner.dart` *(NEW)*
- `lib/features/trip_detail/widgets/trip_officers_card.dart` *(NEW)*
- `lib/features/trip_detail/widgets/destination_weather_widget.dart` *(NEW)*
- `lib/features/trip_detail/widgets/individual_budget_snapshot.dart` *(NEW)*
- `test/features/trip_detail/ongoing_trip_hud_test.dart` *(NEW)*
- `test/features/trip_detail/trip_detail_quick_action_nav_test.dart` *(NEW)*

---

---

## Plan 14: Day Map Intelligent Route Optimization & Best-Way Routing

### Goal
Upgrade the Day Map from drawing simple linear/straight-line connections between itinerary stops to calculating and rendering the **best realistic path (street-level route navigation / road network polyline)** and optionally calculating the **most optimal sequence (Traveling Salesperson / Route Optimizer)**.

### Core Capabilities
1. **Actual Road Network Routing (Polyline Following Actual Streets)**:
   - Instead of naive direct point-to-point lines (`Polyline([stopA, stopB])`), fetch turn-by-turn road geometries (e.g., via OpenStreetMap / OSRM routing engine or Mapbox Directions API).
   - Display real curves, highways, bridges, and walking/driving roads between consecutive stops on the Day Map.
2. **"Find Best Way" Intelligent Reordering (Optional TSP / Route Reorder)**:
   - Provide an "Optimize Day Route" action that computes the shortest travel distance/time among all day stops.
   - Prevents zigzagging across town by suggesting an optimized visit sequence.
   - Respects user-pinned fixed-time commitments (e.g., hotel check-ins, tour reservations) while reordering flexible stops in between.
3. **Travel Duration & Distance Estimates**:
   - Display distance (km) and estimated travel duration between stops along route segments.
   - Dynamic transport mode toggle (Driving, Walking, Transit) per leg where applicable.
4. **Offline Caching & Fallback**:
   - Cache route polylines locally so previously loaded day routes render instantly offline.
   - Gracefully fallback to straight-line dashed connector if no network is available and no route is cached.
5. **Automatic Arrival Pin Pop-up & Geofence Notification**:
   - **In-App Proximity Pop-up**: When the traveler's live GPS enters the target stop's radius (~50–100m geofence), trigger an arrival card / pin pop-up celebrating arrival: *"You have arrived at [Location Name]!"* with a 1-tap "Mark as Visited / Arrived" button.
   - **Local Push Notification**: If the app is in the background or device is locked, deliver an actionable local notification: *"Arrived at [Stop Name]? Tap to mark as completed."*
   - **Auto Status Progression**: Marking as arrived automatically updates the stop's status to `completed` in Supabase and progresses active routing to the next upcoming stop on the Day Map.

### Impacted Files & Architecture
- `lib/core/services/route_optimization_service.dart` *(NEW)*
- `lib/core/services/geofence_arrival_service.dart` *(NEW)*
- `lib/features/itinerary/widgets/day_map_view.dart` *(MODIFY)*
- `lib/features/itinerary/widgets/arrival_dialog.dart` *(NEW)*
- `lib/features/itinerary/providers/itinerary_provider.dart` *(MODIFY)*
- `test/services/route_optimization_service_test.dart` *(NEW)*
- `test/services/geofence_arrival_service_test.dart` *(NEW)*

---

---

## Plan 15: Comprehensive Mobile Notifications Architecture (Push, In-App Banners & Deep-Link Routing)

### Goal
Deliver a unified, multi-tier notification and in-app event system for Tara Travel. Integrates **Local Timed Alarms**, **Remote Push Notifications (FCM)**, sleek **Dynamic In-App Island Banners**, and **Contextual Deep-Link Routing** so travelers never miss trip updates and can act on alerts with a single tap.

### Core Capabilities
1. **Hybrid Architecture (Local Offline + Cloud Push)**:
   - **Local Timed Notifications**: Schedules offline alarms for departure wheels-up (2h & 30m before meet-up), daily 7:00 AM itinerary summaries, and packing reminders.
   - **Remote Push (FCM / Realtime)**: Pings for trip invites, co-traveler expense logs, convoy SOS alarms, and unread chat messages.
   - **Android 13+ Notification Channels**: Configures `tara_travel_critical` (heads-up, custom SOS alarm tone), `tara_travel_updates` (stop arrivals), and `tara_travel_social` (chat pings).
2. **Dynamic Island / Top Slide-Down In-App Banners**:
   - Modern frosted-glass pill banner sliding smoothly from behind the status bar when new events arrive while using the app.
   - Includes category-tinted avatars, progress timers, and swipe-up to dismiss.
   - Suppresses duplicate OS notifications if the user is already actively viewing that exact screen.
3. **Interactive Quick Actions & Deep-Link Routing**:
   - Notifications contain entity metadata: `trip_id`, `target_screen` (`expenses`, `itinerary`, `chat`, `packing`, `members`), and `target_item_id`.
   - **Tap Routing**:
     - Expense logged → opens `TripDetailScreen` Expenses tab or `ExpenseDetailModal`.
     - Stop arrival / geofence → opens `ItineraryScreen` focused on the stop with 1-tap `[Check In]`.
     - Chat ping → expands inline quick reply or opens `ChatScreen`.
     - Convoy alert → 1-tap `[Wait / Slow Down]` ping without leaving current screen.
   - Visual affordance: interactive cards feature trailing chevrons and hover/press ripple effects.

### Impacted Files & Architecture
- `pubspec.yaml` *(MODIFY — add `flutter_local_notifications: ^18.0.1`, `timezone: ^0.9.4`)*
- `android/app/src/main/AndroidManifest.xml` *(MODIFY — ensure `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, and notification channel metadata)*
- `lib/core/services/notification_service.dart` *(NEW — unified manager coordinating local notification scheduling and channels)*
- `lib/core/services/notification_router.dart` *(NEW — central route resolver for notification payloads)*
- `lib/core/widgets/notifications/in_app_notification_overlay.dart` *(NEW — global overlay banner renderer with slide animations & gesture dismissal)*
- `lib/core/services/in_app_notification_manager.dart` *(NEW — FIFO queue manager, duplicate suppression, and audio/haptic trigger)*
- `lib/features/notifications/notifications_screen.dart` *(MODIFY — clickable cards, visual chevrons, and badge counter sync)*
- `lib/features/trip_detail/trip_detail_screen.dart` *(MODIFY — support `initialTabIndex` and `highlightItemId`)*
- `test/core/services/notification_service_test.dart` *(NEW)*
- `test/services/notification_router_test.dart` *(NEW)*
- `test/core/widgets/in_app_notification_overlay_test.dart` *(NEW)*

---

---

## Plan 16: Gemini Embedded AI Travel Copilot & Assistant

### Goal
Embed Google's **Gemini AI** directly into Tara Travel to deliver an intelligent in-app travel copilot. Enables conversational trip generation, intelligent itinerary restructuring, local food/attraction recommendations, automated budget and expense anomaly audits, and packing list synthesis — with flexible dual-path execution (secure Supabase Edge Function or client API key fallback).

### Core Capabilities
1. **Conversational Travel Planning & Instant Trip Generation**:
   - Users can describe their dream trip in natural language (e.g. *"Plan a 4-day chill weekend in Sagada for 5 friends with P20,000 total budget, lots of local coffee and cave exploration"*).
   - Gemini parses the intent and returns a structured JSON payload that users can preview in a rich **AI Trip Proposal Card** and launch with 1-tap (**"🚀 Create & Launch Trip"**).
2. **Context-Aware In-Trip Assistant**:
   - Accessible from the Trip Detail Screen HUD or Itinerary bottom dock as a discreet **"✨ Tara Copilot"** floating button or quick action.
   - Leverages `TripContextSerializer` to inject current trip details (destination, dates, stops, budget, weather forecast, traveler count) into the system prompt.
   - Answers contextual travel questions:
     - *"What should we do if it rains this afternoon in Tagaytay?"*
     - *"Suggest 3 famous budget-friendly dinner spots near our current stop."*
     - *"How much budget do we have left per person for Day 3?"*
3. **Smart Actions & Interactive Tool Calling**:
   - Copilot emits actionable UI chips alongside markdown answers:
     - **[➕ Add Stop to Itinerary]**: Directly adds a suggested attraction or diner to the user's active day schedule.
     - **[🎒 Add Packing Items]**: Auto-populates missing climate-appropriate packing essentials.
     - **[💸 Log Expense]**: Pre-fills cost estimations into the expense tracker.
4. **Dual-Path Resilient Architecture (Edge Function + Direct API Fallback)**:
   - **Primary (Zero Secrets Leakage)**: Calls Supabase Edge Function `tara-copilot`, proxying requests to Google Gemini 1.5 Flash / Gemini 2.0 with server-side API keys and rate limiting.
   - **Fallback / Power User**: Supports optional user-provided Gemini API Key stored in `flutter_secure_storage` via `google_generative_ai` package when offline or on custom developer deployments.
5. **Local Philippine Travel Prompt Engineering & Grounding**:
   - Tailored system prompt primed with Philippine geography, transport options (trike, jeepney, bus, van rental, tollways), local holiday timings, and peso budget norms.

### Impacted Files & Architecture
- `pubspec.yaml` *(MODIFY — add `google_generative_ai: ^0.4.6`)*
- `lib/core/services/gemini_ai_service.dart` *(NEW — Gemini client, prompt grounding, JSON schema parsing, and API caller)*
- `lib/features/ai_assistant/screens/tara_copilot_sheet.dart` *(NEW — conversational chat modal with streaming bubbles and action chips)*
- `lib/features/ai_assistant/widgets/ai_trip_proposal_card.dart` *(NEW — rich preview for 1-tap trip creation)*
- `lib/features/trip_detail/widgets/trip_detail_quick_actions.dart` *(MODIFY — add "AI Copilot" quick action)*
- `test/core/services/gemini_ai_service_test.dart` *(NEW — mock responses, schema validation, and tool-call parsing)*

---

---

## Plan 17: Supabase & Middleware App Versioning & OTA Updates

### Goal
Implement a rock-solid app versioning, compatibility, and maintenance gatekeeper powered by **Supabase Remote Config**, Shorebird OTA Code Push, and the **Tara Middleware Gateway (Plan 17)**. Prevents stale mobile clients from encountering schema mismatch crashes or corrupted RLS writes after database migrations, while enabling instant Dart code fixes without Play Store delays, remote maintenance mode, and automated release pipelines.

### Core Capabilities
1. **Remote Versioning Schema (`app_versions` / `remote_config`)**:
   - Stores authoritative platform release records in Supabase: `min_supported_version`, `latest_version`, `force_update_url`, `maintenance_mode`, and `release_notes`.
2. **Three-Tier User UX Modals**:
   - **Tier 1: Mandatory Force-Update (Hard Gate)**: Non-dismissible modal with primary CTA: **"Update App"**.
   - **Tier 2: Soft Update Recommendation (Dismissible)**: Friendly bottom sheet (*"New features available in v1.4!"*).
   - **Tier 3: Maintenance Mode Screen**: Locks UI gracefully with status badge and estimated back-online timer.
3. **Shorebird Over-The-Air (OTA) Code Push**:
   - Integrates `shorebird_code_push` for instant over-the-air Dart patches pushed directly to users' phones in minutes, skipping app store delays for bugfixes and UI improvements.
4. **Non-Google Play Direct Cloud Update Channels**:
   - **Supabase Storage Direct APK Installer**: Downloads release APK via Dio with an animated progress bar and launches Android system install intent (`FileProvider`).
   - **Firebase App Distribution**: Direct beta tester dispatch via CI/CD.
5. **🤖 Fully Automated GitHub Actions Pipeline (`auto_release.yml`)**:
   - Pushing or merging to release branch (`live`) automatically compiles release APK, uploads to Supabase Storage, dispatches to Firebase, and updates `app_versions` table in Supabase DB.

### Impacted Files & Architecture
- `.github/workflows/auto_release.yml` *(NEW — automated build, Supabase Storage upload, and version DB bump)*
- `pubspec.yaml` *(MODIFY — add `package_info_plus: ^8.0.0`, `open_filex: ^4.5.0`, `shorebird_code_push`)*
- `android/app/src/main/AndroidManifest.xml` *(MODIFY — add `REQUEST_INSTALL_PACKAGES` and `FileProvider`)*
- `lib/core/services/app_version_service.dart` *(NEW — semantic version comparator, Supabase config fetcher, and update status provider)*
- `lib/core/services/apk_download_installer.dart` *(NEW — downloads APK from Supabase Storage with progress and launches installer)*
- `lib/core/widgets/versioning/force_update_screen.dart` *(NEW)*
- `lib/core/widgets/versioning/soft_update_sheet.dart` *(NEW)*
- `lib/main.dart` *(MODIFY — insert version verification check during bootstrap)*
- `test/core/services/app_version_service_test.dart` *(NEW)*

---

---

## Plan 18: Tara Laravel Middleware & SuperAdmin Dashboard (Universal Links, CMS & Ops)

*(Referenced from `DEV_IDEA.md` IDEA-005)*

### Goal
Build a lightweight, production-grade **Laravel 11 + Filament v3** web middleware and SuperAdmin dashboard (hosted on zero-cost tiers: Fly.io/Render with Cloudflare Edge CDN). Handles **Universal Deep Linking** (web-to-app gateway for invite links, OpenGraph social previews), curated trip template CMS, user support ticket helpdesk, and dynamic remote config.

### Core Capabilities
1. **Universal Deep Linking & Social Previews (Web-to-App Gateway)**:
   - `https://tara-travel.app/join/{code}`:
     - Mobile browser: redirects into Flutter app via Android App Links (`tara://trip/join?code=...`) or Play Store fallback.
     - Desktop browser: renders branded preview page with trip details and QR code to scan.
   - Dynamic OpenGraph cards with destination cover photo and trip dates for Messenger, WhatsApp, and Telegram.
   - Hosts `assetlinks.json` and `apple-app-site-association` at domain root.
2. **Curated Itinerary CMS (Filament v3)**:
   - Visual trip template builder (e.g., *"4D3N Coron Island Adventure"*, *"3D2N Baguio Food Trail"*).
   - Manage featured itineraries, seasonal banners, and spotlight destinations on the mobile home screen.
3. **User Support & Incident Helpdesk**:
   - Triage user-submitted bug reports and travel dispute flags with sanitized diagnostic telemetry.
   - Send direct in-app notification responses and broadcast system travel advisories.
4. **Dynamic Remote Config & Ops Governance**:
   - No-store-release updates for currency rates, default split methods, and category taxonomies.
   - Community moderation: freeze abusive accounts or force-revoke compromised invite codes.

### Impacted Files & Architecture
- `backend/` *(NEW — Laravel 11 project with Filament v3 panel)*
- `backend/routes/web.php` *(NEW — deep link routes: `/join/{code}`, `/trip/{id}`, `/friend/{code}`)*
- `backend/public/.well-known/assetlinks.json` *(NEW — Android App Links verification)*
- `backend/Dockerfile` *(NEW — multi-stage non-root container for Fly.io/Render deployment)*
- `lib/core/middleware/gateway_interceptor.dart` *(MODIFY — handshake with middleware headers)*

---

---

## Plan 19: Universal Responsive Layout Engine & Zero-Overflow Architecture

### Goal
Dynamically adapt all screens, modal bottom sheets, and dialogs across Tara Travel to any mobile form factor (from compact ~4.7″ devices like iPhone SE / 320–360dp Androids to tall flagships, foldables, and tablets) and accessibility text scaling, eliminating hardcoded viewport arithmetic and UI overflow errors.

### Core Capabilities
1. **Global Text Scaler Bounds (`AppResponsive.clampedTextScaleBuilder`)**:
   - Injected at root `MaterialApp.builder`.
   - Clamps `MediaQuery.textScaler` between `0.85` and `1.20` so extreme accessibility enlargement never ruptures fixed-height chips, pills, or action docks.
2. **Centralized Responsive Tokens & Context Extensions (`lib/core/theme/app_responsive.dart`)**:
   - Standard logical breakpoints: `compactWidth = 360`, `standardWidth = 414`, `tabletWidth = 600`.
   - Dynamic `context.responsiveHPad` (16dp compact, 20dp standard, 24dp wide).
   - Inset-aware sheet bounds: `context.sheetMaxHeight(fraction)` prevents sheet headers from colliding with notch/status bars.
   - Keyboard & gesture safe insets: `context.safeBottomPadding(base)` and `context.keyboardBottomPadding(base)`.
3. **Hardcoded MediaQuery Arithmetic Eradication**:
   - All modal sheets (Itinerary Stop Detail, Map Sheet, Quick Budget, Poll Sheet, Chat Attachments, Pinned Messages, Friend Actions, SOS Modal, Profile QR) audited and refactored.
   - Screen-level padding across Itinerary, Budget, Packing, Navigation, Explore, Members, and Notifications updated to utilize responsive context helpers.

### Impacted Files & Architecture
- `lib/core/theme/app_responsive.dart` *(NEW — centralized tokens, breakpoints, and BuildContext extensions)*
- `lib/main.dart` *(MODIFY — registered clampedTextScaleBuilder in MaterialApp.builder)*
- `lib/features/itinerary/widgets/stop_detail_sheet.dart` *(MODIFY — responsive sheetMaxHeight & safeBottomPadding)*
- `lib/features/itinerary/widgets/itinerary_map_sheet.dart` *(MODIFY — responsive sheetMaxHeight)*
- `lib/features/itinerary/widgets/navigate_route_button.dart` *(MODIFY — responsive sheetMaxHeight)*
- `lib/features/itinerary/itinerary_screen.dart` *(MODIFY — responsive keyboard insets)*
- `lib/features/packing/widgets/packing_template_modals.dart` *(MODIFY — responsive sheetMaxHeight)*
- `lib/features/packing/widgets/ai_packing_dialog.dart` *(MODIFY — responsive keyboardBottomPadding)*
- `lib/features/packing/packing_screen.dart` *(MODIFY — responsive safeBottomPadding & keyboardBottomPadding)*
- `lib/features/profile/profile_screen.dart` *(MODIFY — responsive safeBottomPadding & sheetMaxHeight)*
- `lib/features/chat/widgets/create_poll_sheet.dart` *(MODIFY — responsive sheetMaxHeight & keyboardHeight)*
- `lib/features/chat/widgets/chat_attachment_picker_sheet.dart` *(MODIFY — responsive sheetMaxHeight)*
- `lib/features/chat/chat_screen.dart` *(MODIFY — responsive sheetMaxHeight)*
- `lib/features/home/widgets/quick_budget_sheet.dart` *(MODIFY — responsive keyboardBottomPadding)*
- `lib/features/home/home_screen.dart` *(MODIFY — responsive topInset)*
- `lib/features/navigation/navigation_screen.dart` *(MODIFY — responsive sheetMaxHeight)*
- `lib/features/navigation/live_navigation_screen.dart` *(MODIFY — responsive topInset)*
- `lib/features/navigation/widgets/nav_panels.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/navigation/widgets/group_tracker_tab.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/navigation/widgets/privacy_control_sheet.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/navigation/widgets/sos_emergency_modal.dart` *(MODIFY — responsive keyboardBottomPadding)*
- `lib/features/navigation/widgets/proximity_alert_tab.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/navigation/widgets/navigate_to_member_sheet.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/navigation/widgets/arrived_tab.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/explore/explore_screen.dart` *(MODIFY — responsive sheetMaxHeight & safeBottomPadding)*
- `lib/features/friends/friends_screen.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/friends/widgets/friend_list_item.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/members/members_screen.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/notifications/notifications_screen.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/trips/widgets/join_trip_modal.dart` *(MODIFY — responsive keyboardBottomPadding)*
- `lib/features/trip_detail/trip_detail_screen.dart` *(MODIFY — responsive topInset)*
- `lib/features/create_trip/steps/transport_step.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/create_trip/steps/budget_step.dart` *(MODIFY — responsive keyboardBottomPadding)*
- `lib/features/budget/budget_screen.dart` *(MODIFY — responsive keyboardHeight)*
- `lib/features/budget/widgets/set_allowance_sheet.dart` *(MODIFY — responsive keyboardBottomPadding)*
- `lib/core/widgets/inputs/map_pin_picker_modal.dart` *(MODIFY — responsive sheetMaxHeight)*
- `lib/core/widgets/multi_member_picker_sheet.dart` *(MODIFY — responsive sheetMaxHeight)*
- `lib/core/widgets/share/share_trip_modal.dart` *(MODIFY — responsive safeBottomPadding)*
- `lib/features/activity/activity_log_screen.dart` *(MODIFY — responsive safeBottomPadding)*

