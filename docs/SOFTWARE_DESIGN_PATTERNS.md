# 📐 Agent Memory: REST API Best Practices & Architecture Standards
> **NON-NEGOTIABLE ARCHITECTURAL & SOFTWARE DESIGN STANDARDS**  
> **Status**: Production Standard  
> **Scope**: REST API Design, Mobile & Backend Software Patterns, Data Layer Contracts, Error Envelopes, and Security Protocols.

---

## 🛠️ Core API Design Guidelines

### 1. Versioning
* **Standard:** Use explicit URL path versioning (e.g., `/v1/users` -> `/v2/users`).
* **Rule:** Never apply breaking changes to an active API version. Deprecate older routes gracefully while maintaining backward compatibility.

### 2. Pagination
* **Standard:** Set default page sizes and strict max limits (e.g., `limit=20`, `max=100`).
* **Rule:** Never allow un-paginated queries over large data collections (`SELECT *`). Always return pagination metadata (total, limit, offset/cursor).

### 3. Rate Limiting
* **Standard:** Return standard status code `429 Too Many Requests` when rate limits are exceeded.
* **Rule:** Always attach rate-limiting headers (`X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`) to incoming API responses.

### 4. Idempotency Keys
* **Standard:** Accept `Idempotency-Key` headers for mutating requests (`POST`, `PATCH`, `PUT`).
* **Rule:** Prevent accidental double-processing on network retries by checking and locking key IDs in cache (e.g., Redis).

### 5. HATEOAS (Hypermedia as the Engine of Application State)
* **Standard:** Embed explicit action metadata/links (`_links`) in responses where appropriate.
* **Rule:** Inform the client about allowed next actions dynamically directly inside the payload (e.g., payment submission URLs, cancel actions).

### 6. Meaningful Status Codes
* **Standard:** Match HTTP response codes directly to request outcomes.
* **Rule:** **Never** return a `200 OK` status with an embedded error payload like `{ "error": true }`. Use proper 4xx/5xx status codes (`400`, `401`, `403`, `404`, `429`, `500`).

### 7. Filtering + Sorting
* **Standard:** Support query parameters for collection subsets (e.g., `/users?status=active&sort=-created_at`).
* **Rule:** Execute filtering and sorting on the database side before returning results; never filter firehose streams on the client side.

### 8. Consistent Naming
* **Standard:** Use plural nouns for resources (e.g., `/users`) and lowerCamelCase or snake_case consistently across all endpoints.
* **Rule:** Avoid mixing verbs in path definitions (e.g., prefer `GET /users` over `GET /getUser` or `POST /user_list`).

### 9. Auth in Headers
* **Standard:** Send tokens explicitly via `Authorization: Bearer <token>` HTTP headers.
* **Rule:** **Never** pass API keys or sensitive session tokens inside URL query strings, as URLs are routinely stored in web server logs, browser history, and referrers.

### 10. Error Envelopes
* **Standard:** Standardize error response payloads across all endpoints.
* **Rule:** Always return a structured JSON error body containing predictable fields:
  ```json
  {
    "error": {
      "code": "INVALID_INPUT",
      "message": "Email is required.",
      "details": []
    }
  }
  ```

---

## 🏛️ Application Software Design Patterns (Flutter & Dart)

### 1. Repository Pattern (Remote Single Source of Truth)
* **Standard:** Decouple data access logic from presentation components.
* **Rule:** Presentation widgets must never execute direct database or HTTP calls. All data retrieval and mutations must pass through typed domain repositories (`TripRepository`, `ExpenseRepository`, `ProfileRepository`, `AuthRepository`).

### 2. MVI / MVVM State Management (Riverpod Notifiers)
* **Standard:** Model all UI states as immutable, unidirectional data streams.
* **Rule:** UI components react strictly to state changes (`AsyncValue`, `StateNotifier`, `Notifier`). Side effects are triggered through deterministic notifier methods, never through mutable global variables.

### 3. Write-Through Local Caching with TTL Stamps
* **Standard:** Cache remote payloads locally in Sembast document stores with explicit timestamp invalidation.
* **Rule:** High-frequency collections (Chat Messages, Expenses, Itinerary Stops) write through to local storage to provide instant offline rendering, updating cache freshness stamps (`SessionCacheService.stamp()`).

### 4. Partitioned Multitenancy (Per-User Storage Isolation)
* **Standard:** Isolate local SQLite / Sembast database files per authenticated user UUID.
* **Rule:** Switching accounts must immediately close active database locks and mount `tara_travel_<user_id>.db` via `DatabaseService.instance.switchUser(userId)` to prevent cross-account data leakage.

### 5. Circuit Breaker & Offline Sync Queue (FIFO Resiliency)
* **Standard:** Isolate network mutation failures during network loss into a durable offline queue.
* **Rule:** Failed writes are serialized into `OfflineSyncQueue` (`offline_queue` store) and replayed in FIFO order with exponential backoff retries when `ConnectivityService` detects an online state.

### 6. Defense-in-Depth 3-Layer Encryption Pipeline
* **Standard:** Encrypt sensitive Personally Identifiable Information (PII) at rest and in transit.
* **Rule:** Asymmetric RSA-2048 key exchange + Symmetric AES-256-GCM data encryption + Transport Layer Security (TLS 1.3). Keys are protected exclusively inside Android Keystore / iOS Keychain.

---

## 📱 Mobile Responsive Layout & Overflow Prevention Patterns (Flutter & Mobile UI)
> **MANDATORY INVARIANT: Every screen and modal must be responsive to any mobile screen size and strictly immune to layout overflows (`RenderFlex` overflow errors / yellow-and-black stripes).**

### 1. Universal Screen Boundary Rule: Scrollable Viewports
* **Standard:** Wrap all vertical or variable-length layouts in a scrollable container.
* **Rule:** Never assume a fixed vertical screen height. Always use `SingleChildScrollView`, `ListView`, or `CustomScrollView` on form screens, modal bottom sheets, onboarding flows, and detail views.
* **Keyboard Awareness:** Ensure `SingleChildScrollView` or `Scaffold.resizeToAvoidBottomInset: true` is paired with adequate bottom padding or `MediaQuery.of(context).viewInsets.bottom` so inputs are never occluded by the virtual keyboard.

### 2. Flexible & Expanded Column / Row Constraints
* **Standard:** Inside `Row` and `Column` widgets, dynamic children must be bounded.
* **Rule:** 
  * In a `Row`, any dynamic text, label, or variable-width child **must** be wrapped in `Expanded` or `Flexible` with `overflow: TextOverflow.ellipsis` to prevent horizontal render overflow on narrow devices (e.g., 320px–360px viewport widths).
  * Never place an unbounded `ListView` or `SingleChildScrollView` directly inside a `Column` without wrapping it in an `Expanded` or `Flexible` widget.

### 3. Safe Dynamic Typography & Text Overflow Defense
* **Standard:** Typography must follow the canonical brand font pairing and gracefully handle accessibility font scaling (large system text sizes) and multi-locale string lengths.
* **Brand Font Hierarchy:**
  * **DM Sans** (`font-dm-sans`): Primary font, applied as the default body font (`ThemeData.fontFamily`), UI labels (Medium), and body copy (Regular).
  * **Playfair Display** (`font-playfair` / `font-heading`): Decorative serif mapped for headings/display text (`AppTextStyles.headline1`-`3`, `tagline`, AppBar and Dialog titles).
  * **Georgia (serif)**: Used as a direct inline fallback in designated display locations (loading splash "Tara TRAVEL" logo and Home greeting name).
* **Rule:**
  * Always provide explicit `overflow: TextOverflow.ellipsis` and `maxLines` on single-line or bounded multi-line text.
  * For critical buttons or headers, wrap with `FittedBox(fit: BoxFit.scaleDown)` or allow multi-line wrapping instead of hardcoding fixed container widths.
  * Clamp text scaling where extreme system accessibility zoom would completely break critical navigation actions using `MediaQuery.withClampedTextScaling(...)`.

### 4. Adaptive & Proportional Sizing (No Hardcoded Viewport Assumptions)
* **Standard:** Layouts must dynamically calculate spatial budgets using responsive breakpoints and constraints.
* **Rule:**
  * Use `LayoutBuilder` or `BoxConstraints` to adapt layouts based on parent constraints rather than relying purely on static dimensions.
  * For split-view or grid items, calculate item aspect ratios or column counts adaptively based on available width:
    ```dart
    int crossAxisCount = constraints.maxWidth > 600 ? 3 : (constraints.maxWidth > 340 ? 2 : 1);
    ```
  * Avoid hardcoded fixed widget widths (e.g., `width: 380`) on mobile screens; prefer percentages, flex factors (`Expanded`), or relative sizing (`MediaQuery.sizeOf(context).width`).

### 5. Safe Area Ingestion & Notch / Gesture Navigation Insets
* **Standard:** Content must respect device hardware cutouts, camera notches, dynamic islands, and OS gesture bars.
* **Rule:** Always wrap top-level body content or edge-anchored floating bars in `SafeArea` or consume `MediaQuery.paddingOf(context)` / `viewPadding`.
* **Modal Bottom Sheets:** Always set `isScrollControlled: true` and wrap bottom sheet content with `SafeArea` and scroll bounds to prevent overflow on compact or landscape mobile orientations.

### 6. Dynamic Card & Content Wrapping
* **Standard:** Tag groups, filter chips, action button groups, and badge lists must adapt to arbitrary horizontal sizes.
* **Rule:** Use `Wrap` with `spacing` and `runSpacing` instead of `Row` for dynamic chip collections, tags, or button bars that could exceed the screen width.

---

## 🧩 Component Reuse & Anti-Duplication Standards (DRY UI Architecture)
> **MANDATORY INVARIANT: Always reuse existing design-system components instead of building one-off, hardcoded widgets. Duplicate widget logic, ad-hoc styling, and redundant dialog/input implementations are strictly forbidden.**

### 1. Pre-Flight Component Audit Rule
* **Standard:** Before creating any new UI widget, inspect `lib/core/widgets/` and existing feature components.
* **Rule:** If a design requirement overlaps with an existing component, you **must** import and compose the existing component or extend it via clean parameters. Never rewrite one-off equivalents.

### 2. Canonical Shared Components Catalog
Whenever implementing screens or modals, utilize these canonical implementations:
* **Buttons & Navigation:**
  * [`AppBackButton`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/buttons/app_back_button.dart): Canonical 12px brand back button with `glass`, `light`, `brand`, and `ghost` variants. Never use raw `IconButton(icon: Icon(Icons.arrow_back))` or ad-hoc containers.
  * [`DynamicIslandPill`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/dynamic_island_pill.dart): Status and glanceable pill badges.
* **Feedback, Dialogs & Alerts:**
  * [`AppFeedback`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_feedback.dart): Unified snackbar/toast toasts (`showSuccess`, `showError`, `showWarning`, `showInfo`).
  * [`AppDialog`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_dialog.dart): Standardized modal alert/confirmation dialogs. Never invoke raw `showDialog` with custom ad-hoc `AlertDialog` containers.
  * [`AppBanner`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/feedback/app_banner.dart): In-page status alerts and banners.
* **Inputs & Form Controls:**
  * [`AppTextField`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/app_text_field.dart): Standard text entry with brand borders, 12px radius, and focus states.
  * [`AppNumericField`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/app_numeric_field.dart): Currency and numeric inputs with built-in validation.
  * [`AppDropdown`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/app_dropdown.dart): Styled form select menus.
  * [`AppDatePicker`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/app_date_picker.dart) & [`TaraDateRangePicker`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/tara_date_range_picker.dart): Standard brand date and date-range pickers.
  * [`LocationPicker`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/location_picker.dart) & [`MapPinPickerModal`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/inputs/map_pin_picker_modal.dart): Philippine address & GPS geocoding inputs.
* **Loading & Surfaces:**
  * [`ShimmerLoading`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/shimmer_loading.dart): Universal skeleton loaders (`ShimmerBox`, `ShimmerCard`, `ShimmerCircle`). Never use static spinners or un-themed progress bars where skeleton loading applies.
  * [`GlassCard`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/glass_card.dart): Frosted backdrop cards.
* **Shared Feature Carousels & Sheets:**
  * [`TripTypeCarousel`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/trip_color_carousel.dart): Canonical trip type selector across Create and Edit flows.
  * [`MultiMemberPickerSheet`](file:///d:/Spencer/Downloads/tara_travel/lib/core/widgets/multi_member_picker_sheet.dart): Shared group member selection for expenses, packing, and roles.

### 3. Centralized Brand Tokens
* **Rule:** Never hardcode colors (`Color(0xFF...)`), text styles (`TextStyle(...)`), or corner radii in feature files. Always consume:
  * [`AppColors`](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_colors.dart) (`primary`, `secondary`, `sand`, `sunset`, `deepEarth`, `warmWhite`, `cardBorder`, etc.)
  * [`AppTextStyles`](file:///d:/Spencer/Downloads/tara_travel/lib/core/theme/app_text_styles.dart) (Playfair Display headlines, DM Sans body and labels)
  * Design tokens from `0_Brand identity.html` (strictly 12px corner radii for buttons & inputs, 20px pill badges).

---

## 🔒 Security & Data Integrity Invariants

1. **Zero Hardcoded Secrets**: All backend URLs, API keys, and OAuth client IDs are loaded dynamically at runtime via `.env` through `flutter_dotenv`.
2. **Deterministic Input Sanitization**: All client parameters, invite codes, and user input strings must be trimmed, normalized, and validated prior to SQL execution.
3. **Database-Level RLS Anti-Recursion**: Postgres security policies must never recursively query the target relation directly; always delegate permission checks to `SECURITY DEFINER` helper functions.
4. **Zero Layout Overflow Tolerance**: All production Flutter builds must undergo rigorous multi-device verification (compact 320px–360px phones, tall notch phones, and large display zoom settings) with zero unhandled `RenderFlex` exceptions.
5. **Zero Hardcoded Component Duplication**: Reject duplicate one-off UI implementations; all views must strictly compose reusable components from `lib/core/widgets/` and theme tokens from `lib/core/theme/`.


