# Phase 2: Session Validation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-02
**Phase:** 02-Session Validation
**Areas discussed:** Validation targets, Evidence format, Clipboard method, Failure policy, Validation artifact placement

---

## Validation targets

| Option | Description | Selected |
|--------|-------------|----------|
| QQ+Zotero baseline | Use `QQ` and `Zotero` as mandatory validation targets, and test each through shell launch plus desktop-entry launch | ✓ |
| Representative apps | Use one Electron app, one Qt app, and one extra wrapped app as representatives | |
| Full affected set | Try to validate every currently affected app already in Phase 2 | |

**User's choice:** QQ+Zotero baseline.
**Notes:** This keeps Phase 2 aligned with the concrete apps targeted by later repair phases.

## Evidence format

| Option | Description | Selected |
|--------|-------------|----------|
| Checklist + logs | Create a human-readable validation checklist plus command/log outputs that can be rerun and compared | ✓ |
| Shell tests only | Prefer automated shell scripts and avoid human checklists unless absolutely necessary | |
| Manual notes only | Keep it lightweight with written steps and observed results | |

**User's choice:** Checklist + logs.
**Notes:** Phase 2 must leave behind repeatable evidence, not just automation or ad hoc notes.

## Clipboard method

| Option | Description | Selected |
|--------|-------------|----------|
| Generic + QQ | Use a generic session-level clipboard probe plus a QQ-specific paste check | ✓ |
| QQ only | Focus only on the exact QQ stale-paste behavior | |
| Generic only | Only validate the session clipboard path now | |

**User's choice:** Generic + QQ.
**Notes:** This allows later phases to distinguish session-level clipboard faults from app-specific paste problems.

## Failure policy

| Option | Description | Selected |
|--------|-------------|----------|
| Any missing path fails | If shell launch and desktop launch do not both have portal/IME evidence, or clipboard validation is inconclusive, Phase 2 is not done | ✓ |
| Major paths only | Allow some gaps if the main shell path is understood | |
| Best-effort | Capture what we can and continue even if some paths remain unproven | |

**User's choice:** Any missing path fails.
**Notes:** Phase 2 is a gating validation phase, not a best-effort information collection phase.

## Validation artifact placement

| Option | Description | Selected |
|--------|-------------|----------|
| Phase dir + tests | Keep reusable scripts in `tests/` and keep checklists/log templates in the Phase 2 directory | ✓ |
| Phase dir only | Put scripts, logs, and checklists all inside the phase artifact directory | |
| Tests only | Push everything into reusable repo paths and avoid phase-local validation docs | |

**User's choice:** Phase dir + tests.
**Notes:** This preserves reusable tooling in the repo while keeping phase-local evidence and templates with the planning artifacts.

## the agent's Discretion

- Exact names and layout for Phase 2 scripts and validation docs
- Exact command set used to capture portal, IME, and launch-path evidence on this machine

## Deferred Ideas

- `QQ` runtime repair itself — Phase 3
- `Zotero` runtime repair itself — Phase 4
- Wider affected-app validation rollout — later phases
