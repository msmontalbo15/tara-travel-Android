# Tara Travel — Developer Ideas & Architecture Backlog (`DEV_IDEA.md`)

This document tracks developer proposals, feature concepts, and architectural enhancement ideas for the **Tara Travel** application.

---

## 💡 IDEA-001: Standardized & Brand-Unified Feedback System (Alerts, SnackBars & Modals)

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

## 💡 IDEA-002: Streamlined Itinerary Experience via Progressive Disclosure & Unified Action Hub

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

## 💡 IDEA-003: Real-Time Group Live Location Sharing, Convoy Tracking & Direct Member Navigation

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
