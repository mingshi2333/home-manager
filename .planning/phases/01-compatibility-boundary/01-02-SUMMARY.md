---
phase: 01-compatibility-boundary
plan: 02
subsystem: testing
tags: [nix, home-manager, nixgl, testing, jq]
requires:
  - phase: 01-01
    provides: compatibilityPolicies and appInventory exports
provides:
  - shell regression test for compatibility boundary coverage
  - policy export assertions for representative apps
  - ownership guardrails for session-level environment variables
affects: [phase-03, phase-04, phase-05, testing]
tech-stack:
  added: []
  patterns: [nix-eval boundary regression tests, jq-based export assertions]
key-files:
  created: [tests/compatibility-boundary.sh]
  modified: [tests/compatibility-boundary.sh]
key-decisions:
  - "Validated the compatibility boundary through nix eval JSON assertions instead of wrapper-text parsing or live GUI launches."
  - "Kept the ownership guard negative: app policies must not carry session-global portal or IME variables."
patterns-established:
  - "Pattern: Structural compatibility validation lives in tests/compatibility-boundary.sh and reads local.nixgl exports directly."
  - "Pattern: Policy tests assert raw app-defined fields, not derived wrapper defaults."
requirements-completed: [POLI-03, OTHR-01]
duration: 5min
completed: 2026-04-02
---

# Phase 1 Plan 2: Compatibility Boundary Summary

**Fast nix-eval regression coverage for full wrapped-app inventory, representative policy exports, and ownership boundaries**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-02T15:49:00Z
- **Completed:** 2026-04-02T15:54:32Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `tests/compatibility-boundary.sh` to verify full wrapped-catalog inventory coverage and the required four-state health model.
- Added representative assertions for Wayland and X11 policy exports, including the Zotero per-app IM override.
- Guarded the ownership split by failing if compatibility policy exports start carrying session-wide portal or IME variables.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create a boundary health test for inventory coverage and allowed states** - `40c5397` (test)
2. **Task 2: Add representative policy and ownership assertions to the boundary test** - `97169e8` (test)

## Files Created/Modified

- `tests/compatibility-boundary.sh` - Exercises the exported compatibility boundary through `nix eval` and `jq` assertions.

## Decisions Made

- Used `jq` against exported JSON to keep the test fast and scoped to the declarative boundary.
- Asserted that raw `extraFlags` remain app-authored values by checking that derived Wayland wrapper defaults are not re-exported as policy inputs.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Concurrent `nix eval` commands produced transient `eval-cache` SQLite busy warnings during parallel verification. Commands still completed successfully, so no code change was required.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later phases now have a repeatable structural regression test for the compatibility boundary.
- Inventory and policy regressions will fail before runtime debugging work begins.

## Self-Check: PASSED

- FOUND: `.planning/phases/01-compatibility-boundary/01-02-SUMMARY.md`
- FOUND: `40c5397`
- FOUND: `97169e8`

---
*Phase: 01-compatibility-boundary*
*Completed: 2026-04-02*
