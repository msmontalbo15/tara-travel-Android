# Tara Travel Markdown-Guided Audit and Remediation Prompt

```text
Audit and remediate the Tara Travel Flutter repository against every applicable rule in the repository’s Markdown guidance.

Before making changes, read and follow:

- .agents/workflows/run.md
- .agents/rules/architecture-memory.md
- .agents/rules/brand-identity.md
- docs/Analyze.md
- docs/MEMORY.md
- docs/SOFTWARE_DESIGN_PATTERNS.md
- docs/IMPLEMENTATION_MEMORY.md
- docs/DEV_IDEA.md
- docs/UPCOMING_PLANS.md
- docs/CHANGELOG.md

Remediate these known findings:

1. Replace wildcard Supabase queries in TripRepository.
   - Remove select('*').
   - Explicitly list only supported columns from the documented schema.
   - Replace nested trip_members(*), users(*), and expenses(*) selections with explicit safe column lists.
   - Do not query any forbidden columns listed in architecture-memory.md.
   - Preserve the current TripModel parsing behavior and all existing trip/member/expense functionality.

2. Review all Supabase migrations for active violations of the architecture rules.
   - Ensure final active RLS policies never directly query trip_members from a trip_members policy.
   - Use public.is_trip_member, public.user_owns_trip, and public.user_can_access_trip.
   - Do not break migration ordering or existing deployed databases.
   - Treat historical migrations carefully; do not rewrite already-applied migrations unless there is a clear safety reason.
   - If a historical migration is misleading or unsafe for fresh setup, add a precise corrective migration or update documentation instead.

3. Resolve schema and documentation drift.
   - Update docs/MEMORY.md, docs/Analyze.md, and related documentation so they accurately describe the current schema and implementation.
   - Clearly distinguish historical migration columns from the final active schema.
   - Remove or correct obsolete claims about Sembast/offline infrastructure if that implementation is not present.
   - Do not invent schemas, providers, RPCs, or services.

4. Reuse the existing name privacy helper.
   - Refactor effectiveNameForPeers to reuse MemberModel.formatDisplayName.
   - Preserve the exact current privacy behavior.

5. Synchronize implementation documentation.
   - Append a new correctly numbered milestone to docs/IMPLEMENTATION_MEMORY.md.
   - Update docs/CHANGELOG.md only if the changes are user-facing or architectural.
   - Update docs/Analyze.md if file counts, architecture, providers, repositories, or schema indexes changed.
   - Keep documentation links and paths correct for this repository.

6. Preserve unrelated user changes.
   - Inspect git status first.
   - Do not revert or overwrite existing modifications that are unrelated to this task.
   - Do not modify generated files unless required by the implementation.

Implementation requirements:

- Follow the existing Flutter/Riverpod architecture.
- Keep TripRepository as a direct Supabase repository without introducing a local trip cache.
- Use explicit types and avoid unnecessary casts.
- Do not add broad catches, silent fallbacks, or speculative dependencies.
- Preserve existing UX and behavior.
- Use centralized theme tokens and existing reusable widgets.
- Add or update focused tests only where an existing test structure supports them.

Verification requirements:

- Run flutter analyze.
- Run the smallest relevant existing tests.
- If flutter test is blocked by the Windows toolchain, report the exact environment failure without treating it as an application test failure.
- Search again for forbidden Supabase columns, wildcard repository queries, recursive RLS policies, direct friendships usage, and duplicate name-formatting logic.
- Review the final diff for unrelated changes.

At the end, report:

- Files changed.
- Findings fixed.
- Findings intentionally left as historical migration context.
- Validation commands and results.
- Any remaining risks or follow-up recommendations.
```
