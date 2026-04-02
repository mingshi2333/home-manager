# Phase 3: QQ And Electron Stabilization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-02
**Phase:** 03-QQ And Electron Stabilization
**Areas discussed:** QQ default mode, repair-profile breadth, exposure model, fallback trigger

---

## QQ default mode

| Option | Description | Selected |
|--------|-------------|----------|
| XWayland default | Make `QQ` default to the safer XWayland path and keep Wayland for later repair/testing | ✓ |
| Wayland default | Keep Wayland as the default path and only fall back when it fails | |
| Dual-profile first | Expose only profiles and avoid a single default | |

**User's choice:** XWayland default.
**Notes:** Stability beats native Wayland preference for this phase.

## Profile breadth

| Option | Description | Selected |
|--------|-------------|----------|
| QQ only first | Make profiles only for `QQ` first | |
| Reusable for Electron | Build a reusable Electron mechanism even though `QQ` is the first target | ✓ |
| QQ only, no profiles | Just switch QQ to XWayland without a reusable profile concept | |

**User's choice:** Reusable for Electron.
**Notes:** `QQ` is the first consumer, but the mechanism should not be QQ-private.

## Exposure model

| Option | Description | Selected |
|--------|-------------|----------|
| Default+opt-in profile | Keep a simple default path and expose an explicit Wayland testing profile | ✓ |
| Named profiles only | Require explicit profile names for all launches | |
| Hidden mechanism | Keep profile support internal to config only | |

**User's choice:** Default+opt-in profile.
**Notes:** This preserves a simple user default while still allowing targeted comparison runs.

## Fallback trigger

| Option | Description | Selected |
|--------|-------------|----------|
| Startup failure only | Only auto-fallback on startup failure or immediate exit; runtime degradation is out of scope | ✓ |
| Startup + manual rerun | Only handle startup automatically, leave runtime problems to later manual restart | |
| No runtime fallback | Same practical boundary, expressed as a non-goal | |

**User's choice:** Startup failure only.
**Notes:** The discussion explicitly ruled out automatic detection of long-lived clipboard degradation.

## the agent's Discretion

- Exact profile names and wrapper exposure shape
- Exact startup failure heuristic for fallback

## Deferred Ideas

- Runtime auto-detection of stale clipboard failures
- `Zotero`-specific stabilization logic
- Broad Electron adoption as a same-phase execution target
