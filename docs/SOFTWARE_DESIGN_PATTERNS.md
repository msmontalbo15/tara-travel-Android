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

## 🔒 Security & Data Integrity Invariants

1. **Zero Hardcoded Secrets**: All backend URLs, API keys, and OAuth client IDs are loaded dynamically at runtime via `.env` through `flutter_dotenv`.
2. **Deterministic Input Sanitization**: All client parameters, invite codes, and user input strings must be trimmed, normalized, and validated prior to SQL execution.
3. **Database-Level RLS Anti-Recursion**: Postgres security policies must never recursively query the target relation directly; always delegate permission checks to `SECURITY DEFINER` helper functions.
