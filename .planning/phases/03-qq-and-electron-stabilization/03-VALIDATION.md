---
phase: 03
slug: qq-and-electron-stabilization
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-02
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Repo shell tests plus manual live-session verification |
| **Config file** | none — direct shell scripts under `tests/` |
| **Quick run command** | `bash tests/compatibility-boundary.sh` |
| **Full suite command** | `bash tests/compatibility-boundary.sh && bash -n tests/session-validation-lib.sh && bash -n tests/session-validation.sh && bash -n tests/session-launch-capture.sh && bash tests/session-validation.sh --probe-only --apps qq,qq-wayland-test,qq-auto --launch-paths shell,desktop --log-dir .planning/phases/03-qq-and-electron-stabilization/artifacts/probe-only` |
| **Estimated runtime** | ~20 seconds for automated smoke checks, plus manual QQ validation |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/compatibility-boundary.sh`
- **After every plan wave:** Run `bash tests/compatibility-boundary.sh && bash -n tests/session-validation-lib.sh && bash -n tests/session-validation.sh && bash -n tests/session-launch-capture.sh`
- **Before `/gsd-verify-work`:** Focused `qq` probe-only rerun plus manual clipboard validation must be recorded
- **Max feedback latency:** 30 seconds for automated smoke checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | QQEL-03 | structural | `bash tests/compatibility-boundary.sh` | ✅ existing | ⬜ pending |
| 03-01-02 | 01 | 1 | QQEL-01 | structural + smoke | `bash tests/compatibility-boundary.sh && bash -n tests/session-validation.sh && bash -n tests/session-launch-capture.sh` | ✅ existing, needs updates | ⬜ pending |
| 03-02-01 | 02 | 2 | QQEL-02 | manual + evidence | `bash tests/session-validation.sh --check clipboard --apps qq,qq-wayland-test,qq-auto --launch-paths shell,desktop --log-dir .planning/phases/03-qq-and-electron-stabilization/artifacts/<run-id>/clipboard` | ✅ existing runner | ⬜ pending |
| 03-02-02 | 02 | 2 | QQEL-01, QQEL-02, QQEL-03 | full verify | `bash tests/compatibility-boundary.sh && bash -n tests/session-validation.sh && bash -n tests/session-launch-capture.sh` | ✅ existing, needs updates | ⬜ pending |
| 03-02-03 | 02 | 2 | QQEL-01, QQEL-02 | checkpoint prereq | `bash tests/compatibility-boundary.sh && bash -n tests/session-validation.sh && bash -n tests/session-launch-capture.sh` | ✅ produced before checkpoint | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Plan `03-01` updates `tests/compatibility-boundary.sh` so `qq` no longer expects a raw Wayland default and instead validates default profile plus explicit test-profile metadata.
- [x] Plan `03-01` adds profile-surface assertions for alias/bin/desktop-entry parity on `qq` default and explicit test entrypoints.
- [x] Plan `03-02` updates session-validation helpers only as needed so `qq` profile variants can be captured without creating a second validation framework.
- [x] Phase-local manual evidence coverage already exists in `03-VALIDATION.md` and is refined by Plan `03-02` before the human checkpoint.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `QQ` startup comparison between default safe profile and explicit Wayland test profile | QQEL-01, QQEL-03 | Live launch behavior and backend reality must be confirmed in the current session | Run the focused Phase 3 `qq` probe and launch both the default entrypoint and the explicit Wayland testing entrypoint, then record startup success, launch-path evidence, and user-visible behavior |
| `QQ` clipboard comparison after runtime dwell | QQEL-02 | Stale paste regression is a live-client behavior, not fully automatable in this phase | Reuse the Phase 2 checklist/log style to compare pasted content before and after Phase 3 using both the default and test profile paths |
| Startup-only fallback behavior | QQEL-01 | Wrapper fallback heuristics require observing actual failure/success behavior | Trigger or observe startup failure conditions where practical and confirm fallback only activates for startup-stage failure, not for runtime degradation |

---

## Execution Runbook

Phase 3 reuses the Phase 2 evidence model, but the validation targets change from `qq + zotero` to the three `QQ` surfaces introduced by this phase:

- `qq` — safe default profile
- `qq-wayland-test` — explicit Wayland testing profile
- `qq-auto` — optional startup-only fallback helper

This runbook is the canonical operator path for before/after comparison once the Phase 3 implementation is applied.

### Baseline Reference

The comparison baseline is the Phase 2 artifact set created before Phase 3 changes:

```text
.planning/phases/02-session-validation/artifacts/20260402-2131-phase2-baseline/
```

Use the Phase 2 `wl-clipboard-probe.env` and your recorded `QQ` observations as the "before" side when evaluating Phase 3 outcomes.

### Step 0: Apply the current configuration

Phase 3 changes wrappers, aliases, and generated desktop entries. Apply them before running the live validation flow:

```bash
cd ~/.config/home-manager
hms
```

### Step 1: Create a Phase 3 Run ID

Recommended format:

```text
YYYYMMDD-HHMM-phase3-after-profile
YYYYMMDD-HHMM-phase3-rerun
```

Example:

```bash
RUN_ID="$(date +%Y%m%d-%H%M)-phase3-after-profile"
mkdir -p ".planning/phases/03-qq-and-electron-stabilization/artifacts/$RUN_ID"
```

### Step 2: Run the automated structural and probe captures

Structural guard:

```bash
bash tests/compatibility-boundary.sh
```

Probe-only capture for all Phase 3 QQ surfaces:

```bash
bash tests/session-validation.sh \
  --probe-only \
  --apps qq,qq-wayland-test,qq-auto \
  --launch-paths shell,desktop \
  --log-dir ".planning/phases/03-qq-and-electron-stabilization/artifacts/$RUN_ID/probe-only"
```

Focused clipboard comparison capture:

```bash
bash tests/session-validation.sh \
  --check clipboard \
  --apps qq,qq-wayland-test,qq-auto \
  --launch-paths shell,desktop \
  --log-dir ".planning/phases/03-qq-and-electron-stabilization/artifacts/$RUN_ID/clipboard"
```

Optional full rerun when you want fresh portal and IME evidence tied to the same Run ID:

```bash
bash tests/session-validation.sh \
  --check all \
  --apps qq,qq-wayland-test,qq-auto \
  --launch-paths shell,desktop \
  --log-dir ".planning/phases/03-qq-and-electron-stabilization/artifacts/$RUN_ID/full"
```

### Step 3: Record the live observations

Manual observations are still required. Automation only prepares comparable evidence.

Record these outcomes explicitly:

- `qq` via `shell` and `desktop`
- `qq-wayland-test` via `shell` and `desktop`
- `qq-auto` via `shell` and `desktop` for startup-only behavior

For each relevant run, capture:

- whether launch succeeded
- whether the app stayed up past the startup window
- whether `qq-auto` fell back or stayed on the primary path
- expected pasted content versus observed pasted content
- `pass`, `fail`, or `inconclusive`

### Step 4: Reuse the Phase 2 evidence format

Use the existing Phase 2 templates as the record format, but reinterpret them for Phase 3 surfaces:

- [02-CHECKLIST.md](/home/mingshi/.config/home-manager/.planning/phases/02-session-validation/02-CHECKLIST.md)
- [02-LOG-TEMPLATE.md](/home/mingshi/.config/home-manager/.planning/phases/02-session-validation/02-LOG-TEMPLATE.md)

Mapping rules for Phase 3:

- treat the `QQ` section as the safe default `qq`
- use an additional copied block for `qq-wayland-test`
- use notes or an added copied block for `qq-auto` startup-only results
- keep the same field names so the Phase 2 baseline remains comparable

### Phase 3-Specific Artifact References

- `probe-only/clipboard/live/qq-paste-check.env` — manual safe-profile paste result placeholder
- `probe-only/clipboard/live/qq-wayland-test-paste-check.env` — manual Wayland-test paste result placeholder
- `probe-only/clipboard/live/qq-auto-startup-check.env` — manual startup-only fallback result placeholder
- `probe-only/<check>/launch-paths/<app>/<launch-path>/capture/` — per-surface launch capture evidence

### Completion Rule

Phase 3 human validation is complete only when:

- the safe default `qq` path has startup and clipboard comparison results
- the explicit `qq-wayland-test` path has startup and clipboard comparison results
- the optional `qq-auto` path has startup-only evidence if the helper exists
- every manual result is marked `pass`, `fail`, or `inconclusive`
- the results can be compared back to the Phase 2 baseline artifacts without inventing new fields

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [x] Feedback latency kept at the fast structural/syntax smoke path for per-task gates
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
