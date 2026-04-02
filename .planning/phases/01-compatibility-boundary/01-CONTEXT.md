# Phase 1: Compatibility Boundary - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase creates the declarative compatibility boundary for the current `Fedora + KDE + Wayland` host and establishes a maintained inventory of affected wrapped desktop apps. It defines where app-specific compatibility policy lives, how compatibility choices are expressed, and how affected apps are classified. It does not yet implement the app-specific runtime fixes for `QQ`, `Zotero`, or other broken apps.

</domain>

<decisions>
## Implementation Decisions

### Compatibility Boundary Placement
- **D-01:** App-specific compatibility decisions remain in `nixgl-apps.nix`, alongside the existing wrapped app catalog.
- **D-02:** Session-wide environment wiring such as portal, IME, and other global Fedora/KDE/Wayland integration stays in `modules/`, not in `nixgl-apps.nix`.

### Compatibility Expression Model
- **D-03:** Phase 1 should keep the existing canonical compatibility fields based on raw wrapper data: `platform`, `extraEnv`, and `extraFlags`.
- **D-04:** Phase 1 should not introduce a new named-profile abstraction or compatibility DSL unless later phases prove that raw fields are insufficient.

### Inventory Scope And Classification
- **D-05:** Phase 1 should build an inventory over the full wrapped GUI app catalog, not only currently-known broken apps.
- **D-06:** The inventory must distinguish app health using a 4-state model: `affected`, `suspected`, `healthy`, and `unknown`.
- **D-07:** The inventory should explicitly surface known recurring failures for this host while still preserving visibility into the rest of the catalog for later prioritization.

### Default Host Policy
- **D-08:** The compatibility stance for this host should be explicit per app for important or problematic applications, rather than relying on one universal global default.
- **D-09:** Existing global session defaults may remain in place for now, but Phase 1 should make the per-app declaration path the source of truth for important compatibility behavior.

### the agent's Discretion
- The exact Nix data shape used to store inventory state, as long as it remains declarative and readable from downstream modules.
- The precise file/module split needed to keep app-level compatibility data in `nixgl-apps.nix` while leaving session-level wiring in `modules/`.
- The exact inventory serialization or derived-output format, as long as later phases can read and update it without ambiguity.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project And Phase Scope
- `.planning/PROJECT.md` — project constraints, brownfield repair framing, and host-specific scope boundaries
- `.planning/REQUIREMENTS.md` — Phase 1 requirements `POLI-01`, `POLI-02`, `POLI-03`, and `OTHR-01`
- `.planning/ROADMAP.md` — Phase 1 goal and success criteria for Compatibility Boundary
- `.planning/STATE.md` — current project position and already-locked cross-phase decisions

### Existing Wrapper And Runtime Boundaries
- `nixgl-apps.nix` — current wrapped app catalog, per-app compatibility fields, and generated artifact helpers
- `modules/nixgl-runtime.nix` — shared `local.nixgl.*` runtime boundary consumed by downstream modules
- `modules/packages.nix` — package assembly consuming `config.local.nixgl.appPackages`
- `modules/home-manager-commands.nix` — generated command and script outputs consuming `config.local.nixgl.binScripts` and aliases
- `modules/desktop-entries.nix` — desktop and MIME integration consuming generated app metadata

### Session-Level Environment Wiring
- `modules/environment.nix` — current global Wayland, portal, and `environment.d` session defaults
- `modules/fcitx.nix` — input method environment propagation layer
- `modules/fcitx-env.nix` — shared fcitx env values reused by wrappers and session config

### Codebase Guidance
- `.planning/codebase/ARCHITECTURE.md` — current module boundaries and `local.nixgl` design
- `.planning/codebase/STRUCTURE.md` — file ownership and where new compatibility logic should fit
- `.planning/codebase/CONCERNS.md` — why `nixgl-apps.nix` is currently fragile and why compatibility scope needs explicit containment
- `.planning/codebase/CONVENTIONS.md` — naming and module wiring conventions for new declarative state

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `nixgl-apps.nix`: already defines per-app compatibility knobs via `platform`, `extraEnv`, `extraFlags`, aliases, MIME types, and desktop metadata
- `modules/nixgl-runtime.nix`: already exports a shared `config.local.nixgl` interface, which is the cleanest existing bridge for any new derived compatibility data
- `modules/environment.nix`: already carries global Wayland and portal session variables, so Phase 1 does not need to invent a new session-env mechanism
- `modules/fcitx.nix` and `modules/fcitx-env.nix`: already centralize IME propagation and should stay the session-level source of truth

### Established Patterns
- The repo prefers read-only derived state under `local.*`, specifically `local.nixgl.*`, rather than scattering recomputation across modules.
- App-level wrapper behavior is data-driven from `nixgl-apps.nix`, with downstream modules consuming generated outputs rather than rebuilding them.
- Cross-cutting session behavior lives in `modules/`, while host identity stays minimal in `hosts/mingshi/home.nix`.
- The codebase already uses explicit module imports and narrow helper data files, so any new compatibility data should follow the same declarative pattern.

### Integration Points
- Any new app inventory or compatibility metadata should likely be derived near `nixgl-apps.nix` and surfaced through `modules/nixgl-runtime.nix` so consumers can use it declaratively.
- If a new compatibility-focused module is introduced later, it should integrate through the existing profile/module tree rather than bypassing `home.nix` assembly.
- Session-wide behavior changes must connect through `modules/environment.nix` or `modules/fcitx.nix`, not through app wrapper generation.

</code_context>

<specifics>
## Specific Ideas

- Keep per-app compatibility decisions near the app definitions because that is where the user expects to reason about `QQ`, `Zotero`, and similar wrapped apps.
- Avoid introducing named compatibility profiles in Phase 1; first stabilize the boundary using the existing raw fields and only abstract later if repetition justifies it.
- Inventory should act as the baseline truth for the whole wrapped app catalog, not just a short bug list for the two currently painful apps.

</specifics>

<deferred>
## Deferred Ideas

- Named compatibility profiles such as `electron-wayland`, `xwayland-safe`, or `qt-xcb` — deferred to later phases if Phase 1 shows enough repetition to justify a higher-level abstraction.
- App-specific runtime fixes for `QQ`, `Zotero`, or other broken apps — deferred to Phases 3, 4, and 5.
- Diagnostics and health-check automation for wrapper outputs — already tracked in v2 requirements, not part of this boundary-setting phase.

</deferred>

---
*Phase: 01-compatibility-boundary*
*Context gathered: 2026-04-02*
