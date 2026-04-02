# Roadmap: Fedora KDE Wayland 应用兼容性修复

## Overview

This roadmap repairs the existing Home Manager plus `nixGL` compatibility stack on the current `Fedora + KDE + Wayland` host by first establishing a clean Fedora-specific override boundary, then validating session integration, then stabilizing `QQ`, `Zotero`, and at least one additional affected app through the same declarative repair path.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Compatibility Boundary** - Create the Fedora KDE Wayland compatibility policy layer and baseline app inventory.
- [ ] **Phase 2: Session Validation** - Verify portal, input-method, and clipboard behavior across managed launch paths.
- [ ] **Phase 3: QQ And Electron Stabilization** - Repair `QQ` and establish reusable Electron fallback profiles.
- [ ] **Phase 4: Zotero And Qt Stabilization** - Stabilize `Zotero` startup and encode Qt fallback plus crash diagnosis paths.
- [ ] **Phase 5: Reuse For Other Affected Apps** - Apply the same repair workflow to another broken app and confirm the path is reusable.

## Phase Details

### Phase 1: Compatibility Boundary
**Goal**: User can manage Fedora KDE Wayland compatibility behavior for wrapped apps through one declarative policy layer with a maintained inventory of affected apps.
**Depends on**: Nothing (first phase)
**Requirements**: POLI-01, POLI-02, POLI-03, OTHR-01
**Success Criteria** (what must be TRUE):
  1. User can declare per app whether it should launch through native Wayland or XWayland without editing upstream packages.
  2. User can attach per-app environment variables and launch flags through the repository's managed wrapper path.
  3. User can inspect one Fedora KDE Wayland specific configuration layer that contains host-scoped compatibility overrides.
  4. User can review a current inventory of wrapped desktop apps that still show recurring startup or runtime failures on this host.
**Plans**: 2 total, 2 complete

### Phase 2: Session Validation
**Goal**: User can verify that the Fedora KDE Wayland session provides the portal, IME, and clipboard behavior required by wrapped apps regardless of launch entrypoint.
**Depends on**: Phase 1
**Requirements**: SESS-01, SESS-02, SESS-03
**Success Criteria** (what must be TRUE):
  1. User can confirm that wrapped apps launched from both desktop entries and shell commands see healthy KDE portal integration.
  2. User can confirm that required input-method environment is propagated into the actual runtime context of wrapped apps.
  3. User can run a repeatable validation path for clipboard behavior under the current session before and after app-specific fixes.
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md - Build the reusable session validation probe suite in `tests/` for portal, IME, clipboard, and launch-path evidence.
- [ ] 02-02-PLAN.md - Create the phase-local checklist, log template, and evidence runbook for repeatable Session Validation reruns.

### Phase 3: QQ And Electron Stabilization
**Goal**: User can run `QQ` reliably on the current host and switch Electron-family apps between named repair profiles for stable clipboard behavior.
**Depends on**: Phase 2
**Requirements**: QQEL-01, QQEL-02, QQEL-03
**Success Criteria** (what must be TRUE):
  1. User can launch `QQ` through the managed wrapper path and get repeatable startup on the current Fedora KDE Wayland machine.
  2. User can paste the current clipboard content into `QQ` after prolonged runtime without receiving stale clipboard data.
  3. User can switch `QQ` and similar Electron apps between named launch profiles for repair testing and safe fallback.
**Plans**: TBD

### Phase 4: Zotero And Qt Stabilization
**Goal**: User can launch `Zotero` stably and use a structured Qt fallback and diagnosis path when native startup is unreliable.
**Depends on**: Phase 3
**Requirements**: ZTQT-01, ZTQT-02, ZTQT-03
**Success Criteria** (what must be TRUE):
  1. User can launch `Zotero` repeatedly on the current machine without the intermittent startup failures that currently require retries.
  2. User can select an explicit Qt backend fallback strategy for `Zotero` and similar apps when the default backend is unstable.
  3. User can capture a structured crash-diagnosis path when `Zotero` startup fails or segfaults.
**Plans**: TBD

### Phase 5: Reuse For Other Affected Apps
**Goal**: User can apply the same compatibility policy, validation workflow, and repair patterns to another affected wrapped app beyond `QQ` and `Zotero`.
**Depends on**: Phase 4
**Requirements**: OTHR-02
**Success Criteria** (what must be TRUE):
  1. User can take at least one additional affected app from the inventory and repair it through the same compatibility-policy and validation workflow established earlier.
  2. User can verify that the additional app uses the shared override model rather than a one-off unmanaged workaround.
  3. User can confirm the repair path is reusable for future Fedora KDE Wayland app issues in this repository.
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Compatibility Boundary | 2/2 | Complete | 2026-04-02 |
| 2. Session Validation | 0/TBD | Not started | - |
| 3. QQ And Electron Stabilization | 0/TBD | Not started | - |
| 4. Zotero And Qt Stabilization | 0/TBD | Not started | - |
| 5. Reuse For Other Affected Apps | 0/TBD | Not started | - |
