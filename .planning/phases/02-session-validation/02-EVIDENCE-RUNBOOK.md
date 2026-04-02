# Phase 2 Session Validation Evidence Runbook

This runbook is the canonical Phase 2 execution reference.
Use it for the initial baseline run and for reruns after Phase 3 and Phase 4 repairs.

## Scope

Phase 2 is validation-only.
It records portal, IME, and clipboard evidence for `QQ` and `Zotero` across `shell` and `desktop` launch paths.

Do not use this runbook to perform repairs.
Do not add app-specific launch flags, wrapper edits, environment overrides, or desktop-entry rewrites during a validation run.

## Required Inputs

- Working tree contains the current Phase 2 probe suite in `tests/session-validation.sh` and `tests/session-launch-capture.sh`.
- Operator will create one Run ID and use it in the checklist, log template, and artifact directory.
- Validation targets remain fixed: `QQ`, `Zotero`, `shell`, and `desktop`.

## Run ID And Artifact Layout

Choose one Run ID before running probes.
Recommended format:

```text
YYYYMMDD-HHMM-phase2-baseline
YYYYMMDD-HHMM-phase2-after-phase3
YYYYMMDD-HHMM-phase2-after-phase4
```

Recommended artifact directory:

```text
.planning/phases/02-session-validation/artifacts/<Run ID>/
```

Recommended companion documents:

- `02-LOG-TEMPLATE.md` copied or filled for the same Run ID.
- `02-CHECKLIST.md` completed for the same Run ID.

## Execution Order

Run the steps in order. Do not skip the probe-only pass.

### Step 1: Create the artifact directory

Example path:

```text
.planning/phases/02-session-validation/artifacts/<Run ID>
```

Record this path in the log template and checklist.

### Step 2: Run the probe-only baseline capture

Command:

```bash
bash tests/session-validation.sh \
  --probe-only \
  --apps qq,zotero \
  --launch-paths shell,desktop \
  --log-dir .planning/phases/02-session-validation/artifacts/<Run ID>/probe-only
```

Purpose:

- Confirm the structural and live-session probes run cleanly.
- Generate deterministic launch-path capture metadata before any manual observations.
- Establish the artifact map that later checklist entries will reference.

Expected outputs:

- `portal/`, `ime/`, and `clipboard/` subdirectories under the selected log directory.
- `run-result.env` at the selected log directory root.
- Per-app and per-launch-path capture directories under each check.

### Step 3: Run the full validation pass

Command:

```bash
bash tests/session-validation.sh \
  --check all \
  --apps qq,zotero \
  --launch-paths shell,desktop \
  --log-dir .planning/phases/02-session-validation/artifacts/<Run ID>/full
```

Purpose:

- Capture the full portal, IME, and clipboard evidence set.
- Produce the same log structure used for later comparison runs.

If a focused rerun is needed, use one of these exact forms:

```bash
bash tests/session-validation.sh --check portal --apps qq,zotero --launch-paths shell,desktop --log-dir .planning/phases/02-session-validation/artifacts/<Run ID>/portal-rerun
bash tests/session-validation.sh --check ime --apps qq,zotero --launch-paths shell,desktop --log-dir .planning/phases/02-session-validation/artifacts/<Run ID>/ime-rerun
bash tests/session-validation.sh --check clipboard --apps qq,zotero --launch-paths shell,desktop --log-dir .planning/phases/02-session-validation/artifacts/<Run ID>/clipboard-rerun
```

### Step 4: Populate the log template

Fill `02-LOG-TEMPLATE.md` with:

- Run metadata and exact commands executed.
- Structural evidence references.
- Live session evidence references.
- Launch capture references for `QQ` and `Zotero` across `shell` and `desktop`.
- Journal excerpts.
- Generic clipboard probe input and output values.
- `QQ`-specific paste observations for both launch paths.

### Step 5: Complete the checklist

Use `02-CHECKLIST.md` after the log template has file references.

Every app and launch-path block must record:

- A concrete attachment or reference for launch capture.
- A concrete attachment or reference for runtime env or PID evidence.
- An explicit `pass`, `fail`, or `inconclusive` value for portal evidence.
- An explicit `pass`, `fail`, or `inconclusive` value for IME evidence.
- The generic clipboard result reused from the global section.
- For `QQ`, an explicit `pass`, `fail`, or `inconclusive` paste result for both `shell` and `desktop`.

## Artifact Map

Map the probe suite outputs into the log template and checklist with no inferred steps.

### Portal Artifacts

- `portal/structural/session-variables.json`
  Record in the log template under `Portal session variables`.
- `portal/structural/environment-portal.conf`
  Record under `Portal environment.d export`.
- `portal/structural/desktop-entries-eval.env`
  Record whether desktop metadata came from `nix eval` or fallback mode.
- `portal/live/org.freedesktop.portal.Desktop`
  Record under the D-Bus probe section.
- `portal/live/org.freedesktop.impl.portal.desktop.kde`
  Record under the KDE portal backend section.
- `portal/live/portal-settings-readall.txt`
  Record under `Portal settings ReadAll call`.

### IME Artifacts

- `ime/structural/session-variables.json`
  Record under `IME session variables`.
- `ime/structural/environment-fcitx.conf`
  Record under `IME environment.d export`.
- `ime/live/fcitx5.service`
  Record under `fcitx5 user-service status`.
- `ime/live/org.fcitx.Fcitx5`
  Record under the D-Bus probe section.
- `ime/live/systemctl-user-environment.txt`
  Record under the live environment capture section.
- `ime/live/fcitx5-remote.txt`
  Record under the `fcitx5-remote` section.

### Clipboard Artifacts

- `clipboard/live/wl-clipboard-probe.env`
  Record the input value, output value, and outcome in the log template.
- `clipboard/live/qq-paste-check.env`
  Treat this as a placeholder that must be resolved by manual `QQ` paste observation in the checklist and log template.

### Launch Capture Artifacts

For each check family, capture outputs live under paths shaped like:

```text
<check>/launch-paths/<app>/<launch-path>/
```

Required attachments for the log template and checklist:

- `journal.txt`
- `desktop-file-validate.txt`
- `capture/capture.env`
- `capture/pgrep.txt` when present
- `capture/environ.txt` when present
- `capture/desktop-entry.desktop` for `desktop` probe-only fallback capture when present

`tests/session-launch-capture.sh` is the source of truth for launch-path runtime evidence.
Its output must be attached or referenced for both apps and both launch paths.

## Manual Observation Rules

These observations must be recorded by the operator after the automated run.

### Generic Clipboard Probe

- Copy the input and output values from `clipboard/live/wl-clipboard-probe.env`.
- Mark the result `pass`, `fail`, or `inconclusive`.
- Do not replace this with a `QQ`-specific result.

### QQ Paste Check

- Test `QQ` paste behavior separately for `shell` and `desktop` launch paths.
- Record the expected pasted content and the observed pasted content.
- Mark each path `pass`, `fail`, or `inconclusive`.
- If the result is inconclusive, record why.

### Zotero Notes

- Record launch observations for `Zotero` in both launch paths.
- Reuse the generic clipboard probe result only; do not invent a Zotero-specific clipboard check in Phase 2.

## Desktop Launch Guidance

The probe suite prefers generated desktop metadata and validates desktop-entry launch feasibility through the Phase 2 scripts.

Use the recorded launch-capture output to determine which path was used:

- If desktop metadata was captured directly, reference the generated desktop file evidence.
- If `gtk-launch` was not reliable, reference the deterministic fallback captured from generated desktop entry metadata.

Do not edit desktop files during validation.

## Validation-Only Boundary

This phase must remain validation-only.

Forbidden during this runbook:

- No repair flags for `QQ`.
- No repair flags for `Zotero`.
- No wrapper changes.
- No desktop-entry rewrites.
- No manual environment overrides added just for the run.
- No reclassification of failures as fixes.

If validation reveals a defect, record it in the log template and checklist for later repair phases.

## Rerun Policy For Later Phases

Use this same runbook after later repairs land.

- After Phase 3, rerun the full flow with a new Run ID and compare `QQ` evidence against the baseline.
- After Phase 4, rerun the full flow with a new Run ID and compare `Zotero` evidence against the earlier runs.
- Keep field names and artifact paths stable so pass, fail, and inconclusive outcomes remain comparable over time.

## Completion Criteria

The run is complete only when all of the following are true:

- Probe-only logs exist for the Run ID.
- Full-run logs exist for the Run ID.
- `QQ` and `Zotero` both have `shell` and `desktop` launch evidence.
- Portal and IME evidence exists for both launch paths.
- The generic clipboard probe is recorded.
- The `QQ`-specific paste result is recorded for both launch paths.
- The checklist and log template use the same Run ID and artifact references.
