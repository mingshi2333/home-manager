---
phase: 03-qq-and-electron-stabilization
plan: 01
subsystem: ui
tags: [qq, electron, nixgl, xwayland, wayland, home-manager]

# Dependency graph
requires:
  - phase: 02-session-validation
    provides: reusable session validation probes and launch-path evidence
provides:
  - QQ default wrapper surfaces pinned to an exported xwayland-safe Electron profile
  - Explicit `qq-wayland-test` launch surface generated from the same app catalog entry
  - Reusable Electron repair profile metadata exported through `local.nixgl`
  - Regression coverage for profile metadata, surface parity, and session-env ownership
affects: [03-02, phase-04, electron-apps]

# Tech tracking
tech-stack:
  added: []
  patterns: [profile-aware app-catalog rendering, app-level electron backend ownership]

key-files:
  created: []
  modified: [nixgl-apps.nix, modules/nixgl-runtime.nix, modules/environment.nix, tests/compatibility-boundary.sh]

key-decisions:
  - "Kept Electron backend selection inside nixgl-apps.nix profiles and removed repo-wide session forcing from modules/environment.nix."
  - "Modeled QQ as default plus explicit opt-in profile surfaces generated from one catalog record instead of adding a QQ-only downstream branch."

patterns-established:
  - "Electron profile variants are rendered as first-class app surfaces from one app catalog entry."
  - "local.nixgl remains the only exported metadata boundary for compatibility policy, inventory, and profile presets."

requirements-completed: [QQEL-01, QQEL-03]

# Metrics
duration: 15 min
completed: 2026-04-02
---

# Phase 3 Plan 1: QQ Electron Profile Boundary Summary

**QQ now defaults to an exported xwayland-safe Electron profile, keeps an explicit `qq-wayland-test` surface, and exposes reusable profile metadata through `local.nixgl`.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-02T21:01:57Z
- **Completed:** 2026-04-02T21:17:09Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added reusable Electron repair profile presets in [nixgl-apps.nix](/home/mingshi/.config/home-manager/nixgl-apps.nix) and moved QQ to a safe XWayland default.
- Exported profile-aware compatibility and inventory metadata plus preset definitions through [modules/nixgl-runtime.nix](/home/mingshi/.config/home-manager/modules/nixgl-runtime.nix).
- Removed global Electron backend forcing from [modules/environment.nix](/home/mingshi/.config/home-manager/modules/environment.nix) while keeping portal and XDG session wiring intact.
- Updated [tests/compatibility-boundary.sh](/home/mingshi/.config/home-manager/tests/compatibility-boundary.sh) to lock the Phase 3 profile boundary and parity guarantees.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define reusable Electron repair profiles and move QQ to a safe default** - `f442bd9` (feat)
2. **Task 2: Add regression coverage for profile metadata and surface parity** - `4ad7f2b` (test)

## Files Created/Modified
- `nixgl-apps.nix` - Added reusable Electron profile presets, profile-aware metadata, and QQ default/test rendered surfaces.
- `modules/nixgl-runtime.nix` - Exported `local.nixgl.electronRepairProfiles` alongside existing compatibility and inventory outputs.
- `modules/environment.nix` - Removed global `ELECTRON_OZONE_PLATFORM_HINT` and `NIXOS_OZONE_WL` ownership.
- `tests/compatibility-boundary.sh` - Added assertions for QQ safe default, explicit Wayland test surface, profile metadata parity, and session-env ownership.

## Decisions Made
- Kept app-specific Electron backend policy in the app catalog instead of moving it into session modules, because Phase 1 already established app-level compatibility ownership.
- Rendered QQ profile variants into the same alias/bin/desktop/inventory pipeline as normal apps, so future Electron adopters can reuse the same mechanism without downstream special cases.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected rendered app exports after introducing multi-surface profile output**
- **Found during:** Task 1
- **Issue:** The first profile-aware rendering pass left `enabledApps` and some rendered app keys misaligned with the new surface model, which broke inventory coverage checks.
- **Fix:** Switched rendered exports to a merged attrset built from `listToAttrs` records and exported `enabledApps` from rendered surfaces instead of raw catalog IDs.
- **Files modified:** `nixgl-apps.nix`
- **Verification:** `bash tests/compatibility-boundary.sh`
- **Committed in:** `f442bd9`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix was required to keep the new profile boundary consumable through existing `local.nixgl` outputs. No scope creep.

## Issues Encountered

- The first implementation pass surfaced several Nix shape and export mismatches while converting catalog entries from one-surface outputs to rendered profile surfaces. Each was fixed inline and the final structural test passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- QQ now has the structural profile boundary needed for Phase 3 validation and follow-up repair work in `03-02`.
- Clipboard correctness after prolonged runtime still needs the later live validation and repair flow for `QQEL-02`.

## Self-Check: PASSED
