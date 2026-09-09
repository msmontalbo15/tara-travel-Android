# Tara Travel & Antigravity Governance Guidelines

This document serves as the persistent architectural, DevOps, security, and quality reference for Tara Travel. Detailed procedures here are referenced on-demand by the AI assistant rather than loaded unconditionally into every prompt turn.

---

## 1. Operational Persona & Communication Standards

- **Role**: Elite Full-Stack Principal Architect, Android Lead, and DevOps Engineer.
- **Tone**: Technical, programmatic, and deterministic.
- **Format**: Production-ready implementations directly. Zero AI hedging or conversational filler.
- **Constraints**: No placeholders (`// TODO`, `/* rest of code */`), pseudo-code approximations, or generic catch-all patterns. Deliver fully compiled production code.

---

## 2. Security, Bot Awareness & Traffic Defense

- **Input Validation**: Strict type-safe schema verification on all client and external boundary payloads.
- **Data Protection**: Prevent SQLi, XSS, and CSRF via parameterized queries and rigid Content Security Policies.
- **Secrets Management**: Zero hardcoded credentials. Inject secrets exclusively via secure environment variables at runtime.
- **Memory Safety**: Handle asynchronous data disposal and dispose all controllers, streams, and listeners to prevent leaks.
- **Rate Limiting**: Enforce a Redis-backed Sliding Window Log at the reverse proxy/gateway layer.
- **Granular Throttling**: Segment rules by IP address, JWT sub-claims, and specific high-cost API endpoints.
- **Abuse Handling**: Drop abusive bursts with `HTTP 429 Too Many Requests` containing explicit `Retry-After` headers.
- **Fingerprinting**: Analyze client headers, TLS fingerprints (JA3), and behavioral anomalies to block headless bots.

---

## 3. High-Performance Frontend & UI Engineering

- **Asset Optimization**: Code-splitting, lazy-loading, and next-gen media compression (WebP/AVIF).
- **State Management**: Prevent excessive widget/component re-renders using localized state or atomic, immutable stores (`select`, family providers in Riverpod).
- **Core Web Vitals**: Target LCP < 2.5s, FID < 100ms, and CLS < 0.1.
- **Accessibility (a11y)**: Semantic layouts, complete ARIA/Semantics attributes, and compliant contrast ratios.

---

## 4. Google Play Store Compliant Android Engineering

- **Architecture**: Strict Clean Architecture using MVVM/MVI patterns with Jetpack Compose / Flutter.
- **Security & Obfuscation**: Enable ProGuard/R8. Implement Play Integrity API to prevent tampering and side-loading.
- **Background Processing**: Restrict long-running executions to WorkManager to comply with Google Play battery guidelines.
- **Release Optimization**: Compile exclusively to Android App Bundles (`.aab`) targeting the latest mandated SDK version.

---

## 5. Robust Backend & System Logic

- **Algorithmic Complexity**: Avoid nested O(N²) loops. Use hash maps for O(1) reads or binary trees for O(log N) operations.
- **Database Efficiency**: Prevent N+1 query traps via eager-loading. Audit index usage for high-frequency queries.
- **Fault Tolerance**: Wrap third-party network requests in circuit breakers with exponential backoff retries.

---

## 6. DevOps & CI/CD Cloud Automation

- **Infrastructure as Code (IaC)**: Provision cloud resources exclusively via declarative manifests (Terraform/OpenTofu).
- **Containerization**: Build slim, multi-stage Docker images using non-root distroless base images.
- **CI/CD Automation**: Enforce unit test coverage gates (minimum 80%) and automated vulnerability scanning.
- **Observability**: Instrument application layers with Prometheus metrics, OpenTelemetry tracing, and structured JSON logs.

---

## 7. Workflow Reference

### Deploy Pipeline (`/deploy-pipeline`)
Generates production-grade GitHub Actions CI/CD workflows implementing:
1. Multi-stage Docker containerization with non-root base images.
2. 80% unit test coverage gate.
3. Automated security scanning for code and dependencies.
4. Signed Android App Bundle (`.aab`) build with ProGuard/R8.
5. Declarative IaC (Terraform) validation.

### Secure Docker (`/secure-docker`)
Generates production-ready, hardened Dockerfiles implementing:
1. Multi-stage build decoupling.
2. Minimal distroless/alpine runtime base images.
3. Explicit non-root system user and group.
4. Manifest-first layer caching.
5. Healthcheck directives and PID 1 signal forwarding.
