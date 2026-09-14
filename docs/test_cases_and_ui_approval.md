# Test Cases & Screen UI Approval
## QuickActionTile Refactoring + Find Friends Button Cleanup

> [!NOTE]
> Covers changes from conversations:
> - **Quick Action Tile Refactoring** — Full modern polish (Option C), variant system, dark-mode/tablet resilience, label/icon changes
> - **Refactoring Find Friends Buttons** — Option B: consolidated actions into Find Friends tab, cleaned top header

---

## 1. Modified Files Summary

| File | Change Type | Scope |
|:-----|:-----------|:------|
| [`quick_action_tile.dart`](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/widgets/quick_action_tile.dart) | Refactored | `QuickActionVariant` enum, gradient cards, scale animation, Semantics/Tooltip, dark-mode colors |
| [`home_screen.dart`](file:///d:/Spencer/Downloads/tara_travel/lib/features/home/home_screen.dart) | Modified | Quick action labels: "Join trip" (was Invite), "Friends" (was Split bill), "Navigate" with conditional sublabel |
| [`friends_screen.dart`](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/friends_screen.dart) | Modified | Find Friends tab: 3-button discovery bar (Scan QR / My QR Code / Add by ID), removed top header buttons |
| [`friend_list_item.dart`](file:///d:/Spencer/Downloads/tara_travel/lib/features/friends/widgets/friend_list_item.dart) | Existing | No direct changes — verify integration still correct |

---

## 2. QuickActionTile — Test Cases

### 2.1 Visual & Layout

- [ ] **TC-QA-01**: Primary variant (orange=true / `QuickActionVariant.primary`) renders coral→orange gradient fill
- [ ] **TC-QA-02**: Surface variant (default) renders white card with subtle `AppColors.cardBorder` border
- [ ] **TC-QA-03**: Accent variant renders sand/amber styling with correct icon and text colors
- [ ] **TC-QA-04**: Icon box renders 32×32 with 10px rounded corners
- [ ] **TC-QA-05**: Label uses `DM Sans` (`AppTextStyles.fontBody`) at 13.5px bold
- [ ] **TC-QA-06**: Sublabel uses `DM Sans` at 11px, w500, secondary color
- [ ] **TC-QA-07**: Card border radius is 18px
- [ ] **TC-QA-08**: `FittedBox` prevents label and sublabel overflow on narrow screens
- [ ] **TC-QA-09**: Card has correct `BoxShadow` for each variant (primary: coral glow, surface: subtle, accent: amber)

### 2.2 Interactions & Feedback

- [ ] **TC-QA-10**: Tap triggers `HapticFeedback.lightImpact()` + `onTap` callback
- [ ] **TC-QA-11**: Press-down animates scale to 0.96 via `AnimatedScale` (120ms, easeOutCubic)
- [ ] **TC-QA-12**: Release restores scale to 1.0 smoothly
- [ ] **TC-QA-13**: `InkWell` ripple renders inside 18px rounded border (no overflow)
- [ ] **TC-QA-14**: Long-press shows `Tooltip` with label text

### 2.3 Accessibility

- [ ] **TC-QA-15**: `Semantics` widget wraps tile with `button: true` and combined label+sublabel string
- [ ] **TC-QA-16**: TalkBack/VoiceOver reads "New trip, Start planning" (for the primary tile)

### 2.4 Dark Mode

- [ ] **TC-QA-17**: Surface variant uses `Color(0xFF221612)` background in dark mode
- [ ] **TC-QA-18**: Surface variant border becomes `white @ 0.08 alpha` in dark mode
- [ ] **TC-QA-19**: Labels become white/white70 in dark mode for surface variant
- [ ] **TC-QA-20**: Primary variant gradient is consistent across light/dark (shadow opacity increases in dark)

### 2.5 Responsiveness

- [ ] **TC-QA-21**: Grid renders 2 columns (`crossAxisCount: 2`) with 12px spacing
- [ ] **TC-QA-22**: `childAspectRatio: 1.52` maintains correct proportions on different screen widths
- [ ] **TC-QA-23**: On tablets/large screens, tiles scale proportionally without cropping

---

## 3. Home Screen Quick Actions — Test Cases

### 3.1 Label & Icon Verification

| Tile | Icon | Label | Sublabel | Route |
|:-----|:-----|:------|:---------|:------|
| New trip | `Icons.add_rounded` | "New trip" | "Start planning" | `/create-trip` |
| Join trip | `Icons.group_add_outlined` | "Join trip" | "Enter code" | `showJoinTripModal()` |
| Friends | `Icons.people_outline_rounded` | "Friends" | "Find & connect" | `/friends` |
| Navigate | `Icons.navigation_outlined` | "Navigate" | "Convoy & map" / "Start a trip first" | `/navigation` |

- [ ] **TC-HS-01**: "New trip" tile has `orange: true` (primary gradient variant)
- [ ] **TC-HS-02**: "Join trip" tile is surface variant, opens Join Trip modal on tap
- [ ] **TC-HS-03**: "Friends" tile is surface variant, navigates to `/friends`
- [ ] **TC-HS-04**: "Navigate" sublabel shows "Convoy & map" when active trip exists
- [ ] **TC-HS-05**: "Navigate" sublabel shows "Start a trip first" when no active trip
- [ ] **TC-HS-06**: Navigate tile shows info feedback when tapped with no active trip
- [ ] **TC-HS-07**: Navigate tile selects active trip and pushes `/navigation` when trip exists

### 3.2 JIT Guard

- [ ] **TC-HS-08**: "New trip" tile calls `JitGuard.checkCreateTripGuard()` before navigation
- [ ] **TC-HS-09**: When guard returns `false`, creation flow does not launch
- [ ] **TC-HS-10**: When guard passes, `setFirstRunCompleted()` is called and `/create-trip` launches

---

## 4. Friends Screen — Test Cases

### 4.1 Top Header

- [ ] **TC-FR-01**: Header shows "Friends" title centered
- [ ] **TC-FR-02**: `AppBackButton` (light variant) appears when `Navigator.canPop` is true
- [ ] **TC-FR-03**: Right padding spacer (48px) balances layout when back button is present
- [ ] **TC-FR-04**: No QR/Scan/Add buttons in the top header bar (all moved to Find Friends tab)

### 4.2 Segmented Tab Bar

- [ ] **TC-FR-05**: 3 tabs render: "My Friends", "Requests", "Find Friends"
- [ ] **TC-FR-06**: Active tab indicator is white with 11px rounded corners and subtle shadow
- [ ] **TC-FR-07**: Active tab label color is `AppColors.primary` (coral)
- [ ] **TC-FR-08**: Inactive tab label is `AppColors.textSecondary`
- [ ] **TC-FR-09**: Requests tab shows coral badge with count when `requestCount > 0`
- [ ] **TC-FR-10**: Badge hides when incoming request count is 0
- [ ] **TC-FR-11**: Tab container background is `Color(0xFFEDE8E3)` with 14px border radius

### 4.3 Tab 1: My Friends

- [ ] **TC-FR-12**: Empty state shows group icon, "No Friends Yet" title, descriptive text
- [ ] **TC-FR-13**: Empty state has "Find Friends" CTA button (navigates to tab index 2)
- [ ] **TC-FR-14**: Empty state has "My QR" outlined button (opens QR modal)
- [ ] **TC-FR-15**: Friends list shows online summary banner with "All" and "Online" filter chips
- [ ] **TC-FR-16**: "All" chip is coral when selected, surface when deselected
- [ ] **TC-FR-17**: "Online" chip is green when selected, green-tinted when deselected
- [ ] **TC-FR-18**: Online count text shows "X active" or "All offline"
- [ ] **TC-FR-19**: Local filter text field appears when friends count > 4
- [ ] **TC-FR-20**: Filter text field filters friends by name and email in real-time
- [ ] **TC-FR-21**: Clear button resets filter when text is present
- [ ] **TC-FR-22**: Online-only mode shows "No friends currently online" when all offline
- [ ] **TC-FR-23**: "Show all friends" button resets `_showOnlineOnly` to false
- [ ] **TC-FR-24**: Pull-to-refresh invalidates all friend providers
- [ ] **TC-FR-25**: Each friend renders as `FriendListItem` with avatar, name, presence indicator
- [ ] **TC-FR-26**: Realtime presence provider (`friendsRealtimePresenceProvider`) is watched

### 4.4 Tab 2: Requests

- [ ] **TC-FR-27**: "Incoming Requests" section header with mail icon and count badge
- [ ] **TC-FR-28**: Empty incoming state shows check icon and "No incoming requests" message
- [ ] **TC-FR-29**: Incoming requests render `FriendListItem` with `isIncomingRequest: true`
- [ ] **TC-FR-30**: Accept button sends request, shows success feedback
- [ ] **TC-FR-31**: Decline button rejects request, shows info feedback
- [ ] **TC-FR-32**: "Sent Requests" section shows outgoing count label
- [ ] **TC-FR-33**: Outgoing requests show "Cancel" action button
- [ ] **TC-FR-34**: Cancel action calls `rejectRequest()` and shows feedback
- [ ] **TC-FR-35**: Pull-to-refresh works for both sections

### 4.5 Tab 3: Find Friends

- [ ] **TC-FR-36**: Discovery Action Bar renders 3 equal-width buttons in a `Row`
- [ ] **TC-FR-37**: "Scan QR" button — icon: `qr_code_scanner_rounded`, color: coral, style: surface (white bg)
- [ ] **TC-FR-38**: "My QR Code" button — icon: `qr_code_rounded`, color: deep earth, style: surface (white bg)
- [ ] **TC-FR-39**: "Add by ID" button — icon: `person_add_rounded`, style: primary (coral fill, white text)
- [ ] **TC-FR-40**: "Scan QR" opens `QrScannerModal`, processes scanned ID
- [ ] **TC-FR-41**: "My QR Code" opens bottom sheet with QR image, display name, copy chip, share button
- [ ] **TC-FR-42**: "Add by ID" opens dialog with text input, live user preview, send request action
- [ ] **TC-FR-43**: Search bar (`AppTextField`) with debounce (300ms) filters users by name/email
- [ ] **TC-FR-44**: When search query is empty, discovery help banner shows with usage instructions
- [ ] **TC-FR-45**: When search query is active, search results replace help banner
- [ ] **TC-FR-46**: Empty search results show "No travelers found" with search icon
- [ ] **TC-FR-47**: Found users display count label and `FriendListItem` with `isSearchMode: true`

### 4.6 Discovery Action Button Widget (`_discoveryActionBtn`)

- [ ] **TC-FR-48**: Primary button has coral background, coral shadow, white icon+text
- [ ] **TC-FR-49**: Surface button has white background, subtle shadow, card border
- [ ] **TC-FR-50**: Icon is 17px, 6px gap before label text
- [ ] **TC-FR-51**: Label uses 12px bold text, `maxLines: 1` with `TextOverflow.ellipsis`
- [ ] **TC-FR-52**: Buttons have 14px border radius and 12px vertical / 8px horizontal padding

### 4.7 QR Code Modal

- [ ] **TC-FR-53**: Modal has 28px top border radius, handle bar, "My Friend Code" title
- [ ] **TC-FR-54**: QR code renders 200×200 with deep earth color modules
- [ ] **TC-FR-55**: User display name shows below QR
- [ ] **TC-FR-56**: Copy ID chip shows truncated UUID (`first8chars…`), copies full ID on tap
- [ ] **TC-FR-57**: "Share Profile Code" button triggers `SharePlus` with formatted message
- [ ] **TC-FR-58**: Loading state shows `CircularProgressIndicator` when userId is empty

### 4.8 Add Friend Dialog

- [ ] **TC-FR-59**: Dialog has 20px border radius, white background
- [ ] **TC-FR-60**: Title shows person_add icon + "Add Friend"
- [ ] **TC-FR-61**: Input supports display name, email, or User ID
- [ ] **TC-FR-62**: QR scanner icon in suffix when input is empty (opens scanner, closes dialog)
- [ ] **TC-FR-63**: Paste button in suffix when input is empty (pastes from clipboard)
- [ ] **TC-FR-64**: Clear button replaces suffix when input has text
- [ ] **TC-FR-65**: Live user preview appears after 350ms debounce with avatar, name, email
- [ ] **TC-FR-66**: Already-friends users show green "Friends ✓" label, Send disabled
- [ ] **TC-FR-67**: Pending users show amber "Pending" label
- [ ] **TC-FR-68**: "Send Request" button disabled when input empty or user is already friend
- [ ] **TC-FR-69**: Successful send shows "Friend request sent to {name}! 🎉"
- [ ] **TC-FR-70**: Error handling shows error via `AppFeedback.showError`
- [ ] **TC-FR-71**: Loading state shows `CircularProgressIndicator` while sending

---

## 5. FriendListItem — Integration Verification

- [ ] **TC-FLI-01**: Accepted friend shows avatar with online indicator dot (green glow when online)
- [ ] **TC-FLI-02**: Online status text shows `presenceStatusText` with appropriate color
- [ ] **TC-FLI-03**: 3-dot menu on accepted friends opens options modal (Invite to Trip, Copy ID, Remove)
- [ ] **TC-FLI-04**: Incoming request shows "Wants to be your friend" subtitle
- [ ] **TC-FLI-05**: Incoming request action buttons: Decline (circle X) + Accept (coral pill)
- [ ] **TC-FLI-06**: Outgoing request shows "Request pending approval" + Cancel button
- [ ] **TC-FLI-07**: Search mode — `FriendStatus.none` shows "Add" button (coral pill)
- [ ] **TC-FLI-08**: Search mode — `FriendStatus.accepted` shows "Friends" badge (green)
- [ ] **TC-FLI-09**: Search mode — `FriendStatus.pending` shows "Requested" badge (amber)
- [ ] **TC-FLI-10**: Loading state shows `CircularProgressIndicator` during async operations

---

## 6. Cross-Cutting Concerns

### 6.1 Error Handling

- [ ] **TC-CC-01**: Network failure on friend search shows error text (not crash)
- [ ] **TC-CC-02**: QR scanner permission denial handles gracefully
- [ ] **TC-CC-03**: Empty clipboard paste is a no-op (does not error)

### 6.2 State Management

- [ ] **TC-CC-04**: `_refreshAll()` invalidates `friendsProvider`, `incomingRequestsProvider`, `outgoingRequestsProvider`
- [ ] **TC-CC-05**: `searchUsersProvider(_searchQuery)` auto-disposes when search tab is left
- [ ] **TC-CC-06**: Realtime presence updates friend online status without manual refresh

### 6.3 Navigation

- [ ] **TC-CC-07**: Back button from Friends screen works (Navigator.pop)
- [ ] **TC-CC-08**: Tab switching between My Friends → Requests → Find Friends is smooth
- [ ] **TC-CC-09**: Deep-linking from Home "Friends" tile lands on correct screen

---

## 7. UI Approval Checklist

> [!IMPORTANT]
> Each screen state below must be visually inspected on device/emulator and approved.

### Home Screen

| # | Screen State | Status |
|:--|:-------------|:-------|
| 1 | Quick Actions grid — 4 tiles visible, correct labels/icons | ⬜ Approve |
| 2 | "New trip" tile — coral gradient, white icon/text | ⬜ Approve |
| 3 | "Join trip" tile — white card, group_add icon | ⬜ Approve |
| 4 | "Friends" tile — white card, people icon, "Find & connect" | ⬜ Approve |
| 5 | "Navigate" tile — white card, with active trip sublabel | ⬜ Approve |
| 6 | "Navigate" tile — with no active trip sublabel | ⬜ Approve |
| 7 | Press animation — tiles scale down smoothly on press | ⬜ Approve |

### Friends Screen — My Friends Tab

| # | Screen State | Status |
|:--|:-------------|:-------|
| 8 | Empty state — icon, title, description, CTAs | ⬜ Approve |
| 9 | Populated list — filter chips, friend cards, presence dots | ⬜ Approve |
| 10 | Online filter active — filtered list, green chip highlighted | ⬜ Approve |
| 11 | Local search filter — text field visible (>4 friends) | ⬜ Approve |
| 12 | Friend options modal — Invite / Copy ID / Remove layout | ⬜ Approve |

### Friends Screen — Requests Tab

| # | Screen State | Status |
|:--|:-------------|:-------|
| 13 | Empty incoming — check icon + message | ⬜ Approve |
| 14 | Incoming request cards — avatar, subtitle, Accept/Decline buttons | ⬜ Approve |
| 15 | Outgoing request cards — avatar, subtitle, Cancel button | ⬜ Approve |
| 16 | Request badge count on tab | ⬜ Approve |

### Friends Screen — Find Friends Tab

| # | Screen State | Status |
|:--|:-------------|:-------|
| 17 | Discovery bar — 3 buttons (Scan QR / My QR / Add by ID) | ⬜ Approve |
| 18 | Discovery help banner — instructions visible | ⬜ Approve |
| 19 | Search results — user cards with status badges | ⬜ Approve |
| 20 | Empty search results — "No travelers found" | ⬜ Approve |

### Modals & Dialogs

| # | Screen State | Status |
|:--|:-------------|:-------|
| 21 | My QR Code modal — QR, name, copy chip, share button | ⬜ Approve |
| 22 | Add Friend dialog — input, live preview, Send button | ⬜ Approve |
| 23 | QR Scanner modal — camera view, instruction text | ⬜ Approve |

---

## 8. Sign-Off

| Role | Name | Date | Approved |
|:-----|:-----|:-----|:---------|
| Developer | | | ⬜ |
| UI/UX Review | | | ⬜ |
| QA | | | ⬜ |
