---
description: Generates a hardened, multi-stage Dockerfile adhering to non-root execution, distroless/minimal base images, and layer caching.
---

# Secure Docker Workflow

When triggered via `/secure-docker`:

1. **Multi-Stage Build**:
   - Decouple build-time compilers/SDKs from runtime environment.
2. **Minimal Base Image**:
   - Use hardened minimal base images (e.g., `alpine`, `gcr.io/distroless`).
3. **Non-Root Execution**:
   - Explicitly declare and switch to a non-root system user and group (e.g. `USER nonroot` or dedicated UID/GID).
4. **Cache Optimization**:
   - Copy dependency manifests (`pubspec.yaml`, `package.json`, `go.mod`, etc.) before copying full application source code.
5. **Runtime Health & Signals**:
   - Include `HEALTHCHECK` directive and handle PID 1 graceful shutdown signal forwarding.
