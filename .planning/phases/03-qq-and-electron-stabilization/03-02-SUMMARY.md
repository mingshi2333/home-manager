---
phase: 03-qq-and-electron-stabilization
plan: 02
subsystem: testing
tags: [qq, electron, clipboard, wayland, xwayland, validation]

# Dependency graph
requires:
  - phase: 03-qq-and-electron-stabilization
    provides: QQ default safe profile plus explicit test-profile surfaces from 03-01
provides:
  - optional startup-only `qq-auto` fallback helper built on the new profile surfaces
  - Phase 3 validation flow for `qq`, `qq-wayland-test`, and `qq-auto`
  - dedicated Phase 3 runbook for before/after QQ startup and clipboard comparison
affects: [phase-04, electron-apps, qq-validation-reruns]

# Tech tracking
tech-stack:
  added: []
  patterns: [startup-only fallback helper, phase-local qq comparison runbook, profile-aware validation surfaces]

key-files:
  created:
    - .planning/phases/03-qq-and-electron-stabilization/03-HUMAN-UAT.md
  modified:
    - nixgl-apps.nix
    - tests/session-validation.sh
    - tests/session-launch-capture.sh
    - .planning/phases/03-qq-and-electron-stabilization/03-VALIDATION.md

key-decisions:
  - "Kept the startup fallback helper explicit and opt-in instead of letting it replace the normal QQ default surface."
  - "Reused the Phase 2 validation model for QQ safe/test/fallback comparison instead of creating a second evidence framework."

patterns-established:
  - "Pattern: Startup fallback helpers may supervise only the initial launch window and must not claim runtime health detection."
  - "Pattern: Phase-local validation docs extend the existing evidence model instead of inventing new result fields for each repair phase."

requirements-completed: [QQEL-01, QQEL-02, QQEL-03]

# Metrics
duration: 20 min
completed: 2026-04-03
---

# Phase 3 Plan 2: QQ Startup Fallback And Validation Summary

**QQ now exposes an optional startup-only fallback helper and a Phase 3 runbook that compares the safe default, the explicit Wayland test path, and the fallback surface using the existing validation tooling.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-04-03T00:35:00+03:00
- **Completed:** 2026-04-03T00:55:00+03:00
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `qq-auto` as an explicit startup-only fallback helper on top of the new QQ profile surfaces.
- Extended `tests/session-validation.sh` and `tests/session-launch-capture.sh` so Phase 3 can capture evidence for `qq`, `qq-wayland-test`, and `qq-auto` without introducing a second validation framework.
- Completed `03-VALIDATION.md` with concrete commands, artifact layout, and manual clipboard comparison steps for the new QQ surfaces.
- Captured live user approval that the new QQ path is behaving normally in practice.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add an optional startup-only QQ fallback helper on top of the profile surfaces** - `f74b6cb` (feat)
2. **Task 2: Adapt the Phase 2 validation tooling and write the Phase 3 evidence runbook** - `3eaf5fa` (feat)
3. **Task 3: Record live QQ startup and clipboard comparison evidence** - user-approved checkpoint, captured in `03-HUMAN-UAT.md`

**Plan metadata:** pending final phase metadata commit

## Files Created/Modified

- `nixgl-apps.nix` - Added explicit `qq-auto` startup-only fallback helper derived from the new QQ profile surfaces.
- `tests/session-validation.sh` - Added Phase 3 QQ surface support for `qq-wayland-test` and `qq-auto` evidence placeholders.
- `tests/session-launch-capture.sh` - Added profile-aware QQ launch capture support using normalized runtime process matching.
- `.planning/phases/03-qq-and-electron-stabilization/03-VALIDATION.md` - Added Phase 3 runbook, commands, and artifact mapping for QQ profile comparison.
- `.planning/phases/03-qq-and-electron-stabilization/03-HUMAN-UAT.md` - Captured user approval for the live QQ validation gate.

## Decisions Made

- Kept the startup fallback helper opt-in so the stable default path stays simple and predictable.
- Kept manual clipboard verification explicit even after introducing `qq-auto`, because Phase 3 still does not pretend to auto-detect runtime degradation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Recovered from a partial executor stop during Task 2**
- **Found during:** Task 2 (Adapt the Phase 2 validation tooling and write the Phase 3 evidence runbook)
- **Issue:** The subagent committed the fallback helper but stopped before writing the summary or completing the validation runbook and script updates.
- **Fix:** Resumed from the partial worktree state, completed the planned script and runbook changes, re-ran the automated gate, and then continued to the human checkpoint.
- **Files modified:** `tests/session-validation.sh`, `tests/session-launch-capture.sh`, `.planning/phases/03-qq-and-electron-stabilization/03-VALIDATION.md`
- **Verification:** `bash tests/compatibility-boundary.sh && bash -n tests/session-validation.sh && bash -n tests/session-launch-capture.sh`
- **Committed in:** `3eaf5fa`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Recovery stayed inside the planned file set and checkpoint flow. No scope creep.

## Issues Encountered

- The Phase 3 probe-only run behaved like the earlier Phase 2 runs: the shell command timed out before clean exit, but it still wrote a complete evidence tree with `run-result.env` reporting `status=ok`. The runbook and checkpoint used the recorded artifacts rather than the timeout alone.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `QQ` now has a stable default path, an explicit Wayland comparison path, and an optional startup-only fallback helper.
- Phase 4 can focus purely on `Zotero` and Qt behavior without reopening the QQ/Electron boundary decisions.

## Self-Check: PASSED
