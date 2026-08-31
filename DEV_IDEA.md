# Tara Travel — Developer Ideas & Architecture Backlog (`DEV_IDEA.md`)

This document tracks developer proposals, feature concepts, and architectural enhancement ideas for the **Tara Travel** application.

---

## ✅ IDEA-001: Standardized & Brand-Unified Feedback System (Alerts, SnackBars & Modals) [COMPLETED]

### 1. Context & Motivation
Currently, alerts, error messages, action confirmations, and floating SnackBars across screens (`trip_detail_screen.dart`, `join_trip_modal.dart`, `profile_screen.dart`, etc.) are implemented ad-hoc using raw `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` or standard alert dialogs with varying styling, borders, and durations.

### 2. Core Proposal
Unify all alerts, notifications, toasts/snackbars, and confirmation dialogs across Tara Travel into a single, cohesive, brand-aligned component system governed by the brand identity design tokens.

---

### 3. Recommended Architectural Design & Standards

#### A. Brand & Aesthetic Guidelines
In accordance with Tara Travel Brand Identity (`brand-identity.md` & `0_Brand_identity.html`):
- **Typography**: 
  - Alert/Dialog Titles: `Playfair Display`, Bold (20px)
  - Message Body & Action Labels: `DM Sans`, Regular / Medium (14px)
- **Geometry & Shape**:
  - Dialogs & Sheets: `20px` to `24px` border radius
  - Floating Toast/Snackbar: `14px` border radius with subtle border (`1px` `#E8E8E8` or glass stroke)
  - Buttons inside alerts: `12px` border radius
- **Color Palettes by Alert Intent**:

| Alert Type | Background | Border / Accent | Icon & Text Highlight | Icon |
| :--- | :--- | :--- | :--- | :--- |
| **Primary / Info** | `AppColors.sand` (`#FAECE7`) or `AppColors.deepEarth` (`#2C1A14`) | `AppColors.primaryLight` (`#F0997B`) | `AppColors.primary` (`#D85A30`) | `Icons.info_outline_rounded` |
| **Success** | `AppColors.greenBg` (`#EAF3DE`) | `AppColors.greenBright` (`#10B981`) | `AppColors.green` (`#3B6D11`) | `Icons.check_circle_outline_rounded` |
| **Warning** | `AppColors.amberBg` (`#FFF8ED`) | `AppColors.amber` (`#EF9F27`) | `AppColors.amberText` (`#854F0B`) | `Icons.warning_amber_rounded` |
| **Error / Destructive**| `AppColors.redLight` (`#FEE2E2`) | `AppColors.red` (`#EF4444`) | `AppColors.red` (`#EF4444`) | `Icons.error_outline_rounded` |

---

#### B. Component Architecture (`lib/core/widgets/feedback/`)

Create reusable, type-safe feedback services and widgets:

1. **`AppFeedback` / `AppSnackBar`**:
   - Centralized static helper methods:
     - `AppFeedback.showSuccess(BuildContext context, String message, {String? title, VoidCallback? onAction, String? actionLabel})`
     - `AppFeedback.showError(BuildContext context, String message, {String? title, VoidCallback? onRetry})`
     - `AppFeedback.showWarning(BuildContext context, String message)`
     - `AppFeedback.showInfo(BuildContext context, String message)`
   - Floating layout with top/bottom anchor option, micro-haptics (`HapticFeedback.lightImpact()`), and auto-dismiss timing.

2. **`AppAlertDialog` / `AppConfirmDialog`**:
   - Uniform modal for destructive confirmations (e.g. Leave Trip, Delete Itinerary Stop, Cancel Booking).
   - Brand-styled buttons: Primary coral action (`#D85A30`) with 12px radius, Sand/ghost button for Cancel.

3. **`AppBanner` / `InlineAlert`**:
   - Embedded contextual alerts for forms and empty states with warm tint backgrounds and crisp SVG/rounded iconography.

---

### 4. Implementation Steps
1. [x] **Design Tokens**: Verify semantic color pairings in [app_colors.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_colors.dart).
2. [x] **Theme Config**: Update `snackBarTheme` and `dialogTheme` in [app_theme.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_theme.dart).
3. [x] **Core Components**: Create `app_feedback.dart`, `app_dialog.dart`, and `app_banner.dart` in `lib/core/widgets/feedback/`.
4. [x] **Refactoring Migration**: Replace all raw `ScaffoldMessenger.of(context).showSnackBar(...)` calls with `AppFeedback` across all feature modules.

> **Status**: Completed (`IMP-060`)

---

## ✅ IDEA-002: Streamlined Itinerary Experience via Progressive Disclosure & Unified Action Hub [COMPLETED]

### 1. Context & Pain Points
The current Itinerary screen (`itinerary_screen.dart`, ~1,600+ lines) is packed with features:
- Day strips, view toggles (List/Timeline), weather widgets, budget fulfillment progress, transit conflict badges, smart suggestions chips, roll call sheets, arrival pill simulations, action menus, navigation launch buttons, and expense logging triggers.
- **Problem**: Too many visible micro-buttons, banners, and toolbars cause cognitive overload, making the screen feel crowded and difficult to scan when traveling on the go.

### 2. Core Proposal: "Clean Canvas, Contextual Depth"
Declutter the visual presentation while retaining **100% of existing functionality** through **Progressive Disclosure**, **Consolidated Action Hubs**, and **Collapsible Smart Summary Drawers**.

---

### 3. Recommended UX & Architectural Redesign

```
┌──────────────────────────────────────────────────────────┐
│  [< Back]     Day 1 · June 14, 2026       [ ⋯ More / Share]│
│  [  D1  ]  [  D2  ]  [  D3  ]  [  D4  ]  [  + Day  ]     │
├──────────────────────────────────────────────────────────┤
│  ⚡ [ Day Insights: ☀️ 29°C · ₱2,400 spent · 3 stops  ▼ ] │ <-- (Accordion Card)
├──────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐  │
│  │ 09:00 AM  🏨 Check-in at Shangri-La         [⋮]    │  │ <-- Clean Stop Card
│  │           📍 Station 2, Boracay                    │  │
│  │ 🚗 15 min transit                                  │  │
│  │ 12:30 PM  🍽️ D'Talipapa Lunch               [⋮]    │  │
│  │           💰 ₱1,200 · Paid by Juan                 │  │
│  └────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────┤
│  [ 🗺️ View Map & Navigate ]       [ ＋ Add Stop ]       │ <-- Sticky Floating Dock
└──────────────────────────────────────────────────────────┘
```

#### A. Progressive Disclosure & Consolidation Patterns
1. **Unified Context Pill / Accordion (`DayInsightsBar`)**:
   - Merge `DayBudgetBar`, `WeatherWidget`, and `ItineraryFulfillmentBanner` into a single, slim expandable header pill (e.g. `☀️ 28°C · ₱1,450 / ₱5,000 · 3/5 Done  ▾`).
   - Tapping expands the full breakdown without cluttering the active scroll view.
2. **Consolidated "⋯" More Action Sheet (Header & Day Level)**:
   - Move secondary actions (*Share Itinerary*, *Export to Calendar*, *Roll Call*, *Day Reorder/Delete*, *Transit Conflict Diagnostics*) into a single, clean bottom sheet accessible via a top-right `⋯` button.
3. **Streamlined Stop Cards (`StopCardV2`)**:
   - Keep default card footprint minimal: Time, Icon/Category, Title, Location, and Status check.
   - Secondary metadata (Booking references, assigned members, transit notes, expense link) reveal on card tap or swipe-to-reveal quick actions (*Edit*, *Log Expense*, *Directions*).
4. **Smart Contextual Bottom Dock & Automated GPS Geofencing**:
   - Replace multiple scattered buttons with a unified bottom floating bar containing only primary travel actions:
     - Primary Button: `+ Add Stop`
     - Secondary Action: `🗺️ Map View / Navigate` toggle
   - **Automated GPS Proximity Detection (Live Geofence)**:
     - Automatically monitor user location (via `Geolocator` / `LocationStreamProvider` with low-power interval when the screen is active).
     - Calculate distance (`Geolocator.distanceBetween`) against next upcoming stops with coordinates (`latitude`, `longitude`).
     - When user is within arrival threshold (e.g. $\le 100\text{m}$ - $150\text{m}$), automatically display the floating `ArrivalPill` prompting *"You're near [Stop Name] — Tap to mark arrived"*.
     - Provide auto-suppression / cooldown to prevent repeated popups once dismissed or marked completed.
     - Keep manual simulation trigger only in developer/debug tools.
5. **Smart Suggestions as a Dismissible Accordion or Swipe Drawer**:
   - Keep `SmartSuggestionChips` collapsed into a subtle `💡 Suggestions available (3)` badge so it doesn't push itinerary items off-screen.

---

### 4. Implementation Steps
1. [x] **UX Architecture**: Create `DayInsightsHeader` consolidating weather, budget summary, and progress metrics into a collapsible accordion.
2. [x] **Action Consolidation**: Build `ItineraryActionSheet` to centralize Calendar sync, Sharing, Roll Call, and Day configuration.
3. [x] **Component Refactoring**: Modernize `StopCard` with swipe-actions / tap-to-expand for expense logging and navigation.
4. [x] **Bottom Dock**: Implement a sleek floating action bar for `Add Stop` and `Map View / Navigate Route`.
5. [x] **Automatic GPS Geofencing**: Hook real-time location stream into the active day's stops to automatically trigger `ArrivalPill` within a configurable radius ($\approx 150\text{m}$), with dismiss cooldowns and battery-efficient location sampling.
6. [x] **Screen Modularization**: Break `itinerary_screen.dart` into smaller, dedicated sub-widgets to improve maintainability and performance.

> **Status**: Completed (`IMP-061`)

---

## ✅ IDEA-003: Real-Time Group Live Location Sharing, Convoy Tracking & Direct Member Navigation [COMPLETED]

### 1. Context & Motivation
During group travels (road trips, island hopping, crowded markets, hiking), companions frequently get separated, take different transport routes, or need to regroup quickly. While Tara Travel currently has mock live telemetry models and radar widgets (`lib/features/navigation/`), it lacks:
1. **Direct "Navigate to Member" / Find Companion**: No quick action to open turn-by-turn routing directly to a separated friend's real-time coordinates.
2. **Production-Grade Live Sync**: Real-time position broadcasting using Supabase Realtime / WebSockets without battery drain.
3. **Smart Convoy & Separation Safeguards**: Automated alerts when a group member falls behind or strays from the itinerary route.

---

### 2. Core Feature Specifications & Best Practice Proposals

#### A. 🧭 Direct "Navigate to Member" (Member-as-Waypoint Routing)
- **One-Tap Routing to Friend**:
  - In `GroupTrackerTab` and `LiveMapTab`, tapping on any member card or map avatar reveals a prominent **"🧭 Navigate to [Name]"** action.
  - Supports **In-App Turn-by-Turn Route Preview** (drawing live dynamic polyline to member's coordinates) or **External Navigation Launch** (Google Maps, Waze, Apple Maps via deep link intent with destination coordinates `geo:lat,lng` / `https://www.google.com/maps/dir/?api=1&destination=lat,lng`).
- **Live Dynamic Waypoint Tracking**:
  - In-app route polyline updates automatically as the moving companion updates their position.
  - Displays real-time delta: *"Juan is 850m away · 3 min walking / 1 min driving"*.
- **"Meet Halfway" Smart Suggestion**:
  - Computes the geographical midpoint between you and the member, proposing nearby cafes or landmarks along the itinerary as a mutual meetup spot.

#### B. 🛰️ High-Efficiency Real-Time Location Engine
- **Supabase Realtime Broadcast Channels**:
  - Use ephemeral WebSocket broadcast channels (`trip:location:{trip_id}`) instead of writing every coordinate update to Postgres disk, eliminating database I/O overhead and latency ($<150\text{ms}$ updates).
  - Store only the last-known position checkpoint on session close or trip checkpoint intervals.
- **Adaptive Battery & Throttling Governance**:
  - **Speed-Adaptive Polling**:
    - *Stationary / Idle*: Update every $60\text{s}$ or when displacement $> 25\text{m}$.
    - *Walking*: Update every $15\text{s}$ or displacement $> 10\text{m}$.
    - *Driving / En Route*: Update every $5\text{s}$ or displacement $> 30\text{m}$.
  - **Background WorkManager / Foreground Service**: Active high-frequency polling strictly enabled when active trip navigation mode is ON; throttles to low-power geofencing when idle.

#### C. 🛡️ Convoy Intelligence & Safety Radar
- **Group Dispersion ("Convoy Break") Alarm**:
  - If a member lags beyond a configurable threshold (e.g. $>2.0\text{km}$ behind during a group road trip), sends a silent push / in-app warning: *"⚠️ Mark fell behind (2.4 km back)"*.
- **Proximity "Found You" Haptic Radar**:
  - When approaching a member within $30\text{m}$ in crowded venues, the app triggers pulsating haptic feedback with a directional compass heading.
- **One-Tap Emergency / Regroup Ping ("SOS / I'm Lost")**:
  - Broadcasts immediate high-priority beacon to all trip members with exact GPS coordinates and battery level.

#### D. 🔒 Privacy & Local-First Battery Controls
- **Ghost / Pause Mode**: Instant toggle to pause location broadcast with customizable timer (e.g., *"Pause sharing for 1 hour"* or *"Stop sharing when trip day ends"*).
- **Precision Control**: Option to share *Exact Location* vs. *Approximate Neighborhood* ($\approx 500\text{m}$ fuzzy bubble) for non-close acquaintances.
- **Name Privacy Invariant**: Automatically formats names via `MemberModel.formatDisplayName(hideSurname: true)` across all tracking badges and map popups.

---

### 3. Architectural Component Breakdown

```
┌────────────────────────────────────────────────────────────┐
│                   Trip Location Channel                    │
│             (Supabase Realtime Broadcast)                  │
└────────────────────────────┬───────────────────────────────┘
                             │
      ┌──────────────────────┴──────────────────────┐
      ▼                                             ▼
┌───────────────────────────┐         ┌───────────────────────────┐
│ LocationBroadcaster       │         │ LocationSubscription      │
│ (Geolocator + Throttling) │         │ (Member Telemetry Store)  │
└───────────────────────────┘         └─────────────┬─────────────┘
                                                    │
                     ┌──────────────────────────────┼──────────────────────────────┐
                     ▼                              ▼                              ▼
        ┌─────────────────────────┐    ┌─────────────────────────┐    ┌─────────────────────────┐
        │ LiveMapTab (Map Pins)   │    │ GroupTrackerTab         │    │ Proximity / Convoy      │
        │ + "Navigate to Member"  │    │ + ETA & Member Cards    │    │ Radar Alerts            │
        └─────────────────────────┘    └─────────────────────────┘    └─────────────────────────┘
```

---

### 4. Implementation Steps
1. [x] **Realtime Infrastructure**: Implement `LocationBroadcastService` over Supabase Realtime broadcast channels for zero-latency peer location streaming.
2. [x] **Navigate-to-Member Action**: Add "Navigate to Member" bottom-sheet and quick action button in `GroupTrackerTab` and `LiveMapTab`, supporting both in-app routing and external GPS intents (Google Maps / Waze).
3. [x] **Adaptive Location Engine**: Create Riverpod `LiveLocationNotifier` with speed-adaptive sampling and battery saver modes.
4. [x] **Convoy Alert System**: Add background/foreground separation detection that alerts trip members when someone drifts outside the convoy perimeter.
5. [x] **Privacy Controls**: Implement Ghost Mode, duration-based sharing timers, and approximate location fuzzing.

> **Status**: Completed (`IMP-062`)

---

## 💡 IDEA-004: Interactive Trip Chat, Collaborative Polls & Contextual Activity Hub

### 1. Context & Motivation
Currently, group decision-making during trips (e.g. *"Where should we eat for dinner?"*, *"What time do we leave for the tour?"*, *"Split costs for boat rental?"*) creates chaotic back-and-forth messaging. The current chat screen (`lib/features/chat/chat_screen.dart`) is a basic text-only stream.
Trip members need **Interactive In-Chat Polls**, **Contextual Pinning (Itinerary / Expense triggers)**, **Media & Live Location attachments**, and **Auto-Resolution Actions** that directly update the trip plan.

---

### 2. Core Feature Specifications & Best Practice Proposals

#### A. 📊 Live Interactive Travel Polls (Integrated in Chat & Itinerary)
- **Trip-Focused Poll Types**:
  - **Single / Multi-Choice Poll**: Quick votes on restaurants, activities, or wake-up times.
  - **Date / Time Availability Grid**: Members vote on departure times or activity slots.
  - **Budget / Budget-Cap Poll**: Group consensus on maximum per-person spend.
  - **"Suggest an Option" (Crowdsourced Options)**: Allows trip members to append their own restaurant/spot nominees to an open poll.
- **Real-Time Live Vote Sync**:
  - Votes update live across all open screens via Supabase Realtime broadcast/table listeners.
  - Real-time animated progress bars showing member avatars on their chosen options.
- **Automated "Winner to Itinerary" Conversion**:
  - When the poll creator or trip owner closes the poll (or expiration countdown ends), the winning option features a **"➕ Add Winner as Itinerary Stop"** or **"💸 Create Expense Draft"** one-tap action.

#### B. 💬 Modern Rich Chat & Travel Utility Embeds
- **Interactive Trip Cards in Chat**:
  - **Itinerary Stop Snippet**: Share a specific stop card directly into the chat with live status and Google Maps directions button.
  - **Expense Request Card**: Inline bill split cards where members can tap *"Mark as Paid"* directly within the chat bubble.
  - **Packing List Urgent Ping**: Share unassigned or missing packing items into chat with a *"I'll bring this!"* claim button.
  - **Live Location Drop**: Send a static landmark pin or a 15-minute live sharing widget directly in chat.
- **Message Reactions & Emoji Micro-Interactions**:
  - Fast emoji reactions (❤️, 👍, 🏖️, 🚗, 🍽️, ⏰) with haptic feedback.
- **Pinned Announcements & Itinerary Notice Banner**:
  - Trip admins can pin critical messages (e.g., flight booking refs, meeting gate, emergency contacts) to a collapsible top header bar in the chat screen.
- **Media & Receipt Attachments**:
  - Photo sharing for receipts, boarding passes, and memories with offline thumbnail caching.

#### C. 🤖 Smart Travel Assistant & Bot Integrations ("Tara Bot / Auto-Summary")
- **Automated Trip Event Summaries**:
  - System messages posted when major actions occur: *"📌 Juan added 'Snorkeling at Coral Garden' to Day 2"* or *"💰 Maria logged ₱3,500 for Van Rental"*.
- **Daily Morning Briefing**:
  - Automated morning recap posted at 7:00 AM: *"☀️ Day 2 starts at 9:00 AM. 3 stops scheduled. Weather: 29°C sunny."*
- **Poll Reminder Bot**:
  - Friendly ping when votes are pending before a deadline: *"⏰ 2 members haven't voted on Dinner spot yet"*.

#### D. 🔒 Offline Queue & Security
- **Local-First Optimistic Dispatch**: Messages and votes queue into local database (`Sembast`/`Isar`) when offline in remote island/mountain areas, automatically syncing with exponential backoff when connectivity returns.
- **End-to-End Privacy & Name Invariant**: Format names through `MemberModel.formatDisplayName(hideSurname: true)` across sender headers, voter lists, and reaction chips.

---

### 3. Messaging Technology Stack Evaluation & Recommendation

#### 🏆 Recommended Architecture: **Supabase Realtime (Dual Hybrid Engine)**
Rather than introducing external third-party chat SaaS (e.g. Stream Chat, Sendbird) with disjointed authentication and high scaling fees ($499+/mo), Tara Travel leverages its existing native **Supabase infrastructure**:

1. **Persistent Messages & Poll Records (`Postgres Table Listeners`)**:
   - `supabase.from('trip_messages').stream(primaryKey: ['id']).eq('trip_id', tripId)`: Real-time synchronization for persistent chat history, media uploads, and poll vote records.
   - **Zero Vendor Overhead**: Direct integration with existing Postgres tables, RLS security helpers (`public.is_trip_member(trip_id)`), and Supabase Storage for media/receipts.
2. **High-Frequency Ephemeral Data (`Realtime Broadcast & Presence Channels`)**:
   - `supabase.channel('trip_room_$tripId')`: Ephemeral WebSockets for typing indicators (*"Maria is typing..."*), live reactions, and temporary GPS breadcrumbs.
   - **Zero Database Disk I/O**: Keeps high-frequency pings in memory without bloating Postgres write operations.
3. **Local-First Caching & Offline Dispatch**:
   - Outbox pattern stored in partitioned local store (`DatabaseService`), optimistically rendering messages and dispatching upon network reconnection.

---

### 4. Architecture & Data Model

```
┌──────────────────────────────────────────────────────────┐
│                   trip_messages Table                     │
│  - id, trip_id, sender_id, message_type (text/poll/card) │
│  - content, metadata (JSONB), created_at, pinned         │
└────────────────────────────┬─────────────────────────────┘
                             │
     ┌───────────────────────┴───────────────────────┐
     ▼                                               ▼
┌───────────────────────────┐         ┌───────────────────────────┐
│     trip_polls Table      │         │     trip_poll_votes       │
│ - id, trip_id, question   │         │ - id, poll_id, user_id    │
│ - options (JSONB), status │         │ - option_index, voted_at  │
│ - closes_at, winner_action│         └───────────────────────────┘
└───────────────────────────┘
```

---

### 5. Implementation Steps
1. [ ] **Database & Migrations**: Create `trip_messages`, `trip_polls`, and `trip_poll_votes` tables with strict RLS policies bound by `public.is_trip_member(trip_id)`.
2. [ ] **Supabase Realtime Subscriptions**: Configure dual hybrid channels (Postgres stream for persistent history + Broadcast for ephemeral typing/reactions).
3. [ ] **Realtime Poll Component**: Build `PollCard` widget with real-time voting progress, avatar chips on options, and winner resolution.
4. [ ] **Rich Message Embeds**: Support embedded itinerary stops, expense splits, and media attachments inside `ChatScreen`.
5. [ ] **Pinned Header Bar**: Add collapsible pinned message drawer at the top of the chat view.
6. [ ] **Optimistic Offline Dispatch**: Implement local outbox queueing for chat messages and votes when traveling without signal.

---

## 💡 IDEA-005: Tara Laravel Middleware & SuperAdmin Dashboard (Universal Links, CMS & Ops)

### 1. Context & Motivation
As Tara Travel scales, two critical architectural requirements emerge:
1. **Dynamic Web Middleware & Universal Deep Linking**: Seamless web-to-app conversion for shareable URLs (e.g. `https://tara-travel.app/join/{invite_code}`, `https://tara-travel.app/friend/{user_code}`, `https://tara-travel.app/trip/{trip_id}`). When clicked in a web browser, SMS, or social chat, the URL renders dynamic OpenGraph previews, checks for app installation, and redirects automatically into the Flutter app via Android App Links / iOS Universal Links (or fallback to Play Store).
2. **Operations & Content SuperAdmin Hub**: An admin suite for team members to curate trip templates, handle user support tickets, trigger app-wide alerts, update remote config (currencies, split taxonomies), and moderate user accounts without mobile app updates.

---

### 2. Recommended Tech Stack & Free Deployment Hosting

| Component | Technology | Rationale |
| :--- | :--- | :--- |
| **Backend & Middleware** | **Laravel 11 (PHP 8.3)** | Rapid REST API creation, robust routing, built-in queue/jobs, and native support for deep link fallback web pages. |
| **Admin Panel Engine** | **Filament PHP v3** (or Laravel Livewire/Blade) | Lightning-fast, customizable admin dashboard with TALL stack (Tailwind, Alpine.js, Laravel, Livewire) requiring zero frontend boilerplate. |
| **Database Connection** | **Supabase Postgres (Direct / REST)** | Laravel connects directly to the Supabase PostgreSQL database or uses Supabase Service Role Key for administrative actions, keeping a single source of truth. |
| **Free Hosting Tier** | **Render / Fly.io / Railway** + **Cloudflare Free CDN** | - **Fly.io** (Free tier 3x shared-cpu VMs) or **Render** (Free Web Service + Auto SSL).<br>- **Cloudflare**: Free SSL, CDN caching, DDoS mitigation, and custom domain routing. |

---

### 3. Core Operational & Middleware Modules

#### A. 🔗 Universal Deep Linking & Social Preview Engine (Web-to-App Gateway)
- **Clickable Links for Group Invites & Friendship**:
  - `https://tara-travel.app/join/{code}`:
    - *Mobile Browser*: Detects device OS → Redirects to `tara://trip/join?code=...` or Android App Link. If app is not installed, opens Google Play Store with deferred referral code.
    - *Desktop Browser*: Renders a high-res, branded landing page showing Trip Title, Dates, Host Avatar, and a QR Code to scan with the Tara Travel mobile app.
  - `https://tara-travel.app/friend/{user_code}`: Direct friend request link with dynamic user avatar preview.
  - `https://tara-travel.app/trip/{trip_id}`: Read-only public itinerary share page with interactive map preview.
- **Dynamic OpenGraph Meta Tags**:
  - Automatically generates dynamic social preview cards (Rich WhatsApp, Messenger, Twitter/X cards) with cover photos, destination name, and trip dates.
- **Digital Asset Links (`assetlinks.json`) & Apple App Site Association (`apple-app-site-association`)**:
  - Hosted directly on the Laravel root domain for seamless OS-level verification.

#### B. 🛠️ Templated Trips & Curated Itinerary CMS (Filament v3)
- **Visual Trip Template Builder**:
  - Create, edit, and publish featured travel packages (e.g. *"4D3N Coron Island Adventure"*, *"3D2N Baguio Heritage & Food Trail"*).
  - Configure default stops, suggested budgets, packing checklists, and local travel advisories.
- **Dynamic Discovery & Hero Banners**:
  - Manage featured itineraries, seasonal banners, and spotlight destinations shown on the mobile app's home discovery feed.

#### C. 🎫 User Support, Feedback & Concern Helpdesk
- **Incident & Feedback Ticket Viewer**:
  - View and triage user-submitted bug reports, dispute flags, and travel concerns with sanitized diagnostic telemetry (App version, OS, trip UUID).
- **Direct Support Response & Broadcast Push Alerts**:
  - Resolve tickets and send in-app notification responses to travelers.
  - Dispatch system-wide travel advisories (e.g. *"⚠️ Boracay ferry services suspended due to gale warning"*).

#### D. ⚙️ Dynamic Remote Config Engine
- **No-App-Store-Release Updates**:
  - Live currency exchange rates (USD/PHP conversion), default split methods, and feature flags.
  - Dynamic category taxonomies (e.g., adding new stop types or expense categories on the fly).

#### E. 🛡️ User Moderation & Group Governance
- **Account & Community Moderation**:
  - Audit flagged group trips, inappropriate chat content, or abusive reports.
  - Freeze or ban abusive accounts, or force-revoke compromised trip invite codes.
- **Role-Based Access Control (RBAC)**:
  - Multi-tier admin accounts (`SuperAdmin`, `SupportAgent`, `ContentCurator`) with full immutable audit logging.

---

### 4. Architecture Diagram

```
       ┌───────────────────────────────────────────────────────────┐
       │   Social Chats (WhatsApp, Messenger, SMS) / Web Browsers  │
       └─────────────────────────────┬─────────────────────────────┘
                                     │ (Clickable HTTPS Link)
                                     ▼
       ┌───────────────────────────────────────────────────────────┐
       │               Laravel 11 Middleware Gateway               │
       │   (Hosted on Fly.io / Render with Cloudflare Edge CDN)    │
       ├───────────────────────────────────────────────────────────┤
       │  • Universal Deep Link Resolver (App Link / Fallback Web) │
       │  • Dynamic OpenGraph Social Image Generator               │
       │  • Filament v3 SuperAdmin Panel (CMS, Tickets, Config)    │
       └─────────────────────────────┬─────────────────────────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         │ (Admin DB Connection)     │ (REST / Realtime)         │ (App Links)
         ▼                           ▼                           ▼
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│ Supabase Postgres│       │ Firebase / FCM   │       │ Tara Mobile App  │
│ (Single Source)  │       │ (Push Alerts)    │       │ (Flutter Client) │
└──────────────────┘       └──────────────────┘       └──────────────────┘
```

---

### 5. Implementation Steps
1. [ ] **Laravel + Filament Setup**: Initialize Laravel 11 project with Filament PHP v3 admin panel and Supabase PostgreSQL connection.
2. [ ] **Deep Link Gateway & `.well-known` Routing**: Build universal link routes (`/join/{code}`, `/friend/{code}`, `/trip/{id}`) with OpenGraph meta tags and `assetlinks.json`.
3. [ ] **Template CMS Resource**: Create Filament resources for managing `trip_templates`, `stop_templates`, and seasonal banners.
4. [ ] **Helpdesk & Ticket Management**: Implement user feedback triage table with response dispatching to mobile notifications.
5. [ ] **Remote Config API**: Expose cached JSON endpoints (`/api/v1/config`, `/api/v1/templates`) with Cloudflare edge caching.
6. [ ] **Deployment Manifests**: Configure Dockerfile and deployment scripts for zero-cost hosting on **Fly.io** or **Render** with Cloudflare DNS/SSL.

---

## 💡 IDEA-006: Cloud-Native Avatar Storage & CDN Cache Architecture (Supabase Storage + PostgreSQL)

### 1. Problem Statement & Motivation
Currently:
- When a user picks a photo from the gallery or camera in [profile_screen.dart](file:///d:/Spencer/Downloads/tara_travel/lib/features/profile/profile_screen.dart#L2080-L2094), the local file path (e.g. `/data/user/0/.../image_picker_xxx.jpg`) is saved into the local state.
- **Flaws**:
  1. **Device Isolation**: Other trip members or friends cannot see the user's avatar (`NetworkImage` fails or falls back to initials).
  2. **Storage Bloat & Loss**: If the app clears its cache or the user logs in from a different device, the local path becomes invalid.
  3. **Performance Degradation**: Large uncompressed raw camera images ($5\text{MB}+$) consume excessive device memory and bandwidth.

### 2. Architectural Solution Overview
Adopt a **Cloud-Native Avatar Pipeline** that pairs **Client-Side Compression** + **Supabase Storage Bucket (`avatars`)** + **PostgreSQL Public URL Persistence** + **Cached Network Fallback**.

```
┌─────────────────┐       ┌─────────────────┐       ┌──────────────────────┐       ┌────────────────────────┐
│ Image Picker /  │ ----> │ Client-Side     │ ----> │ Supabase Storage     │ ----> │ PostgreSQL public.users│
│ Camera (XFile)  │       │ WebP/JPEG Comp. │       │ Bucket ('avatars')   │       │ avatar_url = CDN URL   │
└─────────────────┘       └─────────────────┘       └──────────────────────┘       └────────────────────────┘
                                                                                                │
                                                                                                ▼
                                                                                   ┌────────────────────────┐
                                                                                   │ Tara Universal UI      │
                                                                                   │ (CachedNetworkImage)   │
                                                                                   └────────────────────────┘
```

---

### 3. Detailed Technical Architecture

#### A. Supabase Storage Infrastructure & RLS Policies
1. **Dedicated Public Bucket**: `avatars`
2. **Object Path Convention**:
   - `avatars/{user_id}/avatar_{timestamp}.webp` or `avatars/{user_id}/avatar.webp` (upsert = `true` to replace existing).
3. **Storage RLS Security Policy**:
   ```sql
   -- Allow public read access to avatar images
   create policy "Public Avatar Read Access"
     on storage.objects for select
     using (bucket_id = 'avatars');

   -- Allow authenticated users to upload and overwrite ONLY their own avatar folder
   create policy "User Avatar Write Access"
     on storage.objects for insert to authenticated
     with check (
       bucket_id = 'avatars' 
       and (storage.foldername(name))[1] = auth.uid()::text
     );

   create policy "User Avatar Update Access"
     on storage.objects for update to authenticated
     using (
       bucket_id = 'avatars' 
       and (storage.foldername(name))[1] = auth.uid()::text
     );

   create policy "User Avatar Delete Access"
     on storage.objects for delete to authenticated
     using (
       bucket_id = 'avatars' 
       and (storage.foldername(name))[1] = auth.uid()::text
     );
   ```

#### B. Client-Side Image Optimization Pipeline
- **Resize & Compress**:
  - Max dimensions: $512 \times 512\text{px}$ (square avatar crop).
  - Target file size: $\le 60\text{KB}$ with WebP / JPEG 85% quality.
- **Eliminate Local Storage Bloat**:
  - Remove raw picked image temp files from app sandbox cache once uploaded.

#### C. Database Synchronization & Reactive State
1. **Upload File to Supabase Storage**:
   ```dart
   final fileBytes = await compressedFile.readAsBytes();
   final path = '${user.id}/avatar.webp';
   await supabase.storage.from('avatars').uploadBinary(
     path,
     fileBytes,
     fileOptions: const FileOptions(upsert: true, contentType: 'image/webp'),
   );
   final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
   // Append cache-buster timestamp query param to bypass stale CDN caches
   final freshUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
   ```
2. **Persist in `public.users` & `auth.users`**:
   - Update `public.users.avatar_url` via [profile_repository.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/repositories/profile_repository.dart).
   - Sync `auth.updateUser(UserAttributes(data: {'avatar_url': freshUrl}))`.
3. **Propagate via Riverpod**:
   - `ref.read(profileProvider.notifier).updatePhoto(freshUrl)`.
   - Automatically reflects in trip member lists, friend lists, and chat cards.

#### D. Unified UI Component (`AppAvatar`)
Create a single reusable widget [app_avatar.dart](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/app_avatar.dart) handling:
- **HTTP / CDN URLs**: Loaded via `CachedNetworkImage` with memory cache and disk cache limits.
- **Initial Fallbacks**: Renders stylized Initials with deterministic brand color when `avatar_url` is null/empty or network fails.
- **Offline Mode**: Uses local memory cache before falling back to initials.

---

### 4. Implementation Steps
1. [ ] **Supabase Storage Migration**: Create `021_storage_avatars_bucket.sql` creating the `avatars` bucket and strict RLS owner policies.
2. [ ] **Storage Upload Service**: Create `StorageService` or add `uploadAvatar(File file, String userId)` to `ProfileRepository`.
3. [ ] **Client Compression**: Integrate image compression before upload to keep uploads $< 60\text{KB}$.
4. [ ] **Profile Screen Integration**: Update `_pickAndSavePhoto()` in `profile_screen.dart` and `onboarding_screen.dart` to upload to cloud storage before saving.
5. [ ] **Unified `AppAvatar` Component**: Refactor `profile_screen.dart`, `friend_list_item.dart`, and `details_step.dart` to use unified `AppAvatar` with `CachedNetworkImage`.

---

## 🤖 IDEA-006: In-App AI Travel Assistant & Copilot ("Tara AI")

### 1. Context & Motivation
Group travelers and solo adventurers often face logistical overhead during trip execution: budgeting questions ("How much have we spent on food?"), itinerary optimization ("What should we visit next between 2 PM and 5 PM near BGC?"), packing advice ("What essentials do I need for Sagada spelunking?"), and local cultural / transit tips.

Integrating **Tara AI** provides an intelligent, context-aware companion inside the app that understands the user's active trip state (itinerary stops, budget, expenses, packing items, companions, weather) and can execute automated assistant actions (e.g., adding stops, generating packing lists, summarizing expenses).

---

### 2. Core Feature Specifications & Best Practice Proposals

#### A. 🧠 Context-Aware Trip Copilot Engine
- **In-Memory Trip Injection**:
  - The AI assistant is automatically grounded with the active trip context:
    - Destination & Dates
    - Group size & companions
    - Current itinerary schedule and stops
    - Budget cap and categorized expenses logged so far
    - Weather forecast for the destination
- **Local Filipino & Regional Travel Intelligence**:
  - Built-in prompt awareness of local Philippine transit (jeepney routes, tricycles, RORO ferries, tollways), local customs, tipping norms, peak seasons, and emergency hotlines (PNP, Coast Guard, NDRRMC).

#### B. 💬 Chat UI & Conversational Capabilities
- **Access Points**:
  - Global Floating Action Pill / FAB on Home Screen and Trip Detail Screen.
  - Dedicated "Tara AI" tab or drawer sheet with full-screen conversation view.
  - **"Create Trip with Tara AI"** prompt card in the Trip Creation / Home Screen flow.
- **Quick Action Starter Chips**:
  - *"🏖️ Plan a 3-day weekend trip to Siargao for 4 people under ₱25k"*
  - *"✨ Suggest day 2 afternoon activities"*
  - *"📊 Summarize our current spending vs budget"*
  - *"🎒 What packing items are we missing?"*
  - *"🌧️ What's an indoor backup plan if it rains?"*
- **Streaming Response & Markdown Rendering**:
  - Token-by-token streaming response with rich markdown formatting (bolding, bullet points, budget tables).
- **Haptic & Visual Feedback**:
  - Subtle typing indicators and brand-themed bubble avatars (`#D85A30` coral accents).

#### C. ⚡ Interactive Tool Calling & Autonomous Actions
Tara AI can output structured function-call intents that the Flutter client parses to directly execute app actions:
1. **`create_trip_proposal` (AI Full-Trip Generator)**:
   - User types: *"Plan a 4-day food and beach trip to Cebu for 3 friends next month, budget ₱30k total"*.
   - Tara AI outputs a complete trip proposal:
     - Title, Destination, Trip Type (`Beach`, `Food`, `Adventure`, etc.), Estimated Dates, and Budget.
     - Day-by-day Itinerary breakdown with suggested stops (name, time, location, estimated cost).
     - Recommended starter packing items.
   - User reviews the generated proposal card with a single tap: **"🚀 Create & Launch This Trip"** $\rightarrow$ writes to `trips`, batches `itinerary_stops`, and populates `packing_items` via `TripRepository`.
2. **`add_itinerary_stop`**:
   - Suggests a spot $\rightarrow$ User taps **"Add to Itinerary"** button $\rightarrow$ automatically opens pre-filled stop modal with name, time, estimated cost, and notes.
3. **`add_packing_items`**:
   - Generates tailored checklist items $\rightarrow$ User taps **"Add all to Packing List"** $\rightarrow$ bulk-inserts into `packing_items`.
4. **`calculate_split_summary`**:
   - Computes multi-person debt settlements on the fly based on current `expenses` table data.

#### D. 🔒 Security, Privacy & API Key Governance
- **Zero Client-Side API Key Exposure**:
  - Calls routed via Supabase Edge Function (`supabase/functions/tara-copilot`) or secure backend proxy.
  - Client sends JWT auth token + context JSON payload.
- **Privacy Enforcement**:
  - User names masked to display format (`Juan D.`).
  - Sensitive personal data stripped before forwarding to LLM endpoints.
- **Offline / Rate-Limit Fallback**:
  - Graceful fallback with offline pre-cached travel tips and rule-based canned responses when network is unavailable.

---

### 3. Architecture & State Management

```
┌────────────────────────────────────────────────────────┐
│                   Tara AI Chat Screen                  │
│              (lib/features/ai_assistant/)              │
└───────────────────────────┬────────────────────────────┘
                            │ (Riverpod State)
                            ▼
┌────────────────────────────────────────────────────────┐
│              AiAssistantNotifier / State               │
│          (Chat History, Stream State, Actions)         │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────────┐   ┌────────────────────────┐
│   TripContextSerializer   │   │  AiAssistantRepository │
│  (Stops, Budget, Packing) │   │ (Supabase Edge / API)  │
└───────────────────────────┘   └───────────┬────────────┘
                                            │ (POST /stream)
                                            ▼
                                ┌────────────────────────┐
                                │  Supabase Edge Func    │
                                │    `tara-copilot`      │
                                └────────────────────────┘
```

---

### 4. Implementation Steps
1. [ ] **Domain & State Design**: Create `AiMessage` model with support for roles (`user`, `assistant`, `system`), tool call actions (`create_trip`, `add_stop`, `add_packing`), and timestamping in `lib/features/ai_assistant/models/`.
2. [ ] **AI Trip Proposal Generator**: Design structured schema & parser for full trip creation payloads (`title`, `dates`, `budget`, `trip_type`, `itinerary_stops`, `packing_items`).
3. [ ] **Context Serializer**: Create `TripContextSerializer` in `lib/features/ai_assistant/services/` to extract and compact active trip data into structured LLM system prompts.
4. [ ] **Repository & Edge Function Service**: Create `AiAssistantRepository` implementing secure streaming inference (Gemini / OpenAI API via Supabase Edge Function).
5. [ ] **Riverpod State Management**: Build `aiAssistantProvider` (`AiAssistantState` / `AiAssistantNotifier`) handling message history, streaming tokens, error states, and tool execution callbacks.
6. [ ] **Interactive Chat Screen & Trip Preview Card**: Implement `TaraAiChatScreen`, `AiTripProposalCard`, and `AiActionCard` components with starter prompts, markdown parsing, and one-tap creation actions (**"🚀 Create & Launch This Trip"**, **"Add Stop"**, **"Add Packing Items"**).

---

## 📍 IDEA-007: Ultra-Simplified Itinerary Stop Cards & Unified "Mark as Arrived" Presence Hub

### 1. Context & Motivation
Currently, each `StopCard` on the Itinerary screen contains multiple competing action buttons (Check-In button, Roll Call button with counters, expense trigger, and navigation actions). This creates visual clutter and information overload on the main itinerary feed. Furthermore, "Check In" and "Roll Call" are conceptually redundant since both manipulate the exact same arrival state (`checkedInMemberIds`, `visitedAt`, `status`).

To achieve clean visual hierarchy and an effortless user experience:
1. **Stop Card Simplification**: Strip the `StopCard` down to its essential information (time, title, category/location, cost, and a clean arrival badge) with **only one single primary CTA**: **"🗺️ Map" / "🧭 Navigate"**.
2. **Move Actions Inside `StopDetailSheet`**: Tapping any stop opens the comprehensive detail sheet, where the user can access secondary actions (Log Expense, Edit/Delete Stop, and Group Arrival Management).
3. **Unified Presence & Member Arrival Roster in Detail Sheet**: Completely retire "Roll Call" in favor of **"Mark as Arrived"**. Inside the detail sheet, show a clear live breakdown of **"Companions Arrived"** vs. **"Not Yet Arrived"** with 1-tap toggles.

---

### 2. Core Feature Specifications & Best Practice Proposals

#### A. 🎴 Ultra-Clean `StopCard` Design (Single CTA)
- **Visual Hierarchy**:
  - **Left**: Time slot & stop category icon.
  - **Center**: Stop title, location subtitle, budget/cost chip, and a subtle status indicator (e.g. green check pill `✓ Arrived` if visited).
  - **Right / Primary CTA**: A single, prominent action button:
    - **`[ 🧭 Navigate ]` / `[ 🗺️ Map ]`**: Instantly launches Google Maps/Apple Maps or in-app route preview.
  - **Removed from Card Surface**: All multi-button rows (Check-In button, Roll Call button, and Expense shortcut) are removed from the card face, keeping the feed minimal and readable.
- **Card Tap Interaction**: Tapping anywhere on the card body opens the `StopDetailSheet`.

#### B. 👥 "Members" Arrival Button & Interactive Avatar Roster in `StopDetailSheet`
- **Top-Right Edit & Action Header**:
  - The **`[ ✏️ Edit ]`** button (and overflow/delete menu) is placed prominently in the **top-right corner** of the sheet header, keeping administrative actions cleanly separated from the primary travel flow.
- **Canonical "Mark as Arrived" Hero Action**:
  - Prominent 1-tap button for the current user:
    - Default state: `[ 📍 Mark as Arrived ]` (Coral brand button)
    - Arrived state: `[ ✓ You Arrived at 2:30 PM ]` (Soft green surface, tap to undo)
- **Dedicated "Members" Arrival Trigger & Avatar Preview**:
  - In `StopDetailSheet`, for group trips, a sleek **"Members (3/5 Arrived)"** card/button:
    - Displays an **overlapping avatar stack** of arrived companions + badge of total arrived (`✓ 3/5`).
    - Tapping this button expands or reveals the **Companion Arrival List**:
      1. **Arrived Companions (`✓`)**:
         - Member avatar with green arrival ring, formatted name (`Juan D.`), and timestamp (`Arrived 2:15 PM`).
         - 1-tap undo option.
      2. **Not Yet Arrived (`⏳`)**:
         - Muted member avatar, formatted name, and direct `[ + Mark Arrived ]` button.
      3. **Batch Shortcut**: `"Mark Everyone as Arrived"` button for group organizers.

#### C. 🚀 Geofence & GPS `ArrivalPill` Harmony
- The automated background GPS geofence retains its high-utility popup:
  - When within 150m of a stop, the floating `ArrivalPill` appears with swipe-to-check-in.
  - Tapping the pill body opens the `StopDetailSheet` directly with the arrival roster ready.

---

### 3. Architecture & Interaction Flow

```
┌────────────────────────────────────────────────────────┐
│                   Itinerary Stop Card                  │
│   [Time] [Title & Location]        [🧭 Navigate (Only)]│
└───────────────────────────┬────────────────────────────┘
                            │ (Tap card body)
                            ▼
┌────────────────────────────────────────────────────────┐
│                    StopDetailSheet                     │
├────────────────────────────────────────────────────────┤
│  [Drag Handle]                          [✏️ Edit] [✕]  │
│  • Stop Title & Photo Gallery                          │
│                                                        │
│  • [ 📍 Mark as Arrived (You) ] (Primary Hero CTA)     │
│                                                        │
│  • [ 👥 Members (3/5 Arrived)  [Avatars Stack]  ▼ ]   │
│    └─► Expands / Opens Member Arrival Roster:          │
│        ✓ Maria S. (Arrived 2:15 PM)                    │
│        ✓ Juan D.  (Arrived 2:20 PM)                    │
│        ⏳ Carlos T.               [+ Mark Arrived]      │
│                                                        │
│  • [ 💵 Log Expense ]                                  │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│             ItineraryNotifier / Repository             │
│        Updates `checkedInMemberIds` & `status`         │
└────────────────────────────────────────────────────────┘
```

---

### 4. Implementation Steps
1. [x] **`StopCard` Simplification**: Remove `_CheckInButton` and `_RollCallPillButton` from `stop_card.dart`. Ensure the sole visible CTA is `[ 🧭 Navigate ]` / `[ 🗺️ Map ]`.
2. [x] **Top-Right Edit Placement**: Position the `[ ✏️ Edit ]` button on the top-right header of `StopDetailSheet` alongside the close/dismiss action.
3. [x] **Retire "Roll Call" Terminology**: Replace all occurrences of "Roll Call" in code, labels, tooltips, and action sheets with "Mark as Arrived" / "Members".
4. [x] **Detail Sheet "Members" Button & Avatar Roster**: In `StopDetailSheet` (`lib/features/itinerary/widgets/stop_detail_sheet.dart`):
   - Add primary `Mark as Arrived` button for self-check-in.
   - Add a dedicated `[ 👥 Members (3/5 Arrived) ]` button with avatar stack that opens/expands the companion arrival roster.
   - Display member avatars with status badges (`Arrived` vs `Not Arrived`) and direct check-in toggles.
   - Include batch `"Mark All as Arrived"` button for organizers.
5. [x] **Deprecate Separate `RollCallSheet`**: Merge its presence logic and member lists directly into the `StopDetailSheet` "Members" component.
6. [x] **Arrival Pill & Notification Sync**: Ensure `ArrivalPill` swipe-to-check-in seamlessly updates the same state and links to the newly structured detail sheet.







