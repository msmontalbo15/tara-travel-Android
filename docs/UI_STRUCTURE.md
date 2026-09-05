# 📱 Tara Travel — UI Component & Section Structure Map

> **Authoritative UI Architecture & Component Inventory**  
> **Target Framework**: Flutter (Dart) & Riverpod MVI/MVVM  
> **Theme Design System**: DM Sans (Body) + Playfair Display / Georgia (Headings) | Coral (`#D85A30`), Sand (`#FAECE7`), Deep Earth (`#2C1A14`)  
> **Last Updated**: September 2026  
> **Rule**: Keep this document updated whenever UI screens, sheets, dialogs, or subcomponents are created, refactored, or rearranged.

---

## 🧭 Navigation & Global Screen Routing Map

```mermaid
graph TD
    Splash[Splash / Get Started] --> Onboarding[Onboarding Flow (7 Steps)]
    Splash --> Home[Home Screen]
    Onboarding --> Home

    subgraph BottomNav [Main Floating Navigation Bar (5 Shell Pages)]
        HomeTab[Home Tab]
        TripsTab[Trips Tab]
        BudgetTab[Budget Tab]
        ExploreTab[Explore Tab]
        ProfileTab[Profile Tab]
    end

    Home --> HomeTab
    Home --> TripsTab
    Home --> BudgetTab
    Home --> ExploreTab
    Home --> ProfileTab

    HomeTab --> CreateTrip[Create Trip Flow (4 Steps)]
    HomeTab --> TripDetail[Trip Detail Hub]
    HomeTab --> Notifications[Notifications Center]
    HomeTab --> Friends[Friends Management Screen]

    TripDetail --> Itinerary[Itinerary & Day Schedule]
    TripDetail --> BudgetSub[Budget & Expense Tracking]
    TripDetail --> Packing[Packing Checklist]
    TripDetail --> Members[Members & Permissions]
    TripDetail --> LiveNav[Live Navigation & GPS Convoy]
    TripDetail --> Chat[Trip Group Chat & Polls]
    TripDetail --> Activity[Activity Audit Log]
```

### Route Registry (`lib/main.dart`)
| Route Name | Target Widget | Primary Screen Path |
| :--- | :--- | :--- |
| `/` | `SplashScreen` | `lib/features/splash/splash_screen.dart` |
| `/onboarding` | `OnboardingScreen` | `lib/features/onboarding/onboarding_screen.dart` |
| `/home` | `HomeScreen` | `lib/features/home/home_screen.dart` |
| `/create-trip` | `CreateTripFlow` | `lib/features/create_trip/create_trip_flow.dart` |
| `/notifications`| `NotificationsScreen` | `lib/features/notifications/notifications_screen.dart` |
| `/budget` | `BudgetScreen` | `lib/features/budget/budget_screen.dart` |
| `/itinerary` | `ItineraryScreen` | `lib/features/itinerary/itinerary_screen.dart` |
| `/navigation` | `LiveNavigationScreen` | `lib/features/navigation/live_navigation_screen.dart` |
| `/packing` | `PackingScreen` | `lib/features/packing/packing_screen.dart` |
| `/members` | `MembersScreen` | `lib/features/members/members_screen.dart` |
| `/explore` | `ExploreScreen` | `lib/features/explore/explore_screen.dart` |
| `/profile` | `ProfileScreen` | `lib/features/profile/profile_screen.dart` |
| `/trip-detail` | `TripDetailScreen` | `lib/features/trip_detail/trip_detail_screen.dart` |
| `/activity` | `ActivityLogScreen` | `lib/features/activity/activity_log_screen.dart` |
| `/chat` | `ChatScreen` | `lib/features/chat/chat_screen.dart` |
| `/trips` | `TripsScreen` | `lib/features/trips/trips_screen.dart` |
| `/friends` | `FriendsScreen` | `lib/features/friends/friends_screen.dart` |

---

## 🎨 Global Design Tokens & Reusable Core Components

### 1. Color Palette (`lib/core/theme/app_colors.dart`)
- **Primary / Brand**: Coral (`#D85A30`), Light Coral (`#F0997B`)
- **Backgrounds**: Deep Earth (`#2C1A14`), Sand (`#FAECE7`), Surface Light (`#F7F4F0`)
- **Accents & Status**: Sunset Amber (`#EF9F27`), Green (`#2E7D32`), Red (`#C62828`), Sky Blue (`#1E88E5`)

### 2. Typography (`lib/core/theme/app_text_styles.dart`)
- **Body & UI**: `DM Sans` (Regular 400, Medium 500, Semi-bold 600, Bold 700)
- **Headings & Display**: `Playfair Display` (Bold 700, Italic) with `Georgia` serif fallback

### 3. Core Component Library (`lib/core/widgets/`)
| Category | File Path | Component Name | Description |
| :--- | :--- | :--- | :--- |
| **Brand** | `app_brand_logo.dart` | `AppBrandLogo` | Tara road-badge SVG/Canvas logo + wordmark |
| **Nav Shell** | `navigation/floating_nav_bar.dart` | `FloatingNavBar` | Floating pill 5-tab bar with active indicators |
| **Buttons** | `buttons/app_back_button.dart` | `AppBackButton` | Standard & glass back navigation button |
| **Indicators**| `dynamic_island_pill.dart` | `DynamicIslandPill` | Top floating status pill for active alerts |
| **Cards** | `glass_card.dart` | `GlassCard` | Frosted blur translucent surface container |
| **Avatars** | `member_avatar_circle.dart` | `MemberAvatarCircle` | Cached network image avatar with initial fallbacks |
| **Pickers** | `multi_member_picker_sheet.dart` | `MultiMemberPickerSheet` | Multi-select member sheet with avatars & search |
| **Location** | `ph_location_picker.dart` | `PhLocationPicker` | Region/Province/City/Barangay PH cascader |
| **Location** | `inputs/location_picker.dart` | `LocationPicker` | Nominatim search input with pin support |
| **Location** | `inputs/map_pin_picker_modal.dart`| `MapPinPickerModal` | Interactive OpenStreetMap pin dropper |
| **Date** | `inputs/tara_date_range_picker.dart` | `TaraDateRangePicker` | Custom start-to-end trip calendar picker |
| **Date** | `inputs/app_date_picker.dart` | `AppDatePicker` | Single date input picker field |
| **Form Inputs**| `inputs/app_text_field.dart` | `AppTextField` | 12px radius standard text input with validation |
| **Form Inputs**| `inputs/app_dropdown.dart` | `AppDropdown` | Custom styled select menu dropdown |
| **Form Inputs**| `inputs/app_numeric_field.dart`| `AppNumericField` | Decimal & currency formatted input field |
| **Scanner** | `scanner/qr_scanner_modal.dart` | `QrScannerModal` | Camera QR scanner sheet (trips & friends) |
| **Share** | `share/share_trip_modal.dart` | `ShareTripModal` | QR display, invite link & native share sheet |
| **Feedback** | `feedback/app_banner.dart` | `AppBanner` | Floating snack / notification banners |
| **Feedback** | `feedback/app_dialog.dart` | `AppDialog` | Styled confirmation and warning modals |
| **Feedback** | `profile_completion_banner.dart` | `ProfileCompletionBanner` | Sticky warning prompt for incomplete profile |
| **Legal** | `npc_privacy_policy_sheet.dart` | `NpcPrivacyPolicySheet` | PH Data Privacy Act consent bottom sheet |
| **Shimmers** | `shimmer_loading.dart` | `TripsListSkeleton`, etc. | Shimmer skeletons for data loading states |

---

## 📱 Detailed UI Screen Breakdown

---

### 1. Home Dashboard (`lib/features/home/`)
**Primary Entry**: `HomeScreen` (`home_screen.dart`)  
**Container**: `PopScope` + `Stack` with `IndexedStack` (5 tabs) + `FloatingNavBar` at bottom.

#### Header Section (SliverPersistentHeader: `_HomeHeaderDelegate`)
- **Top Inset Bar**: Profile avatar with initials/network image, greeting (*"Good morning, Spencer"*), Notification bell with unread badge.
- **Active Trip Hero Card** (`widgets/next_trip_card.dart`):
  - Badge with Trip Type Icon & Status pill (*"Ongoing"* / *"Planned"*).
  - Trip Title, Destination, and formatted Date Range.
  - Quick Countdown Tag (*"In 3 days"* / *"Day 2 of 5"*).
  - Quick Tap-through to `TripDetailScreen` or `LiveNavigationScreen`.
- **Empty State Hero** (`widgets/empty_trip_hero_card.dart`):
  - Displayed when no active trip exists, inviting user to create or join.

#### Body Content Section (`_HomeBody` via `CustomScrollView`)
1. **Your Trips Section**:
   - Header with section title + *"See all"* button (navigates to `TripsScreen`).
   - List of active/draft trip cards (`widgets/trip_card.dart`):
     - Destination image/icon, trip name, dates, overlap conflict warnings.
     - 3-dot overflow menu triggering `TripActionSheet` (`widgets/trip_action_sheet.dart`).
   - If zero trips: `StarterTemplatesCarousel` (`widgets/starter_templates_carousel.dart`) featuring pre-populated destination templates.
2. **Quick Actions Grid** (`widgets/quick_action_tile.dart`):
   - **New Trip** (Primary Coral): Navigates to `CreateTripFlow`.
   - **Invite** (Sand): Launches `MembersScreen` or share modal.
   - **Split Bill**: Opens `BudgetScreen` (checks GCash JIT guard).
   - **Packing**: Opens `PackingScreen` with live progress percentage sublabel.
3. **Interactive Walkthrough Tour Overlay** (`_TourCard` & `_TourFocus`):
   - Guided onboarding walkthrough for new users highlighting header, trips, and quick actions.

---

### 2. Trip Detail Hub (`lib/features/trip_detail/`)
**Primary Entry**: `TripDetailScreen` (`trip_detail_screen.dart`)  
**Purpose**: Central operational cockpit for a specific selected trip.

#### Components & Sections:
1. **Collapsible Header**:
   - Trip Cover gradient / type background.
   - Trip Title, Destination, Date range, and Status pill.
   - Back button (`AppBackButton`), Share button (`ShareTripModal`), and Edit button (`EditTripSheet`).
2. **Trip Health & Countdown HUD**:
   - Dynamic days countdown (*"T-minus 2 days"*).
   - Departure Point & Meet-up assembly summary tag.
3. **Feature Navigation Grid**:
   - **Itinerary Tile**: Days count, next scheduled stop, progress bar.
   - **Budget & Expenses Tile**: Spent vs Total budget bar, liability indicator.
   - **Packing Checklist Tile**: Packed items ratio and pending alerts.
   - **Members & Roles Tile**: Member avatars list, organizer crown tag.
   - **Live Navigation Tile**: GPS status, convoy tracker shortcut.
   - **Trip Group Chat Tile**: Unread message badges and active poll count.
4. **Draft Trip Action Bar**:
   - Publish Trip banner button (transitions trip from `draft` to `planned`).
5. **Inline Activity Feed**:
   - Recent member edits, expense additions, or itinerary changes.

---

### 3. Itinerary & Schedule Planner (`lib/features/itinerary/`)
**Primary Entry**: `ItineraryScreen` (`itinerary_screen.dart`)  
**View Modes**: List View vs Timeline View (toggleable).

#### Components & Sections:
1. **Top Bar & Weather Insights**:
   - Header with trip title and back navigation.
   - `DayInsightsHeader` (`widgets/day_insights_header.dart`): Destination weather forecast, total day distance, and pacing summary.
2. **Day Selector Horizontal Strip**:
   - `DayStrip` (`widgets/day_strip.dart`): Scrollable pills for Day 1, Day 2, etc., with dates and active indicator.
3. **GPS Arrival Geofence Banner**:
   - `ArrivalPill` (`widgets/arrival_pill.dart`): Dynamic pill popping up when GPS detects proximity to the next stop, with a *"Slide to Arrive"* button (`widgets/slide_to_arrive_button.dart`).
4. **Day Summary & Pacing Bar**:
   - `DaySummaryCard` (`widgets/day_summary_card.dart`): Overview of stops count and travel time.
   - `DayBudgetBar` (`widgets/day_budget_bar.dart`): Allocated vs spent budget for the active day.
5. **Stops List & Timeline**:
   - `StopCard` (`widgets/stop_card.dart`): Individual stop card with stop type icon, start/end times, cost tag, booking reference, and companion check-in avatars.
   - `TimelineView` (`widgets/timeline_view.dart`): Connected vertical line node rendering for chronological visual flow.
   - `InterStopTransitBadge` (`widgets/inter_stop_transit_badge.dart`): Driving/transit travel duration and distance between stops, flagging conflicts via `TransitConflictHelper`.
6. **Actions & Bottom Floating Dock**:
   - `ItineraryBottomDock` (`widgets/itinerary_bottom_dock.dart`): Floating glass dock with quick actions:
     - **Add Stop** (opens `AddStopForm` in `widgets/add_stop_form.dart`).
     - **Day Map** (opens `ItineraryMapSheet` in `widgets/itinerary_map_sheet.dart`).
     - **Day Actions** (opens `DayActionsSheet` in `widgets/day_actions_sheet.dart` for reordering and clearing).
7. **Modals & Detail Sheets**:
   - `StopDetailSheet` (`widgets/stop_detail_sheet.dart`): Detailed sheet with map coordinates, companion check-ins, booking refs, and quick navigation button (`NavigateRouteButton`).
   - `EditStopForm` (`widgets/edit_stop_form.dart`): Full form to modify an existing stop.
   - `SmartSuggestionChips` (`widgets/smart_suggestion_chips.dart`): Recommended POIs nearby.

---

### 4. Budget & Split Bill Hub (`lib/features/budget/`)
**Primary Entry**: `BudgetScreen` (`budget_screen.dart`)  
**Scope Switcher**: `[ Personal Budget | Trip Expenses ]`

#### Components & Sections:
1. **Top Scope Switcher**:
   - Pill toggle switching between Personal wallet tracking and Group fund expenses.
2. **Hero Budget Card**:
   - **Personal Scope**: `PersonalTripBudgetHeroCard` (`widgets/personal_trip_budget_hero_card.dart`) showing user's allocated allowance, spent amount, and group liability.
   - **Trip Scope**: `TripBudgetHeroCard` (`widgets/trip_budget_hero_card.dart`) showing total trip budget, approved group expenditure, and remaining pool.
3. **Budget Analytics & Visualizations**:
   - `DailyPacingCard` (`widgets/daily_pacing_card.dart`): Daily burn rate tracker.
   - `CategoryBudgetChart` (`widgets/category_budget_chart.dart`): Visual breakdown by Food, Transport, Lodging, Activities, etc.
   - `CashVsDigitalCard` (`widgets/cash_vs_digital_card.dart`): Cash vs GCash/digital split.
   - `AlertBanner` (`widgets/alert_banner.dart`): Warnings when budget threshold exceeds 80% or 100%.
4. **Expense Management**:
   - Sub-tabs under Trip Expenses: `[ Overview | Expenses | Split ]`.
   - `ExpenseLog` (`widgets/expense_log.dart`): List of expenses with status (pending, approved, rejected), receipt preview thumbnails, and payer details.
   - `PersonalExpenseList` (`widgets/personal_expense_list.dart`): Filtered list of user's own expenses.
   - `AddExpenseForm` (`widgets/add_expense_form.dart`): Bottom sheet to log expenses, upload receipts, pick category, and assign payers.
   - `SplitBillPanel` (`widgets/split_bill_panel.dart`): Net debt resolution matrix calculating who owes whom via simplified transactions.
   - `MemberContributionCard` (`widgets/member_contribution_card.dart`): Breakdown of paid expenses per member.
   - `SetAllowanceSheet` (`widgets/set_allowance_sheet.dart`): Modal to set or update personal trip budget.

---

### 5. Create Trip Wizard (`lib/features/create_trip/`)
**Primary Entry**: `CreateTripFlow` (`create_trip_flow.dart`)  
**Flow Model**: 4-Step PageView with `StepIndicator` (`widgets/step_indicator.dart`).

#### Steps:
1. **Step 1: Details** (`steps/details_step.dart`):
   - Trip Name input.
   - Destination picker (with autocomplete & map coordinates).
   - Trip Type selector (`TripTypeCarousel` in `shared/widgets/`).
   - Departure Point & Meet-up location input (with map pin picker).
   - Date range selector (`TaraDateRangePicker`).
2. **Step 2: Transport** (`steps/transport_step.dart`):
   - Transport Mode selection (Car/Van, Flight, Ferry/Boat, Bus, Commute).
   - Dynamic detail fields: Vehicle count, flight number, ferry operator, booking reference, estimated transit cost.
3. **Step 3: Budget** (`steps/budget_step.dart`):
   - Total group budget input (`AppNumericField`).
   - Split method selector (Equal, Custom, Percentage).
   - Initial personal allowance configuration.
4. **Step 4: Confirm & Summary** (`steps/confirm_step.dart`):
   - Review trip summary card with all configured parameters.
   - Create Trip CTA button triggering `TripCreationLoadingOverlay` (`widgets/trip_creation_loading_overlay.dart`) with stepped animation (Trip Creation $\rightarrow$ Initial Meet-up Stop Insertion $\rightarrow$ Complete).

---

### 6. Live Navigation & Convoy Tracking (`lib/features/navigation/`)
**Primary Entry**: `LiveNavigationScreen` (`live_navigation_screen.dart`)  
**Tabs**: `[ Live Map | Group | Proximity | Arrived ]`

#### Components & Sections:
1. **Top Navigation Header** (`_NavHeader`):
   - Back button, trip title, emergency SOS trigger button, and Privacy mode toggle.
2. **Live Map Tab** (`widgets/live_map_tab.dart` & `widgets/nav_map_view.dart`):
   - OpenStreetMap layer (`flutter_map`) with dynamic zoom/center.
   - Route Polyline between stops with turn guidance hints.
   - Real-time GPS markers for user and companions.
   - `ConvoyAlertBanner` (`widgets/convoy_alert_banner.dart`): Warning when convoy members fall behind.
3. **Group Tracker Tab** (`widgets/group_tracker_tab.dart`):
   - List of all trip members with real-time distance from destination/leader, battery status, and online indicator.
   - Shortcut to `NavigateToMemberSheet` (`widgets/navigate_to_member_sheet.dart`).
4. **Proximity Alert Tab** (`widgets/proximity_alert_tab.dart`):
   - Radar-style distance display alerting when members wander outside the safety radius.
5. **Arrived Tab** (`widgets/arrived_tab.dart`):
   - Destination celebration screen showing arrival milestones, final travel times, and member roll-call.
6. **Sheets & Modals**:
   - `SosEmergencyModal` (`widgets/sos_emergency_modal.dart`): High-priority emergency broadcast modal triggering alerts to companions and emergency contacts.
   - `PrivacyControlSheet` (`widgets/privacy_control_sheet.dart`): Toggle exact vs blurred GPS location sharing.

---

### 7. Packing Checklist (`lib/features/packing/`)
**Primary Entry**: `PackingScreen` (`packing_screen.dart`)  
**Tabs**: `[ All Items | My Items ]`

#### Components & Sections:
1. **Header & Overall Progress Card**:
   - Circular/linear packing percentage indicator (`packedPct`).
   - Search filter bar and expand/collapse all toggle.
2. **Categorized Item Sections**:
   - Expandable category groups (Clothing, Toiletries, Electronics, Documents, Essentials).
   - Item row with checkbox, item title, and member assignment chip.
3. **Action Triggers & Modals**:
   - **Add Item Form**: Quick input field to append new packing items.
   - **AI Packing Dialog** (`widgets/ai_packing_dialog.dart`): Generates recommended packing list based on destination type, weather forecast, and trip duration.
   - **Packing Template Modal** (`widgets/packing_template_modals.dart`): Apply starter templates (e.g. Beach, Hiking, Business).
   - **Member Assignment Sheet** (`widgets/member_assignment_sheet.dart`): Reassign shared gear (e.g. First Aid, Tent) to specific travelers.

---

### 8. Trip Group Chat & Live Polls (`lib/features/chat/`)
**Primary Entry**: `ChatScreen` (`chat_screen.dart`)  
**Capabilities**: Supabase Realtime messaging, media attachments, and interactive polls.

#### Components & Sections:
1. **Chat Header**:
   - Trip title, active members count, and pinned items drawer toggle.
2. **Pinned Polls / Items Drawer**:
   - Horizontal sliding carousel of active polls and urgent pinned announcements.
3. **Message Stream**:
   - Realtime message bubble list with timestamp, sender avatar, and read indicators.
   - **Special Embeds** (`widgets/chat_embed_cards.dart`):
     - Itinerary stop proposal cards.
     - Expense payment proposal cards.
   - **Poll Card** (`widgets/poll_card.dart`): Interactive voting card with multiple options, vote tallies, and resolution badges.
4. **Bottom Message Bar**:
   - Text input field, send button, and attachment trigger.
   - `ChatAttachmentPickerSheet` (`widgets/chat_attachment_picker_sheet.dart`): Photo picker, location share, or poll creator.
   - `CreatePollSheet` (`widgets/create_poll_sheet.dart`): Modal to draft new single or multi-choice polls with voting deadlines.

---

### 9. Members & Social Graph (`lib/features/members/` & `lib/features/friends/`)

#### Members Screen (`lib/features/members/members_screen.dart`):
- **Role Sections**: Organizers / Coordinators vs Members vs Pending Invites.
- **Member Row**: Avatar circle, formatted display name (respecting `hide_surname` rule), role tag, and contact icons.
- **Member Management Actions**: Kick member, promote to organizer, approve pending requests, or leave trip.
- **Invite CTA**: Triggers `ShareTripModal` (Invite code, QR, SMS/Messenger share).

#### Friends Screen (`lib/features/friends/friends_screen.dart`):
- **Tabs**: `[ Friends | Requests | Find Friends ]`.
- **Search & Filter Bar**: Realtime text filter with online-only toggle.
- **Friend List Item** (`widgets/friend_list_item.dart`): Display name, mutual trips count, status badge, remove/block options.
- **QR Code & Scanner**: Floating action button to display personal friend QR or open camera `QrScannerModal`.

---

### 10. User Profile & Settings (`lib/features/profile/`)
**Primary Entry**: `ProfileScreen` (`profile_screen.dart`)

#### Components & Sections:
1. **User Identity Header**:
   - Large avatar with edit photo button (`ImagePicker`), display name, and bio.
   - Personal QR code modal button for instant friend adding.
2. **Profile Completion Progress Bar**:
   - Visual bar guiding user to fill in city, emergency contacts, and GCash info.
3. **Location & Personal Details Form**:
   - Home Country, Region, City, and Barangay pickers (`PhLocationPicker`).
   - Birthday, Blood type, dietary restrictions, and allergy tags.
4. **Payment & GCash Section**:
   - Encrypted GCash phone number input and GCash QR code image upload.
5. **Security & Biometrics Hub**:
   - Biometric fingerprint/face unlock toggle (`BiometricAuthService`).
   - 4-Digit MPIN management and days remaining tracker (`MpinSecurityService`).
   - Privacy settings: `hide_surname` toggle (e.g. converts *"Juan Dela Cruz"* $\rightarrow$ *"Juan D."*).
   - Data Privacy consent viewer (`NpcPrivacyPolicySheet`).
6. **Account Actions**:
   - Logout button (clears `SecureSessionRepository` and resets partitioned local DB).

---

### 11. Explore Destinations (`lib/features/explore/explore_screen.dart`)
- **Search & Filter Header**: Destination search bar and category filter pills (Beach, Mountain, Heritage, City).
- **Featured Carousel**: Highlighted Philippine travel destinations with curated photos, description, and weather.
- **Destination Grid**: Destination cards with popular stops, average budget estimate, and a *"Plan a Trip Here"* shortcut pre-filling `CreateTripFlow`.

---

### 12. Notifications Center (`lib/features/notifications/notifications_screen.dart`)
- **Filter Chips Bar**: `[ All | Unread | Expenses | Messages | Alerts ]`.
- **Notification Item List**: Categorized icon, title, relative timestamp (*"2m ago"*), read/unread status indicator, and tap navigation leading directly to the relevant trip screen.
- **Bulk Actions**: Mark all as read button.

---

### 13. Activity Audit Log (`lib/features/activity/activity_log_screen.dart`)
- **Available Modes**: Standalone screen with app bar or inline widget (`ActivityLogScreenInline`) embedded in `TripDetailScreen`.
- **Log Feed**: Chronological list of user activities (trip updates, expense approvals, member additions) with timestamps and user avatars.

---

### 14. Splash & App Cold Start (`lib/features/splash/splash_screen.dart`)
- **Animations**: Sequential logo scale, rotation, opacity, and path tracing animations.
- **Session Check**: Rehydrates Keystore session via `SecureSessionRepository`.
  - Authenticated session $\rightarrow$ auto-transitions to `/home`.
  - Unauthenticated / first-time user $\rightarrow$ displays *"Get Started"* button leading to `/onboarding`.

---

### 15. Onboarding Flow (`lib/features/onboarding/onboarding_screen.dart`)
**Flow Model**: 7-Step PageView with smooth transition curves.
1. `choose_mode_step.dart`: Solo vs Group planning persona selection & sign-in mode.
2. `permissions_step.dart`: Geolocation, notifications, and camera permissions prompt.
3. `profile_photo_step.dart`: Camera/gallery avatar upload.
4. `nickname_birthday_step.dart`: Display name and age verification.
5. `preferences_step.dart`: Travel interests (Beach, Hiking, Foodie, Heritage) and currency.
6. `health_safety_step.dart`: Blood type, allergies, and emergency contact details.
7. `all_set_step.dart`: Final completion celebration leading into `/home`.

---

## 🛠️ How to Update This Document

When introducing UI modifications:
1. **New Screen Added**:
   - Register route in `/lib/main.dart` and add entry to Section 1 (Route Registry) & Mermaid Diagram.
   - Add new screen breakdown subsection detailing sections, headers, and child widgets.
2. **New Sheet / Modal / Form Added**:
   - Add entry to the relevant screen subsection under its subcomponents list.
   - If generic/reusable, register it under Section 2 (`lib/core/widgets/`).
3. **Component Relocated or Refactored**:
   - Update file path and class name in the corresponding subsection.
4. **Always cross-reference with `docs/MEMORY.md` and `docs/IMPLEMENTATION_MEMORY.md`** to maintain architectural consistency.
