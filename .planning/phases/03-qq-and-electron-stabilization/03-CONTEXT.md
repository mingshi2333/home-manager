# Phase 3: QQ And Electron Stabilization - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase stabilizes `QQ` on the current Fedora KDE Wayland host and introduces a reusable Electron repair-profile mechanism that later phases and related apps can build on. It must improve launch reliability, move `QQ` to a safer default path, and preserve an explicit test path for Wayland behavior. It does not yet address `Zotero`-specific runtime repair or general non-Electron app repair.

</domain>

<decisions>
## Implementation Decisions

### QQ Default Behavior
- **D-01:** `QQ` should stop using native Wayland as the default launch path in Phase 3.
- **D-02:** `QQ` should default to a safe `XWayland` launch path because stability is the primary goal for this phase.

### Electron Profile Mechanism
- **D-03:** Phase 3 should introduce a reusable Electron repair-profile mechanism rather than a `QQ`-only special case.
- **D-04:** The mechanism should be immediately usable by `QQ` and designed so other Electron-family apps can adopt it in later phases without redesign.

### User-Facing Exposure
- **D-05:** The user-facing model should be `default + opt-in profile`, not profile-only launching.
- **D-06:** `QQ` should have a stable default profile and an explicit Wayland testing profile for repair and comparison runs.

### Fallback Policy
- **D-07:** Automatic fallback is allowed only for startup-stage failure, not for runtime degradation detection.
- **D-08:** Runtime issues such as stale clipboard behavior after prolonged use should not be auto-detected by wrapper logic in Phase 3.
- **D-09:** If startup fallback is implemented, it should only trigger when the primary profile fails to launch, exits immediately, or clearly fails to stay up.

### the agent's Discretion
- The exact naming of the reusable Electron profiles, as long as one is clearly the stable/safe path and one is clearly the Wayland test path.
- The exact wrapper and alias surface used to expose these profiles, as long as the default behavior remains simple and an explicit test path exists.
- The exact startup-failure heuristic used for fallback, as long as it stays limited to startup and does not pretend to solve runtime clipboard regression detection.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project And Phase Scope
- `.planning/PROJECT.md` — project framing, constraints, and current validated foundation
- `.planning/REQUIREMENTS.md` — Phase 3 requirements `QQEL-01`, `QQEL-02`, and `QQEL-03`
- `.planning/ROADMAP.md` — Phase 3 goal and success criteria for QQ and Electron stabilization
- `.planning/STATE.md` — current project position, prior phase decisions, and active concerns

### Prior Phase Outputs
- `.planning/phases/01-compatibility-boundary/01-CONTEXT.md` — compatibility boundary decisions that still constrain app-level changes
- `.planning/phases/02-session-validation/02-CONTEXT.md` — session validation decisions and evidence model
- `.planning/phases/02-session-validation/02-01-SUMMARY.md` — current probe tooling and known desktop-entry fallback behavior
- `.planning/phases/02-session-validation/02-VERIFICATION.md` — what Phase 2 proved versus what remained intentionally manual
- `.planning/phases/02-session-validation/artifacts/20260402-2131-phase2-baseline/full/clipboard/live/wl-clipboard-probe.env` — generic session clipboard probe passed
- `.planning/phases/02-session-validation/artifacts/20260402-2131-phase2-baseline/full/clipboard/live/qq-paste-check.env` — `QQ` paste result remained manual at the end of Phase 2

### Existing Wrapper And App Definition Surfaces
- `nixgl-apps.nix` — existing app catalog, `qq` definition, compatibility policy fields, and current platform choices
- `modules/nixgl-runtime.nix` — derived `local.nixgl.*` runtime boundary used to export app metadata
- `modules/home-manager-commands.nix` — generated alias and bin-script surface that may expose extra launch entrypoints
- `modules/desktop-entries.nix` — generated desktop-entry surface that may need to expose stable versus testing launch paths

### Session And Diagnosis Inputs
- `tests/session-validation.sh` — probe suite for reruns before and after QQ changes
- `tests/session-launch-capture.sh` — launch-path capture helper
- `journalctl` evidence already observed for `qq` including `Maximum number of clients reached`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `nixgl-apps.nix` already supports app-level `platform`, `extraEnv`, `extraFlags`, aliases, bin scripts, and compatibility metadata, which makes it the natural place to express `QQ` default mode and any reusable Electron profile data.
- `modules/nixgl-runtime.nix` already exports read-only derived metadata through `local.nixgl.*`, so new Electron profile information can likely be surfaced without introducing a second config boundary.
- `modules/home-manager-commands.nix` and generated wrapper/bin-script surfaces already provide user-facing command entrypoints and can expose explicit test paths if needed.
- Phase 2 added `tests/session-validation.sh`, which gives Phase 3 a reusable before/after validation harness for `QQ` startup, portal, IME, and clipboard evidence.

### Established Patterns
- App-specific compatibility logic belongs near app definitions, not in global session modules.
- New behavior should remain declarative and flow through existing generated outputs rather than layering ad hoc shell wrappers outside the repo structure.
- The repo has already accepted the idea that some host-specific repair behavior belongs at the app/wrapper layer while portal and IME ownership remain session-level concerns.

### Evidence-Carried Forward
- Generic Wayland clipboard probing passed in Phase 2, which reduces the likelihood that `QQ` stale paste is caused by a totally broken session clipboard path.
- `QQ` still emitted `Maximum number of clients reached` in journal evidence, making app-specific backend or Electron runtime behavior a credible Phase 3 repair target.
- Phase 2 intentionally left `QQ` paste confirmation manual, so Phase 3 should convert that manual suspicion into a concrete app-level stabilization strategy.

</code_context>

<specifics>
## Specific Ideas

- Change `QQ` to a stable default path first, then preserve a clearly named Wayland test path for comparison and future regression checks.
- Make the profile mechanism reusable for Electron-family apps now, but keep Phase 3 execution focused on `QQ` as the first concrete consumer.
- Treat startup fallback as a limited safety feature; do not let it grow into hidden runtime heuristics that pretend to solve long-lived clipboard degradation.

</specifics>

<deferred>
## Deferred Ideas

- `Zotero` runtime repair and Qt backend stabilization — deferred to Phase 4.
- Broad rollout of Electron repair profiles to other apps as a completion target — deferred to later phases once `QQ` proves the mechanism.
- Automatic detection of runtime clipboard degradation and live in-process profile switching — deferred because Phase 3 only allows startup-stage fallback.

</deferred>

---
*Phase: 03-qq-and-electron-stabilization*
*Context gathered: 2026-04-02*
