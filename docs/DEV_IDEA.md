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
7. [x] **Driver-Ready Slide to Confirm Arrival**: Implemented `SlideToArriveButton` and per-member arrival timestamps in `StopDetailSheet` (`IMP-070`).

> **Status**: Completed (`IMP-069`, `IMP-070`)

---

## ✅ IDEA-008: Relocating Live Nav to Itinerary Floating Dock & Driver-Optimized Navigation HUD [COMPLETED]

### 1. Context & Motivation
- **Home Screen Clutter**: Displaying "Live Nav" across multiple home cards (`NextTripCard` header and `TripCard` action rows) cluttered primary trip exploration and squeezed other high-frequency actions (`Itinerary`, `Packing`, `Members`, `Expenses`, `Chat`).
- **Traveling & Driving Context**: When users are actively traveling or driving, they are in the **Itinerary** screen managing their day schedule and waypoints. Having the primary Live Navigation trigger directly docked on the Itinerary floating action bar gives drivers 1-tap access to live telemetry, convoy radar, and turn-by-turn routing without navigating back and forth to the home screen.

### 2. Core Architectural & UX Redesign

#### A. Clean Home Experience
- Removed small `Live Nav` pill from the top header row of `NextTripCard`.
- Removed `Live Nav` from `TripCard` bottom action rows, giving ample breathing room to `Itinerary`, `Packing`, `Members`, `Expenses`, and `Chat`.

#### B. Tri-Action Itinerary Floating Dock (`ItineraryBottomDock`)
- Docked at the bottom of the Itinerary view:
  1. **`[ 🧭 Live Nav ]` (Primary Hero Action)**: 1-tap instant entry into live telemetry, real-time GPS broadcast, and convoy radar.
  2. **`[ 🗺️ Day Map ]`**: Opens interactive route overview and companion pins sheet.
  3. **`[ ＋ Stop ]`**: Fast modal entry for adding itinerary stops.

#### C. Driver-Optimized Navigation HUD
- High-contrast, large-font turn guidance card in `LiveMapTab`.
- **1-Tap Google Maps Integration**: Direct button on the turn card launching native turn-by-turn external navigation (`google.navigation:q=lat,lng`) with seamless web fallback.
- Large-touch target `[ Exit Nav ]` button for easy operation while vehicle is parked or en-route.

### 3. Implementation Steps
1. [x] **Home Card Decluttering**: Removed `Live Nav` CTA from `next_trip_card.dart` and `trip_card.dart`.
2. [x] **Itinerary Dock Redesign**: Integrated prominent `Live Nav` gradient button into `itinerary_bottom_dock.dart`.
3. [x] **Turn-by-Turn External Handoff**: Added 1-tap Google Maps Navigation launch to `_TurnCard` in `live_map_tab.dart`.
4. [x] **Compilation Verification**: Confirmed clean build via `dart analyze lib/`.

> **Status**: Completed (`IMP-071`)

---

## 💡 IDEA-009: Travel Circles (Squads & Barkada Presets) for Instant Multi-Member Trip Creation [PROPOSED]

### 1. Context & Motivation
- **Manual Selection Overhead**: In the current trip creation workflow (`details_step.dart`), adding multiple co-travelers requires manually searching, scrolling, and checking each friend one-by-one (`1-by-1` tap). For recurring travel groups (e.g., *College Barkada*, *Immediate Family*, *Workmates*, *Weekend Hiking Club*), this is repetitive and prone to missing members.
- **Group Cohesion & Role Continuity**: Travelers frequently travel with the same sub-groups and assign consistent responsibilities (e.g., default treasurer, convoy driver). Having saved Circles enables 1-tap roster insertion and auto-population of split profiles during trip setup.

---

### 2. Core Proposal
Introduce **Travel Circles** (or *Travel Squads* / *Barkada Circles*): user-defined and smart-computed cohorts of accepted friends that can be bulk-added to any new trip with a single tap.

```
┌─────────────────────────────────────────────────────────────┐
│                      SELECT TRAVELERS                       │
├─────────────────────────────────────────────────────────────┤
│  [🔍 Search friends or squads...                          ] │
│                                                             │
│  QUICK SQUADS / CIRCLES                                     │
│  ┌──────────────────────┐  ┌──────────────────────────────┐ │
│  │ 🔥 College Barkada   │  │ 🏖️ Boracay Crew (Recent)    │ │
│  │ 👥 6 Members · [ADD] │  │ 👥 4 Members · [ADD]         │ │
│  └──────────────────────┘  └──────────────────────────────┘ │
│                                                             │
│  💡 Smart Suggestions                                       │
│  [✨ Re-invite from "Palawan 2025" (5 friends)]             │
│  [⭐ Frequent Co-Travelers (Top 4)]                         │
│                                                             │
│  INDIVIDUAL FRIENDS (A-Z)                                   │
│  ☑ Juan D. (In College Barkada)                             │
│  ☐ Maria S.                                                 │
└─────────────────────────────────────────────────────────────┘
```

---

### 3. Recommended Architectural & UX Design

#### A. Key Functional Capabilities
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

---

#### B. Supabase Database Schema

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

-- Indices for high-frequency queries
CREATE INDEX idx_friend_circles_owner ON public.friend_circles(owner_id);
CREATE INDEX idx_friend_circle_members_circle ON public.friend_circle_members(circle_id);
CREATE INDEX idx_friend_circle_members_user ON public.friend_circle_members(friend_user_id);

-- RLS Policies
ALTER TABLE public.friend_circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_circle_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own circles"
ON public.friend_circles FOR ALL
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users manage circle members"
ON public.friend_circle_members FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.friend_circles fc
        WHERE fc.id = friend_circle_members.circle_id
          AND fc.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.friend_circles fc
        WHERE fc.id = friend_circle_members.circle_id
          AND fc.owner_id = auth.uid()
    )
);
```

---

#### C. Riverpod State & Architecture Flow

```
┌──────────────────────────────────────────────────────────┐
│                      FriendRepository                    │
│  - getCircles() -> List<FriendCircleModel>               │
│  - createCircle(name, emoji, memberUserIds)              │
│  - getFrequentCoTravelers() -> List<FriendModel>         │
└────────────────────────────┬─────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│                   friendCirclesProvider                  │
│       AsyncNotifierProvider<List<FriendCircleModel>>     │
└────────────────────────────┬─────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│          DetailsStep / SelectFriendsBottomSheet          │
│  • Circle Carousel Pill Row                              │
│  • Bulk toggle: trip.travelers.addAll(circle.members)    │
│  • Badge Counter: "5/6 selected from Barkada"            │
└──────────────────────────────────────────────────────────┘
```

---

### 4. Implementation Steps
1. [ ] **Database Migration**: Create `friend_circles` and `friend_circle_members` tables with indices and RLS policies.
2. [ ] **Repository & Domain Models**: Implement `FriendCircleModel` and CRUD methods in `FriendRepository`.
3. [ ] **Riverpod Providers**: Create `friendCirclesProvider` and `frequentCoTravelersProvider`.
4. [ ] **Circle Management UI**: Build a "Circles" management tab / section in `FriendsScreen` to create, edit, and organize squads.
5. [ ] **Trip Creation Integration**: Update `_showSelectFriendsBottomSheet` in `DetailsStep` with:
   - Quick Circle selector carousel chips.
   - Batch `"Add Entire Circle"` action with check state.
   - Smart suggestions: *"Frequent Co-Travelers"* and *"Re-invite from [Trip]"*.
6. [ ] **Verification & Privacy Audit**: Verify zero duplicate traveler IDs in `NewTripModel` and validate `MemberModel.formatDisplayName` compliance.

> **Status**: Proposed

---

## 💡 IDEA-010: Trip Card Quick-Action Red Notification Dot Indicator for New or Changed Content [COMPLETED]

### 1. Context & Motivation
Currently on the Home Screen (`home_screen.dart` / `trip_card.dart`), the bottom row of the upcoming trip card exposes 5 quick action buttons:
- **Itinerary** (`onItinerary`)
- **Packing** (`onPacking`)
- **Members** (`onMembers`)
- **Expenses** (`onExpenses`)
- **Chat** (`onChat`)

While these buttons provide 1-tap navigation into their respective modules, they are currently static icons without contextual change awareness. Users cannot glance at their trip card to immediately know if there is unread activity, newly added content, or updates made by co-travelers inside any module since they last checked.

---

### 2. Core Proposal
Enhance the Quick Action buttons in `TripCard` with a lightweight, contextual **Red Notification Dot Indicator (`🔴` / `AppColors.red`)**:
- **Trigger**: Display the red dot exclusively when there is **new or modified content** inside that specific module since the user's last view/read timestamp.
- **Modules & Change Triggers**:
  - **Itinerary (`onItinerary`)**: New stops added, modified stop times/details, or schedule revisions.
  - **Packing (`onPacking`)**: New items added or checklist items updated/assigned by co-travelers.
  - **Members (`onMembers`)**: New member invites accepted or traveler list updates.
  - **Expenses (`onExpenses`)**: New expenses logged, pending approval requests, or receipt uploads.
  - **Chat (`onChat`)**: New unread messages in the trip group chat.
- **Auto-Dismissal**: Tapping the action button (or viewing the respective module) automatically updates the local `lastViewed` timestamp and clears the red dot.

```
┌────────────────────────────────────────────────────────────────────────┐
│  QUICK ACTION ROW WITH RED NOTIFICATION DOT CHANGE INDICATORS          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   ┌────────┐       ┌────────┐       ┌────────┐       ┌────────┐        │
│   │ 📅 [🔴]│      │ 🎒     │       │ 👥     │       │ 💬 [🔴]│        │
│   │        │       │        │       │        │       │        │        │
│   └────────┘       └────────┘       └────────┘       └────────┘        │
│   Itinerary         Packing          Members            Chat           │
│ (Updated stops)   (Up to date)     (Up to date)     (Unread messages)  │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 3. Recommended Architectural & UX Design

#### A. Data Model: `TripQuickActionChanges` (`lib/features/home/models/trip_card_badge_data.dart`)

```dart
class TripQuickActionChanges {
  final bool hasItineraryChanges;
  final bool hasPackingChanges;
  final bool hasMemberChanges;
  final bool hasExpenseChanges;
  final bool hasChatChanges;

  const TripQuickActionChanges({
    this.hasItineraryChanges = false,
    this.hasPackingChanges = false,
    this.hasMemberChanges = false,
    this.hasExpenseChanges = false,
    this.hasChatChanges = false,
  });

  bool get hasAnyChanges =>
      hasItineraryChanges ||
      hasPackingChanges ||
      hasMemberChanges ||
      hasExpenseChanges ||
      hasChatChanges;
}
```

---

#### B. Storage Key Scheme & Self-Action Exemption

1. **Storage Scheme (`ModuleViewTrackerService`)**:
   - Backed by Keystore-encrypted storage with in-memory sync cache.
   - Keys formatted as `last_viewed:{module}:{tripId}` (e.g. `last_viewed:itinerary:trip_123`).
   - Value: ISO-8601 UTC string timestamp recorded whenever the user navigates into that section or taps its quick action button.
2. **Self-Action Exemption**:
   - Changes/edits authored by the current logged-in user (`user_id == currentUserId` or `paid_by_user_id == currentUserId`) are filtered out so that users do not receive red dots for their own updates.
3. **Zero DB Migrations**:
   - Queries `updated_at` / `created_at` or unread message counters directly from existing Supabase tables (`itinerary_stops`, `packing_items`, `expenses`, `messages`, `trip_members`).

---

#### C. Component Layout & Visual Tokens

1. **Red Dot Positioning**:
   - Anchored to the top-right of the 44×44 action button container using `Stack` + `Positioned(top: 2, right: 2)`.
2. **Red Dot Specs**:
   - `9px` diameter circle, `AppColors.red` (`#EF4444`) with `1.5px` surface border (`Colors.white`) for crisp contrast against button background.
3. **Accessibility & Tap Targets**:
   - The dot is wrapped in `IgnorePointer` so the entire 44×44 tap target directly triggers existing callbacks (`onItinerary`, `onPacking`, etc.).

---

#### D. Riverpod State Providers

```
┌──────────────────────────────────────────────────────────┐
│              tripQuickActionChangesProvider(trip)        │
│          FutureProvider.family<TripQuickActionChanges>  │
└────────────────────────────┬─────────────────────────────┘
                             │
       ┌─────────────────────┼─────────────────────┐
       ▼                     ▼                     ▼
ItineraryLastModified   PackingLastModified   UnreadMessagesCount
 (vs lastViewedItinerary) (vs lastViewedPacking) (vs lastViewedChat)
```

---

### 4. Implementation Steps
1. [x] **Model Definition**: Create `TripQuickActionChanges` in `lib/features/home/models/trip_card_badge_data.dart`.
2. [x] **Widget Badge Rendering**: Update `_actionButton` in `trip_card.dart` to accept a boolean `hasNotificationDot` and render the top-right red dot when true.
3. [x] **Riverpod Provider**: Implement `tripQuickActionChangesProvider` comparing entity timestamps against local `last_viewed:{module}:{tripId}` storage with self-action exemption.
4. [x] **Home Screen Integration**: Connect `tripQuickActionChangesProvider` in `HomeScreen` and pass indicator flags to `TripCard.upcoming`.
5. [x] **On-Tap Dismissal**: Ensure tapping each quick action writes to `ModuleViewTrackerService` and invalidates `tripQuickActionChangesProvider`.

> **Status**: Completed

---

## 💡 IDEA-011: Interactive Clickable Notifications with Deep-Linking & Contextual Action Routing [PROPOSED]

### 1. Context & Pain Points
In `notifications_screen.dart`, tapping a notification card only marks it as read (`_markAsRead(originalIndex)`). It does not navigate the user anywhere.
- **Problem**: When a user receives a notification about a new trip expense, an itinerary change, a chat message, a member RSVP, a live geofence proximity alert, or a weather advisory, tapping the card leaves the user on the notifications list without taking them to the relevant screen or context.
- **Goal**: Make every notification card **interactive and actionable**, deep-linking directly to the relevant trip screen, sub-tab, or modal sheet.

---

### 2. Core Proposal: Contextual Notification Routing Engine
1. **Target Entity Metadata in Notifications**:
   - Add optional contextual keys to the notification payload / schema: `trip_id`, `target_screen` (e.g. `'expenses'`, `'itinerary'`, `'chat'`, `'packing'`, `'members'`), and `target_item_id` (e.g. specific `expense_id`, `stop_id`, `message_id`).
2. **Interactive Tap Handlers & Visual Affordance**:
   - Mark as read instantly on tap.
   - Smoothly navigate to the relevant destination using `Navigator.push` or Riverpod routing.
   - Display a subtle chevron (`Icons.chevron_right_rounded`) or quick-action chip (*"View Expense"*, *"Open Chat"*, *"Check Itinerary"*) to clearly communicate clickability.
3. **Category-Specific Action Routing Table**:

| Category | Typical Notification | On-Tap Destination / Action |
| :--- | :--- | :--- |
| **`expense` / `payment`** | *"Juan added ₱1,500 for Seafood Dinner"* | Open `TripDetailScreen` $\rightarrow$ Expenses Tab (or directly pop up `ExpenseDetailModal`) |
| **`message` / `chat`** | *"Maria: We're heading to the pier now"* | Open `TripDetailScreen` $\rightarrow$ Group Chat (`ChatScreen`) |
| **`itinerary` / `proximity`**| *"Arrival: You're near White Beach Station 1"* | Open `ItineraryScreen` focused on the current day & stop |
| **`packing`** | *"Don't forget to pack your snorkel gear"* | Open `PackingScreen` with highlight on unpacked category |
| **`friend` / `member`** | *"Carlo accepted your trip invite"* | Open `TripDetailScreen` $\rightarrow$ Members Tab |
| **`profile`** | *"Complete your profile setup"* | Open `ProfileScreen` / `EditProfileScreen` |

---

### 3. Recommended Architecture & Code Design

#### A. Updated Notification Model (`lib/features/notifications/models/notification_model.dart`)

```dart
class NotificationItem {
  final String id;
  final NotificationCategory category;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  // Deep-linking metadata
  final String? tripId;
  final String? targetScreen; // 'chat', 'expenses', 'itinerary', 'packing', 'members', 'profile'
  final String? targetItemId; // e.g. expenseId, stopId
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.tripId,
    this.targetScreen,
    this.targetItemId,
    this.metadata,
  });

  bool get isClickable => tripId != null || targetScreen != null;
}
```

---

#### B. Centralized Notification Router (`NotificationRouter.handleTap`)

```dart
class NotificationRouter {
  static void navigate(BuildContext context, WidgetRef ref, NotificationItem item) {
    if (item.targetScreen == 'profile') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }

    if (item.tripId != null) {
      // 1. Fetch trip and navigate to TripDetailScreen with initial tab index
      final targetTab = _resolveTabIndex(item.targetScreen, item.category);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripDetailScreen(
            tripId: item.tripId!,
            initialTabIndex: targetTab,
            highlightItemId: item.targetItemId,
          ),
        ),
      );
    }
  }

  static int _resolveTabIndex(String? targetScreen, NotificationCategory category) {
    switch (targetScreen) {
      case 'itinerary': return 0;
      case 'expenses': return 1;
      case 'packing': return 2;
      case 'members': return 3;
      case 'chat': return 4;
      default:
        // Fallback by category
        if (category == NotificationCategory.expense || category == NotificationCategory.payment) return 1;
        if (category == NotificationCategory.packing) return 2;
        if (category == NotificationCategory.message) return 4;
        return 0;
    }
  }
}
```

---

#### C. Visual Card Affordance in `NotificationsScreen`

```dart
// Render interactive chevron and hover/tap effect
Row(
  children: [
    // Category icon...
    // Title & Message...
    if (item.isClickable)
      const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.warmMuted,
      ),
  ],
)
```

---

### 4. Implementation Steps
1. [ ] **Model & DB Schema Sync**: Add `trip_id`, `target_screen`, and `metadata` columns to Supabase `notifications` table and `NotificationItem.fromDb`.
2. [ ] **Router Service**: Implement `NotificationRouter` with fallback screen resolvers and argument pass-through.
3. [ ] **UI Affordance**: Add chevron icon and visual ripple/press state on clickable cards in `NotificationsScreen`.
4. [ ] **Screen Parameter Support**: Ensure `TripDetailScreen` accepts `initialTabIndex` and `highlightItemId` for seamless focus landing.
5. [ ] **Realtime Push Integration**: Verify Supabase edge functions or realtime push notifications construct payloads with proper `trip_id` and `target_screen`.

> **Status**: Proposed

---

## 💡 IDEA-012: Dual-Lens Budget & Expense Hub (Personal Pocket Tracker + Group Trip Summary & Deep Insights) [PROPOSED]

### 1. Context & User Problem
Currently, the Budget Screen (`budget_screen.dart`) focuses almost exclusively on **aggregate group expenses**:
- Tab 0: *Overview* (Group category breakdown & total trip budget bar).
- Tab 1: *Expenses* (Master log of all shared group expenses).
- Tab 2: *Split* (Who owes whom / group settlement matrix).

**The Missing Piece**: When traveling in a group, each individual traveler incurs **two distinct layers of expenses**:
1. **Shared Group Expenses**: Split meals, shared Airbnb, rental vans, group boat charters (tracked in the group pool).
2. **Personal / Out-of-Pocket Expenses**: Souvenirs, personal snacks/coffee, individual shopping, private transport, personal activities/massages, and travel gear that should **NOT** be split with the group.

Without personal expense tracking, travelers are forced to use third-party apps (e.g. Notion, Notes, MoneyManager) or calculate their actual personal trip cost in their heads. Furthermore, the overall trip summary lacks deep intelligence (e.g. daily burn rates, projected runway, currency conversions, and personalized saving suggestions).

---

### 2. Core Proposal: Dual-Lens Budgeting System

Transform the Budget navigation into a comprehensive **Dual-Lens Financial Hub** featuring:
- **Lens 1: "My Personal Pocket" (Personal Expense & Cash Tracker)**:
  - Personal spending budget (e.g., *"₱10,000 personal spending money"*).
  - Private expenses logged with 1 tap (visible only to the user, never shared with the group).
  - **"My True Trip Cost"**: Sum of `(My Personal Out-of-Pocket) + (My Fair Share of Group Expenses)`.
  - Cash wallet / GCash remaining balance tracker.
- **Lens 2: "Group Trip Finances" (Deep Trip Summary & Settlement)**:
  - Master shared expenses with category donut charts and split breakdown.
  - Group remaining runway & burn rate.
- **Lens 3: Smart Recommendations & Financial Insights**:
  - Daily recommended budget limit based on remaining days.
  - Category warnings (e.g. *"Food & Dining is 42% over estimated budget"*).
  - Local Filipino price benchmark suggestions (e.g. standard tricycle / island hopping fee benchmarks).

```
┌────────────────────────────────────────────────────────────────────────┐
│               BUDGET & EXPENSES (DUAL-LENS ARCHITECTURE)               │
├────────────────────────────────────────────────────────────────────────┤
│  [ MY PERSONAL POCKET ]               [ GROUP TRIP SUMMARY ]          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   💰 MY TOTAL TRIP COST: ₱8,450                                        │
│   ┌───────────────────────────────────┬────────────────────────────┐   │
│   │ 🎒 Personal Pocket: ₱3,200        │ 👥 Group Share: ₱5,250     │   │
│   │ (Souvenirs, Coffee, Shopping)     │ (Equal split & lodgings)   │   │
│   └───────────────────────────────────┴────────────────────────────┘   │
│                                                                        │
│   📊 Daily Spending Pace: ₱1,200/day · 🟢 On Track (₱1,800/day limit)  │
│                                                                        │
│   [ ＋ Log Personal Expense (Private) ]   [ ＋ Log Shared Expense ]   │
│                                                                        │
│   📋 RECENT ACTIVITY                                                  │
│   • 🛍️ Boracay Pearls Souvenir · ₱1,200 (Personal · Cash)             │
│   • ☕ Cafe Maruja Iced Latte · ₱220 (Personal · GCash)               │
│   • 🍽️ D'Talipapa Group Dinner · ₱650 (My Share of ₱3,900)             │
│                                                                        │
│   💡 SMART TRAVELER SUGGESTIONS                                       │
│   ✨ "You have ₱2,550 left in personal pocket for 2 remaining days."   │
│   💡 "Tip: E-trike rides between Station 1 & 3 are standard ₱15-50."   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 3. Recommended Architectural & Data Design

#### A. Database Schema Updates: `is_personal` & `personal_budget`

```sql
-- 1. Add personal trip budget column to trip_members
ALTER TABLE public.trip_members 
ADD COLUMN IF NOT EXISTS personal_budget NUMERIC(12,2) DEFAULT 0.00;

-- 2. Add is_personal & visibility flags to expenses
ALTER TABLE public.expenses 
ADD COLUMN IF NOT EXISTS is_personal BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash'; -- 'cash', 'gcash', 'card', 'maya'

-- 3. RLS Policy for Personal Expenses: Private to creator only
CREATE POLICY "Personal expenses visible only to owner"
ON public.expenses FOR SELECT
USING (
    (is_personal = FALSE AND public.user_can_access_trip(trip_id))
    OR (is_personal = TRUE AND paid_by_user_id = auth.uid())
);
```

---

#### B. Riverpod State Providers (`lib/core/providers/personal_budget_provider.dart`)

```
┌──────────────────────────────────────────────────────────────┐
│                  personalBudgetProvider(tripId)              │
│       AsyncNotifierProvider<PersonalTripFinancesState>       │
├──────────────────────────────────────────────────────────────┤
│  • personalBudget: double                                    │
│  • personalExpenses: List<ExpenseModel>                      │
│  • groupShareAmount: double (calculated from split engine)   │
│  • totalPersonalSpent: double (personalExpenses + groupShare)│
│  • dailyBurnRate: double (spent / elapsedDays)               │
│  • dailyBudgetCap: double (remainingBudget / remainingDays)  │
└──────────────────────────────────────────────────────────────┘
```

---

#### C. Suggested High-Value Features for the Budget Navigation

1. **"My True Trip Cost" Card**:
   - Distinct breakdown of **Personal Pocket Expenses** (Private) vs **Group Trip Share** (Owed/Paid).
   - Clear distinction between what was paid via **GCash/Maya** vs physical **Cash on Hand** (crucial for Philippine travel with limited ATMs on islands).
2. **Interactive Toggle: `[ Personal ]` vs `[ Group ]` vs `[ Settlement ]`**:
   - Quick segmented switch at the top of the budget tab to focus on personal spending or switch to group accounting.
3. **Daily Budget Burn Gauge (Pace Meter)**:
   - Visual speedometer showing whether the traveler is *Under Budget*, *On Track*, or *Overspending* for the current day.
4. **Smart Expense Categorization & Receipt Scanning**:
   - Preset Philippine-specific quick categories: *Tricycle/Jeepney*, *Pasalubong/Souvenirs*, *Island Environmental Fees*, *Street Food/Snacks*, *Activity/Tour Guide Tips*.
5. **Post-Trip Financial Report / PDF & CSV Export**:
   - Generate a clean summary of total trip expenditure (Personal + Group) ready for personal budgeting or company reimbursement claims.

---

### 4. Implementation Steps
1. [ ] **Database Migration**: Add `is_personal` and `payment_method` to `expenses` table, and `personal_budget` to `trip_members`.
2. [ ] **Domain Model Updates**: Update `ExpenseModel` and `TripMemberModel` with personal tracking fields.
3. [ ] **Personal Budget Engine & Provider**: Implement `personalBudgetProvider` computing split shares, personal totals, and daily burn rates.
4. [ ] **Budget Screen UI Overhaul**:
   - Add segmented control (`[ Personal Pocket ]` / `[ Group Summary ]` / `[ Split & Settle ]`).
   - Build `PersonalPocketCard`, `DailyPaceGauge`, and `PaymentMethodBreakdown`.
   - Update `AddExpenseForm` with a `"Private Personal Expense"` toggle and payment method selector (`Cash`, `GCash`, `Maya`, `Card`).
5. [ ] **Smart Insights Engine**: Generate contextual budget tips based on remaining days, pace, and destination.

> **Status**: Proposed

---

## 💡 IDEA-013: Real-Time Live Weather Forecast & Severe Condition Alerts Engine [PROPOSED]

### 1. Context & User Problem
Currently, the weather forecast in `lib/core/providers/trip_weather_provider.dart` returns static mock data (`WeatherData.mock()`).
- **Problem**: When planning itineraries or traveling across the Philippines (e.g. Boracay, Siargao, Palawan, Cebu, Baguio, Batanes), weather conditions such as monsoon rains (Habagat/Amihan), tropical depressions/typhoons, high UV indices, or rough sea conditions directly dictate activity feasibility (island hopping boat cancellations, hiking safety, outdoor dining, packing requirements).
- **Missing Link**: Users currently see placeholder temperatures and static icons that do not reflect actual on-the-ground weather at the trip destination for the trip dates.

---

### 2. Core Proposal: Real-Time Weather Integration Engine

Integrate a high-reliability, zero-cost, privacy-friendly weather forecasting service (such as **Open-Meteo API** — free, no API key required, 10-14 day forecasts, hourly & daily parameters, WMO interpretation codes, precipitation probability, UV index, and geocoding) with local offline caching.

```
┌────────────────────────────────────────────────────────────────────────┐
│             REAL-TIME WEATHER FORECAST ARCHITECTURE                    │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   [ Trip Destination / Coordinates ] ──> [ Geocoding Service ]         │
│                                                │                       │
│                                                ▼                       │
│   [ Open-Meteo REST API ] <───> [ Local Sembast/Cache Layer ] (3h TTL) │
│                                                │                       │
│                                                ▼                       │
│   ┌────────────────────────────────────────────────────────────────┐   │
│   │                 tripWeatherProvider(tripId)                    │   │
│   └───────────────┬─────────────────┬──────────────────┬───────────┘   │
│                   │                 │                  │               │
│                   ▼                 ▼                  ▼               │
│          [ Itinerary Screen ]   [ Packing Engine ]  [ Alerts & Notifs] │
│          • DayStrip weather     • Auto-select       • Rain warnings    │
│          • DayInsightsHeader      rain/cold gear    • Typhoon alerts   │
│          • Activity caution     • Sun protection    • Gale warnings    │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 3. Recommended Architectural & Data Design

#### A. Weather Service & API Client (`lib/core/services/weather_service.dart`)

1. **Free & High-Accuracy Provider**: Use **Open-Meteo** (`https://api.open-meteo.com/v1/forecast` and `https://geocoding-api.open-meteo.com/v1/search`).
2. **Parameters Fetched**:
   - `daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,uv_index_max,wind_speed_10m_max,precipitation_sum`
   - `timezone=auto`
   - `start_date` & `end_date` aligned with trip duration (up to 14-16 days ahead).
3. **WMO Interpretation Code Standard Mapping**:

| WMO Code | Weather Condition | Icon Emoji | Travel Recommendation |
| :--- | :--- | :--- | :--- |
| `0` | Clear Sky | ☀️ | Great for beach & outdoor tours |
| `1, 2, 3` | Mainly Clear / Partly Cloudy | ⛅ | Ideal travel conditions |
| `45, 48` | Fog / Depositing Rime Fog | 🌫️ | Low visibility caution (mountain drives) |
| `51, 53, 55` | Drizzle (Light to Dense) | 🌦️ | Light rain gear recommended |
| `61, 63, 65` | Rain (Slight, Moderate, Heavy)| 🌧️ | Prepare waterproof gear; indoor backups |
| `80, 81, 82` | Rain Showers (Violent) | 🌧️ | Possible outdoor tour delays |
| `95, 96, 99` | Thunderstorm / Hail | ⛈️ | Outdoor activity & boat hazard alert |

---

#### B. Destination Geocoding & Coordinate Resolution

1. If `trip.departure_lat` and `trip.departure_lng` or itinerary stop coordinates (`latitude`, `longitude`) exist, use them directly ($O(1)$ lookup, zero extra API calls).
2. If only destination name exists (e.g. `"El Nido, Palawan"` or `"Baguio City"`), query Open-Meteo Geocoding API (`/v1/search?name={query}&count=1`) and cache the resolved lat/lng locally.

---

#### C. Local Cache & Offline Resiliency Layer

- **Cache Strategy**: Store weather responses locally with a `fetched_at` timestamp.
- **TTL (Time to Live)**: 3 to 6 hours.
- If network request fails or device is offline in remote travel zones (e.g. island boat tours, remote mountains), automatically return cached data with an `"Offline forecast"` tag.
- Fallback gracefully to `WeatherData.unavailable()` if no cache exists and device is offline.

---

#### D. Riverpod State Providers (`lib/core/providers/trip_weather_provider.dart`)

```dart
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final tripWeatherProvider = FutureProvider.family<List<DayForecast>, String>((ref, tripId) async {
  final tripRepo = ref.watch(tripRepositoryProvider);
  final trip = await tripRepo.getTrip(tripId);
  if (trip == null) return [];

  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.getTripForecast(trip);
});
```

---

#### E. High-Value Integrations Across Tara Travel

1. **Itinerary DayStrip & DayInsightsHeader**:
   - Display real high/low temperatures (e.g. `31° / 24°`), rain chance percentage (e.g. `💧 85%`), and weather condition icon for each day of the trip.
   - Show contextual warnings if rain chance $> 70\%$ (e.g. *"🌧️ High chance of rain today. Consider indoor alternatives for outdoor stops."*).
2. **AI & Dynamic Packing Assistant**:
   - `AIPackingDialog` automatically detects the prevailing forecast during the trip window and pre-selects the weather condition (`☀️ Sunny`, `🌧️ Rainy`, `❄️ Cold`), generating relevant essentials (e.g., umbrella, dry bag, sunscreen SPF50+, waterproof phone pouch).
3. **Severe Weather & Travel Safety Notifications**:
   - Generate local notifications for severe weather (heavy rainfall advisories, thunderstorms, or tropical storms) targeting the trip destination 24-48 hours before departure.

---

### 4. Implementation Steps

1. [x] **Weather Service Client**: Implement `WeatherService` in `lib/core/services/weather_service.dart` with Open-Meteo & OpenWeatherMap API integration and WMO code mapper.
2. [x] **Geocoding & Location Resolver**: Add destination geocoding helper with Philippine travel hub fast table and fallback to trip/stop coordinates.
3. [x] **Local Cache Layer**: Implement local memory cache with 3-hour TTL and offline fallback.
4. [x] **Update Riverpod Provider**: Refactor `trip_weather_provider.dart` to fetch live data using `WeatherService` with `tripWeatherProvider` and `tripCurrentWeatherProvider`.
5. [x] **UI Connection in Itinerary & Insights**: Connect live data to `DayStrip` and `DayInsightsHeader` via Riverpod.
6. [ ] **Packing Module Auto-Sync**: Pre-fill `AIPackingDialog` and smart packing suggestions based on destination forecast.
7. [ ] **Weather Notification Hooks**: Add helper to trigger `NotificationCategory.weather` when severe rain/storms are forecasted.

> **Status**: In Progress / Core Complete

---

## 💡 IDEA-014: Over-The-Air (OTA) Remote Updates via Shorebird Code Push + Supabase Version Gate [PROPOSED]

### 1. Context & Motivation
Currently, deploying bugfixes, UI updates, or urgent travel calculation corrections requires building a new Android App Bundle (`.aab`) or APK and waiting for Google Play Store review (which can take 24–72 hours). Additionally, when breaking backend database migrations or API changes occur, there is no remote kill-switch to enforce that outdated client versions update before corrupting data.

### 2. Core Proposal: Two-Tier Remote Update Architecture
Implement a dual-tier remote update and version control system:
1. **Tier 1 (Shorebird OTA Code Push)**: Instant over-the-air Dart patches pushed directly to users' devices within minutes, skipping app store reviews entirely for Dart code, UI, logic, and bugfixes.
2. **Tier 2 (Supabase Remote Version Gate & Kill-Switch)**: A server-driven version configuration table (`app_version_config`) hosted on Supabase that controls minimum supported versions, soft/forced updates, and maintenance mode.

---

### 3. Recommended Architectural & Data Design

```
+-------------------------------------------------------------+
|                       Tara Travel App                       |
+-------------------------------------------------------------+
          |                                        |
          v (On App Launch)                        v (Silent Background)
+---------------------------+            +----------------------------------+
| Supabase Remote Version   |            | Shorebird Code Push Engine       |
| Gate (`app_version_gate`) |            | (`shorebird_code_push`)          |
+---------------------------+            +----------------------------------+
          |                                        |
   Version Check:                           Check OTA Patch:
   current < min_required?                  - Checks Shorebird patch server
          |                                 - Downloads Dart patch silently
     +----+----+                            - Applies cleanly on next restart
     |         |                                    |
   (YES)      (NO)                           Zero Store Delay!
     |         |
[Hard Block] [Continue to AuthGate]
"Update App"
(URL Launcher)
```

#### A. Shorebird Integration
- **Package**: `shorebird_code_push`
- **Workflow**:
  - Baseline release: `shorebird release android`
  - Over-the-air live patch: `shorebird patch android`
- **Execution**: Background service checks for updates on boot; silently downloads and prepares the patch for the next app restart without disrupting active itineraries.

#### B. Supabase Remote Version Gate (`app_version_config` Table)
- **Schema**:
  - `platform` (`text`, primary key: `'android'`, `'ios'`)
  - `min_supported_version` (`text`, e.g. `'1.0.0'`)
  - `min_supported_build_number` (`int`, e.g. `1`)
  - `latest_version` (`text`, e.g. `'1.0.2'`)
  - `force_update` (`boolean`, default `false`)
  - `store_url` (`text`, Google Play Store or APK URL)
  - `release_notes` (`text`)
  - `maintenance_mode` (`boolean`, default `false`)
  - `maintenance_message` (`text`)
- **Security & RLS**: Read-only public access (`anon` and `authenticated`), write access restricted to service-role / admin.

#### C. Presentation & Guard Flow (`AppVersionGate`)
- Wraps root `TaraApp` before `AuthGate`.
- **States**:
  1. **Maintenance Mode**: Full-screen brand-styled screen (`#FAECE7` Sand / `#D85A30` Coral) explaining scheduled maintenance with a "Check Again" CTA.
  2. **Mandatory Update (Hard Gate)**: Non-dismissible dialog blocking app navigation when `currentVersion < min_supported_version` or `force_update == true`. CTA opens Play Store via `url_launcher`.
  3. **Optional Update (Soft Banner)**: Non-intrusive dismissible banner in Settings/Profile indicating a newer build is available.
  4. **Normal Execution**: Passes directly through to `AuthGate`.

#### D. Middleware / Gateway Interceptor Integration (`GatewayInterceptor`)
Using the application's existing HTTP/Dio middleware (`lib/core/middleware/gateway_interceptor.dart`) creates an active, real-time update detection channel without relying solely on cold app restarts:

1. **Outbound Handshake Headers (`onRequest`)**:
   - The middleware injects `X-App-Version: 1.0.0` and `X-Platform: android` into every outbound request.
2. **Inbound Upgrade Headers (`onResponse` / `onError`)**:
   - Backend APIs or Supabase Edge Functions return status headers:
     - `X-Upgrade-Required: true`: Triggers immediate event via an event bus / Riverpod notifier (`appUpdateRequiredNotifierProvider`).
     - `HTTP 426 Upgrade Required`: Intercepted directly in `onError`, immediately presenting the non-dismissible `UpdateRequiredDialog` without corrupting downstream response parsing.
3. **Mid-Session OTA Trigger**:
   - When the backend signals that a critical patch is ready (`X-Shorebird-Patch-Available: true`), the middleware silently invokes `AppUpdateService.downloadShorebirdPatchInBackground()`.

---

### 4. Implementation Steps
1. [ ] **Dependencies**: Add `package_info_plus` and `shorebird_code_push` to `pubspec.yaml`.
2. [ ] **Database Migration**: Create `supabase/migrations/20260904_app_version_gate.sql` provisioning `app_version_config` and RLS policy.
3. [ ] **Service & Models**: Build `AppVersionConfigModel` and `AppUpdateService` in `lib/core/services/app_update_service.dart`.
4. [ ] **Middleware Hook**: Update `GatewayInterceptor` (`gateway_interceptor.dart`):
   - Inject `X-App-Version` & `X-Platform` in `onRequest`.
   - Intercept `HTTP 426 Upgrade Required` & `X-Upgrade-Required` headers in `onResponse`/`onError` to trigger real-time version gate.
5. [ ] **UI Component**: Build `AppVersionGate` and `UpdateRequiredDialog` in `lib/core/widgets/app_version_gate.dart`.
6. [ ] **App Root Injection**: Mount `AppVersionGate` in `lib/main.dart` wrapping `TaraApp`.
7. [ ] **Operational Playbook**: Add `docs/REMOTE_UPDATES_GUIDE.md` documenting Shorebird release/patch commands and Supabase version control workflows.

> **Status**: Proposed



