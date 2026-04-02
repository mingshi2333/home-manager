# Phase 2 Session Validation Checklist

This checklist is the operator-facing verification sheet for Phase 2 reruns.
Use it together with `02-LOG-TEMPLATE.md` and `02-EVIDENCE-RUNBOOK.md`.

## Run Metadata

- Run ID:
- Date:
- Operator:
- Host:
- Session type:
- Validation mode: baseline / after-repair / regression
- Probe log directory:
- Attached log template file:

## Required Evidence Before App Checks

- [ ] Run ID is written on every attached artifact.
- [ ] Probe output directory exists for this Run ID.
- [ ] Portal structural evidence is attached.
- [ ] Portal live-session evidence is attached.
- [ ] IME structural evidence is attached.
- [ ] IME live-session evidence is attached.
- [ ] Generic clipboard probe evidence is attached.
- [ ] `session-launch-capture.sh` evidence exists for each required app and launch path.
- [ ] Journal excerpts are attached for the same execution window.

## Global Session Evidence Summary

Record one outcome for each dimension before app-specific observations.

| Dimension | Evidence Reference | Outcome (`pass` / `fail` / `inconclusive`) | Notes |
| --- | --- | --- | --- |
| Portal structural checks |  |  |  |
| Portal live-session checks |  |  |  |
| IME structural checks |  |  |  |
| IME live-session checks |  |  |  |
| Generic clipboard probe |  |  |  |

## App Validation Matrix

Every row must reference the same Run ID. Do not leave rows blank.

### QQ

#### QQ via `shell`

- Run ID:
- Launch path: `shell`
- Launch capture attachment:
- Runtime env attachment:
- PID or process evidence attachment:
- Journal attachment:
- Portal evidence outcome: `pass` / `fail` / `inconclusive`
- IME evidence outcome: `pass` / `fail` / `inconclusive`
- Generic clipboard probe outcome reused from global section: `pass` / `fail` / `inconclusive`
- QQ paste behavior outcome: `pass` / `fail` / `inconclusive`
- Observed pasted content:
- Expected pasted content:
- Notes:

Required confirmations:
- [ ] Launch capture records the `shell` path explicitly.
- [ ] Portal evidence for `QQ` via `shell` is attached or cross-referenced.
- [ ] IME runtime evidence for `QQ` via `shell` is attached or cross-referenced.
- [ ] Generic clipboard probe result is linked.
- [ ] QQ-specific paste result is recorded explicitly.

#### QQ via `desktop`

- Run ID:
- Launch path: `desktop`
- Launch capture attachment:
- Runtime env attachment:
- PID or process evidence attachment:
- Journal attachment:
- Portal evidence outcome: `pass` / `fail` / `inconclusive`
- IME evidence outcome: `pass` / `fail` / `inconclusive`
- Generic clipboard probe outcome reused from global section: `pass` / `fail` / `inconclusive`
- QQ paste behavior outcome: `pass` / `fail` / `inconclusive`
- Observed pasted content:
- Expected pasted content:
- Notes:

Required confirmations:
- [ ] Launch capture records the `desktop` path explicitly.
- [ ] Desktop-entry evidence references generated desktop metadata or fallback capture.
- [ ] Portal evidence for `QQ` via `desktop` is attached or cross-referenced.
- [ ] IME runtime evidence for `QQ` via `desktop` is attached or cross-referenced.
- [ ] QQ-specific paste result is recorded explicitly.

### Zotero

#### Zotero via `shell`

- Run ID:
- Launch path: `shell`
- Launch capture attachment:
- Runtime env attachment:
- PID or process evidence attachment:
- Journal attachment:
- Portal evidence outcome: `pass` / `fail` / `inconclusive`
- IME evidence outcome: `pass` / `fail` / `inconclusive`
- Generic clipboard probe outcome reused from global section: `pass` / `fail` / `inconclusive`
- Zotero app notes:
- Notes:

Required confirmations:
- [ ] Launch capture records the `shell` path explicitly.
- [ ] Portal evidence for `Zotero` via `shell` is attached or cross-referenced.
- [ ] IME runtime evidence for `Zotero` via `shell` is attached or cross-referenced.
- [ ] Generic clipboard probe result is linked.

#### Zotero via `desktop`

- Run ID:
- Launch path: `desktop`
- Launch capture attachment:
- Runtime env attachment:
- PID or process evidence attachment:
- Journal attachment:
- Portal evidence outcome: `pass` / `fail` / `inconclusive`
- IME evidence outcome: `pass` / `fail` / `inconclusive`
- Generic clipboard probe outcome reused from global section: `pass` / `fail` / `inconclusive`
- Zotero app notes:
- Notes:

Required confirmations:
- [ ] Launch capture records the `desktop` path explicitly.
- [ ] Desktop-entry evidence references generated desktop metadata or fallback capture.
- [ ] Portal evidence for `Zotero` via `desktop` is attached or cross-referenced.
- [ ] IME runtime evidence for `Zotero` via `desktop` is attached or cross-referenced.
- [ ] Generic clipboard probe result is linked.

## Completion Gate

- [ ] All four app and launch-path combinations are filled.
- [ ] Every required outcome field is marked `pass`, `fail`, or `inconclusive`.
- [ ] Both `QQ` launch paths have a recorded QQ-specific paste outcome.
- [ ] Missing evidence is described rather than implied.
- [ ] Any inconclusive result has a reason and follow-up note.
- [ ] This checklist can be compared directly with later reruns using the same Run ID format.
