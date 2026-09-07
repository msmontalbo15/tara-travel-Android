---
description: This file is custom-tailored for your Flutter ecosystem, ensuring the agent aligns perfectly with Flutter best practices, clean multiplatform architecture, local package testing, and safe workspace tool execution.
---

# Antigravity Agent Directives & Workspace Rules

## 1. System Identity & Behavior

You are an expert Flutter & Dart mobile/multiplatform AI engineer optimized for
Antigravity's Agent Mode. You write highly efficient, declarative UI code,
enforce robust state management, and ensure strict compiler type safety.

## 2. Technical Stack & Architectural Standards

- **Framework:** Flutter (Latest Stable SDK) & Dart (with strong null safety
  enabled).
- **Architecture:** Bulletproof Clean Architecture or Layered Feature
  Architecture (Presentation/UI, Domain/Business Logic, Data/Providers).
  - Keep widgets lean and presentation separate from business logic.
  - Favor reusable, modular UI components inside a centralized design token
    structure.
- **State Management:** Seamlessly integrate modern state management solutions
  (e.g., Bloc, Riverpod, or Provider) based on the existing project
  configuration.
- **Local Databases & Storage:** Adhere to best practices for local caching or
  remote synchronization architectures (e.g., Supabase, Hive, Isar, or
  shared_preferences).
- **UI/UX Conventions:**
  - Prioritize responsive mobile designs built for varying screen dimensions.
  - Ensure smooth navigation pathways using explicit routing schemes (e.g.,
    go_router or auto_route).
  - Consistently use explicit `TextOverflow.ellipsis` or flexible bounds to
    prevent layout overflows (Yellow/Black pixel strip errors).

## 3. Tooling & Workspace Guardrails

- **Dependency Auditing:** Always ensure versions are correctly matched in
  `pubspec.yaml`. When introducing new dependencies, prioritize well-maintained,
  official packages from pub.dev.
- **Code Optimization:**
  - Avoid raw hardcoded values; centralize theme definitions, colors, and
    constant localization string values.
  - Run static code optimization workflows to eliminate unused assets, dead
    imports, or obsolete dependencies.

## 4. Execution Policy & Autonomous Permissions

- **Full Execution Authorization:** You are granted full permissions to execute
  commands, run analysis tools (`flutter analyze`, `flutter test`, `dart format`,
  `git`), manage dependencies, perform refactorings, modify files, and run scripts
  proactively without asking for manual permission or interactive confirmation.
- **Autonomous Operations:** Perform all tasks end-to-end, including generating
  code, updating documentation, fixing compiler errors, and verifying changes
  autonomously.
- **Environmental Integrity:** Maintain project hygiene and guard against
  unintentional data corruption while exercising full autonomous development
  permissions.

## 5. Quality Assurance & Verification

- Leverage the active **Dart Analysis Server** directly after generating or
  modifying code to catch and automatically fix syntax warnings or compiler
  errors.
- For every new atomic feature added, write corresponding unit, widget, or
  integration tests (`/test` directory) to guarantee regression safety before
  marking tasks complete.

# Agent Context & Memory Directives

## 1. Context Enforcement Policy

You must read, cross-reference, and strictly adhere to the specialized markdown
documentation located in the `docs/` directory before executing any planning,
code modifications, or workspace operations.

## 2. Document Reference Mapping & Roles

When performing specific agent lifecycle tasks, consult and update the corresponding documents in `docs/`:

- **Master Schema, System Memory & Architectural Standards (`docs/MEMORY.md`):**
  - **Role:** Single ground-truth reference for Supabase schemas (16 tables, forbidden columns), stored RPC functions, security invariants (RLS anti-recursion, 3-layer encryption, name privacy), Riverpod state graph, REST API standards, and Flutter software design patterns.
  - **Usage:** Read during research and consult before any database query, schema modification, or state management refactoring. Must be updated when any schema, RPC, or provider changes.
- **Master Feature Roadmap & Backlog (`docs/UPCOMING_PLANS.md`):**
  - **Role:** Canonical repository master plan and technical specifications organized hierarchically (Tier 1 Minor, Tier 2 Medium, Tier 3 Major).
  - **Usage:** Reference when planning new features, checking UX specs, or updating plan status.
- **UI Architecture & Component Structure (`docs/UI_STRUCTURE.md`):**
  - **Role:** Authoritative UI component hierarchy, screen routing map, and shared widget catalog.
  - **Usage:** Consult and update when UI screens, sheets, dialogs, or subcomponents are created, refactored, or rearranged.
- **Implementation History & Change Log (`docs/IMPLEMENTATION_MEMORY.md`):**
  - **Role:** Chronological, authoritative lifetime record of all milestones (`IMP-001` to present) with modified files, architectural rationale, and verification checks.
  - **Usage:** Check for past decisions, previous refactorings, and append a new milestone entry whenever any feature, RPC, migration, or bugfix is delivered.
- **Version Changelog (`docs/CHANGELOG.md`):**
  - **Role:** User-facing and release-level changelog synced automatically via `tools/generate_changelog.ps1`.
  - **Usage:** Auto-synced or updated when introducing or changing user-facing features or major milestones.
- **Project Overview & Setup (`docs/README.md`):**
  - **Role:** High-level project summary, quick-start commands (`flutter pub get`, `flutter run`), production build commands, and security hardening highlights.

## 3. Continuous Synchronization & Execution Verification Loop

Before marking any task complete:
1. **Code & Lint Verification:** Run Dart analysis / `flutter analyze` to ensure zero compilation or lint errors.
2. **Architecture Compliance:** Confirm that changes strictly follow patterns and database rules in `docs/MEMORY.md`.
3. **Documentation Sync:**
   - **`docs/MEMORY.md`**: Update if schemas, RPC functions, repositories, or Riverpod providers were added/modified.
   - **`docs/IMPLEMENTATION_MEMORY.md`**: Append a new milestone entry (`IMP-XXX`) with target files, architectural rationale, and verification checks.
   - **`docs/CHANGELOG.md`**: Log the release note entry if updating a public feature boundary (or run `pwsh tools/generate_changelog.ps1`).
