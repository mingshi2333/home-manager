# Phase 2: Session Validation - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase defines and implements the repeatable validation path for Fedora KDE Wayland session behavior that wrapped apps depend on. It must prove portal, IME, and clipboard behavior across both shell launch and desktop-entry launch for the chosen baseline apps. It does not yet perform the app-specific runtime repairs for `QQ`, `Zotero`, or other affected apps.

</domain>

<decisions>
## Implementation Decisions

### Validation Targets
- **D-01:** Phase 2 uses `QQ` and `Zotero` as the mandatory baseline validation targets.
- **D-02:** For both baseline apps, validation must cover both shell launch and desktop-entry launch paths.

### Evidence Model
- **D-03:** Phase 2 must produce a checklist plus logs, not only shell scripts and not only manual notes.
- **D-04:** Validation evidence should be repeatable and comparable across later phases, so logs and checklist outputs must be structured enough to rerun after app-specific fixes land.

### Clipboard Validation Scope
- **D-05:** Clipboard validation must include both a generic session-level clipboard probe and a `QQ`-specific paste check.
- **D-06:** The purpose of the dual clipboard path is to separate session-level faults from app-specific paste behavior before later repair phases begin.

### Failure Policy
- **D-07:** Any missing key validation path counts as Phase 2 failure.
- **D-08:** Phase 2 is not done unless shell launch and desktop-entry launch both have portal and IME evidence, and clipboard validation is conclusive enough to support later repair phases.

### Validation Artifact Placement
- **D-09:** Reusable validation scripts should live in `tests/`.
- **D-10:** Checklists, log templates, and other phase-specific validation artifacts should live in the Phase 2 directory.

### the agent's Discretion
- The exact script names and file layout inside `tests/`, as long as they are clearly tied to Phase 2 validation goals.
- The exact checklist/log file formats in the phase directory, as long as they are human-readable and can be rerun later.
- The exact commands used to inspect portal, IME, and launch-path state, as long as they are appropriate for the current Fedora KDE Wayland machine and produce stable evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project And Phase Scope
- `.planning/PROJECT.md` — brownfield repair framing, host-specific scope, and stability priority
- `.planning/REQUIREMENTS.md` — Phase 2 requirements `SESS-01`, `SESS-02`, and `SESS-03`
- `.planning/ROADMAP.md` — Phase 2 goal and success criteria for Session Validation
- `.planning/STATE.md` — current project position and cross-phase concerns

### Existing Session And Launch Wiring
- `modules/environment.nix` — current global Wayland, portal, and `environment.d` session exports
- `modules/fcitx.nix` — current IME propagation logic
- `modules/fcitx-env.nix` — shared fcitx environment values reused across wrappers and session config
- `modules/desktop-entries.nix` — desktop-entry export path and activation refresh logic
- `modules/plasma.nix` — Plasma restart behavior and session-level activation side effects
- `nixgl-apps.nix` — current app wrapper definitions for `QQ`, `Zotero`, and other wrapped apps

### Phase 1 Outputs That Phase 2 Builds On
- `.planning/phases/01-compatibility-boundary/01-CONTEXT.md` — locked boundary decisions carried forward from Phase 1
- `.planning/phases/01-compatibility-boundary/01-01-SUMMARY.md` — established compatibility policy export boundary
- `.planning/phases/01-compatibility-boundary/01-02-SUMMARY.md` — established structural boundary tests and inventory validation approach
- `tests/compatibility-boundary.sh` — example of current repo test style for new validation scripts

### Codebase Guidance
- `.planning/codebase/ARCHITECTURE.md` — current module boundaries and launch/data flow
- `.planning/codebase/CONCERNS.md` — known fragility around desktop entries, environment duplication, and session integration
- `.planning/codebase/CONVENTIONS.md` — naming, shell style, and module wiring conventions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/environment.nix` already generates `environment.d` entries for portal and Wayland-related variables.
- `modules/fcitx.nix` and `modules/fcitx-env.nix` already centralize IME environment propagation.
- `modules/desktop-entries.nix` already owns desktop-entry synchronization and is the real desktop-launch path that must be validated in this phase.
- `tests/compatibility-boundary.sh` and `tests/hms-aliases.sh` already establish the repo's shell-test style for future validation scripts.

### Established Patterns
- Session-wide concerns belong in `modules/`, while app-specific compatibility metadata remains near app definitions.
- The repo uses shell-based regression checks with `set -euo pipefail` and direct `nix eval` assertions for structural validation.
- Phase 1 already introduced a declarative compatibility boundary through `config.local.nixgl`, so Phase 2 should validate session behavior against that existing boundary rather than inventing a second source of truth.

### Integration Points
- Validation scripts can live in `tests/` and inspect exported config plus real launch-path behavior.
- Phase-local checklists and log templates should live under `.planning/phases/02-session-validation/` for reuse in later repair phases.
- `QQ` and `Zotero` are the baseline validation apps because later phases directly depend on them for focused runtime fixes.

</code_context>

<specifics>
## Specific Ideas

- Treat Phase 2 as a session-diagnosis layer, not as an app-fix phase.
- Use `QQ` and `Zotero` as the fixed baseline apps because they map directly to the next repair phases.
- Make clipboard validation explicitly bifurcated: one generic session probe and one `QQ`-specific check.
- Preserve evidence so that after later fixes land, the same checklist and log path can be rerun to prove whether behavior improved.

</specifics>

<deferred>
## Deferred Ideas

- Actual runtime fixes for `QQ` clipboard behavior — deferred to Phase 3.
- Actual runtime fixes for `Zotero` startup or crash behavior — deferred to Phase 4.
- Broad validation across every affected app in the wrapped catalog — deferred until later phases or Phase 5 reuse work.

</deferred>

---
*Phase: 02-session-validation*
*Context gathered: 2026-04-02*
