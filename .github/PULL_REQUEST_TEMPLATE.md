## Milestone ID
<!-- IMP-XXX -->

## Summary
<!-- Paste the IMPLEMENTATION_MEMORY.md entry for this milestone here -->

## Modified Files
<!-- List the files changed in this PR -->
-

## Schema / Architecture Compliance
- [ ] No forbidden columns queried (see `architecture-memory.md` rules)
- [ ] No RLS recursion on `trip_members`
- [ ] Helper functions used for access checks (`is_trip_member`, `user_owns_trip`, `user_can_access_trip`)
- [ ] Name privacy invariant respected (`MemberModel.formatDisplayName`)

## Memory Sync
- [ ] `MEMORY.md` updated (schemas, RPCs, providers)
- [ ] `IMPLEMENTATION_MEMORY.md` entry appended (IMP-XXX)

## Verification
- [ ] Manual test passed on device/emulator
- [ ] No lint errors (`flutter analyze`)
- [ ] No regression in existing flows
