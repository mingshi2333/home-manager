# Requirements: Fedora KDE Wayland 应用兼容性修复

**Defined:** 2026-04-02
**Core Value:** 当前这台 `Fedora + KDE + Wayland` 机器上的关键桌面应用必须能稳定启动并持续可用，不再依赖频繁重启来恢复。

## v1 Requirements

### Compatibility Policy

- [x] **POLI-01**: User can define whether a wrapped app launches with native Wayland or XWayland through declarative per-app configuration.
- [x] **POLI-02**: User can assign per-app environment variables and launch flags without editing upstream packages.
- [x] **POLI-03**: User can apply Fedora KDE Wayland specific compatibility overrides in one structured configuration layer.

### Session Integration

- [x] **SESS-01**: User can verify that KDE portal integration is healthy for wrapped apps launched from desktop entries and shell commands.
- [x] **SESS-02**: User can propagate and validate input-method environment needed by wrapped apps in the Fedora KDE Wayland session.
- [x] **SESS-03**: User can run a repeatable validation path for clipboard behavior affecting wrapped apps under the current session.

### QQ And Electron

- [ ] **QQEL-01**: User can launch `QQ` reliably through the managed wrapper path on the current Fedora KDE Wayland machine.
- [ ] **QQEL-02**: User can paste current clipboard content into `QQ` after prolonged runtime without receiving stale clipboard data.
- [ ] **QQEL-03**: User can switch `QQ` and similar Electron apps between named launch profiles for repair and fallback testing.

### Zotero And Qt

- [ ] **ZTQT-01**: User can launch `Zotero` reliably on the current Fedora KDE Wayland machine without intermittent startup failure.
- [ ] **ZTQT-02**: User can apply an explicit Qt backend fallback strategy for `Zotero` and similar apps when native behavior is unstable.
- [ ] **ZTQT-03**: User can collect a structured crash-diagnosis path for `Zotero` startup failures and segfaults.

### Other Affected Apps

- [x] **OTHR-01**: User can maintain an inventory of other recurring app startup or runtime failures in this repository's wrapped desktop apps.
- [ ] **OTHR-02**: User can apply the same compatibility-policy and validation workflow to at least one non-QQ, non-Zotero affected app.

## v2 Requirements

### Diagnostics And Hardening

- **DIAG-01**: User can run opt-in diagnostics mode for wrapped apps to inspect applied flags, environment, and launch path details.
- **DIAG-02**: User can verify generated desktop artifacts and rewritten `Exec=` lines through automated health checks.
- **DIAG-03**: User can run regression tests that protect wrapper behavior across future refactors.

### Coverage Expansion

- **COVR-01**: User can maintain a broader compatibility matrix covering all wrapped GUI applications in the repository.
- **COVR-02**: User can promote proven repair profiles into reusable presets by app family beyond the initial target set.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cross-distribution compatibility abstraction | This milestone only targets the current `Fedora + KDE + Wayland` machine |
| Replacing Home Manager or nixGL with a new platform | The repository already has a working foundation and this effort is a repair project |
| Large-scale package curation unrelated to observed failures | v1 is focused on compatibility and stability for broken apps, not expanding app inventory |
| Universal native Wayland forcing for all apps | Research shows this is brittle and would likely break apps that need XWayland fallback |
| Global workaround scripts outside declarative config | Fixes should live in the repository's managed wrapper and module system |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| POLI-01 | Phase 1 | Complete |
| POLI-02 | Phase 1 | Complete |
| POLI-03 | Phase 1 | Complete |
| SESS-01 | Phase 2 | Complete |
| SESS-02 | Phase 2 | Complete |
| SESS-03 | Phase 2 | Complete |
| QQEL-01 | Phase 3 | Pending |
| QQEL-02 | Phase 3 | Pending |
| QQEL-03 | Phase 3 | Pending |
| ZTQT-01 | Phase 4 | Pending |
| ZTQT-02 | Phase 4 | Pending |
| ZTQT-03 | Phase 4 | Pending |
| OTHR-01 | Phase 1 | Complete |
| OTHR-02 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-02*
*Last updated: 2026-04-02 after initial definition*
