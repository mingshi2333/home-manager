# Phase 1: Compatibility Boundary - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-02
**Phase:** 01-Compatibility Boundary
**Areas discussed:** Override boundary, Profile shape, Inventory scope, Default policy, Inventory status model

---

## Override boundary

| Option | Description | Selected |
|--------|-------------|----------|
| New module | Add one dedicated compatibility module under `modules/` and import it from the existing profile tree | |
| Host file only | Put the logic directly in `hosts/mingshi/home.nix` with minimal abstraction | |
| Inside nixgl-apps | Keep everything near app definitions inside `nixgl-apps.nix` even if the file grows further | ✓ |

**User's choice:** Keep the boundary in `nixgl-apps.nix`, then clarified that this means app-specific compatibility policy stays there.
**Notes:** Follow-up clarification locked that session-wide env and host integration do not move into `nixgl-apps.nix`; only app-specific policy belongs there.

## Boundary clarification

| Option | Description | Selected |
|--------|-------------|----------|
| App-specific only | Per-app backend/flags/env stay in `nixgl-apps.nix`; session-wide env and host integration stay in modules | ✓ |
| Everything there | App-specific policy plus session-level compatibility logic all move into `nixgl-apps.nix` | |
| Mostly there | Keep most Fedora compatibility decisions in `nixgl-apps.nix`, with only unavoidable session wiring left elsewhere | |

**User's choice:** App-specific only.
**Notes:** This resolved the apparent conflict between the user's first instinct and the roadmap's host-scoped-boundary language.

## Profile shape

| Option | Description | Selected |
|--------|-------------|----------|
| Raw fields | Keep using `platform`, `extraEnv`, `extraFlags` as canonical fields; add minimal helper structure only if clearly needed later | ✓ |
| Named profiles | Introduce named compatibility profiles like `electron-wayland`, `xwayland-safe`, `qt-xcb` and let apps reference them | |
| Hybrid presets | Keep raw fields, but also add optional named presets for common app families | |

**User's choice:** Raw fields.
**Notes:** This keeps Phase 1 focused on boundary-setting instead of introducing a new abstraction layer.

## Inventory scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full catalog | List all wrapped GUI apps, but explicitly mark which are confirmed affected / suspected / healthy | ✓ |
| Affected only | Only record currently known broken apps like QQ and Zotero | |
| Common apps only | Only track frequently used apps and ignore rare packages | |

**User's choice:** Full catalog.
**Notes:** This gives later phases a baseline over the whole wrapped app set instead of a partial incident list.

## Default policy

| Option | Description | Selected |
|--------|-------------|----------|
| Per-app explicit | Keep current global/session defaults, and require explicit per-app declarations for important/problematic apps | ✓ |
| Wayland-first | Default everything to native Wayland unless an app is proven broken | |
| Conservative fallback | Default everything to XWayland/XCB unless an app is proven healthy on Wayland | |

**User's choice:** Per-app explicit.
**Notes:** This avoids forcing one universal policy for all apps on this host.

## Inventory status model

| Option | Description | Selected |
|--------|-------------|----------|
| 4-state model | Use `affected`, `suspected`, `healthy`, `unknown` | ✓ |
| 2-state model | Only `affected` vs `healthy` | |
| Status+priority | Encode both health and priority in the status label | |

**User's choice:** 4-state model.
**Notes:** This preserves uncertainty without pretending every app has already been proven one way or the other.

## the agent's Discretion

- Exact Nix attrset shape for the inventory and any derived outputs
- Exact module/file split needed to expose the new metadata cleanly through the existing runtime layer

## Deferred Ideas

- Introduce named compatibility profiles later if raw fields become repetitive across app families
- Leave app-specific bug repairs to later phases rather than sneaking them into this boundary phase
