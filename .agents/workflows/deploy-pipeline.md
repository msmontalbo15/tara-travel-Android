---
description: Generates a secure, production-ready GitHub Actions CI/CD workflow (.github/workflows/deploy.yml) with test gates, security scanning, and container/Android builds.
---

# Deploy Pipeline Workflow

When triggered via `/deploy-pipeline`:

1. **Verify Workspace Prerequisites**:
   - Check existing project structure (backend, Flutter/Android, Dockerfiles, IaC).
   - Verify environment secret names required for deployment.

2. **Generate `.github/workflows/deploy.yml`**:
   - Multi-stage Docker build pipeline using non-root base images.
   - Enforce an 80% unit test coverage gate (build fails if coverage drops below 80%).
   - Continuous dependency and vulnerability scanning (e.g., Trivy / Snyk / CodeQL).
   - Signed Android App Bundle (`.aab`) compilation with ProGuard/R8 obfuscation.
   - Declarative IaC (Terraform) validation and security checks (`tflint`, `tfsec`).

3. **Validation**:
   - Run workflow linter or dry-run validation against syntax and action versions.
