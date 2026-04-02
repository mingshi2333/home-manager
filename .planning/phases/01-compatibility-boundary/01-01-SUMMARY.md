---
phase: 01-compatibility-boundary
plan: 01
subsystem: infra
tags: [nix, home-manager, nixgl, wayland, policy]
requires: []
provides:
  - app-catalog compatibility metadata for the wrapped GUI catalog
  - read-only local.nixgl compatibilityPolicies export
  - read-only local.nixgl appInventory export
affects: [phase-02, phase-03, phase-04, phase-05, testing]
tech-stack:
  added: []
  patterns: [catalog-derived compatibility metadata, read-only local.nixgl exports]
key-files:
  created: []
  modified: [nixgl-apps.nix, modules/nixgl-runtime.nix]
key-decisions:
  - "Kept platform, extraEnv, and extraFlags as the raw app-level launch inputs and derived policy records from them."
  - "Exported full-catalog inventory and policy maps through local.nixgl instead of pushing metadata recomputation into downstream modules."
patterns-established:
  - "Pattern: App-specific compatibility intent lives in nixgl-apps.nix beside each catalog entry."
  - "Pattern: Shared compatibility metadata is consumed through typed read-only local.nixgl exports."
requirements-completed: [POLI-01, POLI-02, POLI-03]
duration: 7min
completed: 2026-04-02
---

# Phase 1 Plan 1: Compatibility Boundary Summary

**App-catalog compatibility metadata with normalized policy and inventory exports for the Fedora KDE Wayland wrapped app set**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-02T15:42:38Z
- **Completed:** 2026-04-02T15:49:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added per-app compatibility health, scope, and notes metadata across the wrapped GUI catalog in `nixgl-apps.nix`.
- Derived normalized `compatibilityPolicies` and `appInventory` maps without changing wrapper generation or session-wide environment ownership.
- Exported the new metadata through read-only `config.local.nixgl.*` state for later validation and repair phases.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend the app catalog with explicit compatibility and health metadata** - `0979b61` (feat)
2. **Task 2: Export normalized compatibility policy and inventory through `local.nixgl`** - `f6d4cda` (feat)

## Files Created/Modified

- `nixgl-apps.nix` - Adds compatibility metadata normalization plus full-catalog policy and inventory derivation.
- `modules/nixgl-runtime.nix` - Exposes the new derived metadata through read-only `local.nixgl` options.

## Decisions Made

- Kept derived policy records limited to app-local launch inputs and host-scope metadata so session-wide portal and IME ownership stays in `modules/`.
- Included the full wrapped catalog in `appInventory`, not just enabled outputs used by packages and desktop entries.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `nix eval` emitted dirty-tree warnings because the repository already had unrelated user changes. Evaluation still succeeded.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Downstream validation can now inspect compatibility policy and health inventory directly from `config.local.nixgl`.
- Later repair phases have an explicit per-app policy boundary for `QQ`, `Zotero`, and the rest of the wrapped catalog.

## Self-Check: PASSED

- FOUND: `.planning/phases/01-compatibility-boundary/01-01-SUMMARY.md`
- FOUND: `0979b61`
- FOUND: `f6d4cda`

---
*Phase: 01-compatibility-boundary*
*Completed: 2026-04-02*
