# Project Research Summary

**Project:** Fedora KDE Wayland app compatibility repair
**Domain:** Desktop application compatibility layer for Home Manager + nixGL on Fedora KDE Wayland
**Researched:** 2026-04-02
**Confidence:** HIGH

## Executive Summary

This project is not a greenfield desktop platform. It is a brownfield compatibility repair effort for GUI applications running from a Home Manager repository on Fedora KDE Wayland through `nixGL`. The research is consistent that expert implementations do not try to force one universal display path. They keep the graphics bridge and desktop integration stable at the session level, then choose native Wayland or XWayland explicitly per app based on observed behavior. In this repo, that means retaining the current Home Manager plus `nixGL` foundation, keeping KDE portal integration healthy, and making wrapper policy the source of truth for launch mode.

The recommended approach is a four-layer repair stack: Fedora KDE host services and portals, session environment propagation, `nixGL` as the graphics compatibility bridge, and app-specific wrappers that expose named runtime profiles such as `electron-wayland`, `electron-xwayland`, `qt-wayland`, and `qt-xcb`. The first implementation target should be a clean compatibility-policy boundary for Fedora KDE Wayland, followed by structured per-app overrides, then shared session validation, then app-family repairs starting with Electron and moving to Qt and mixed-toolkit apps. `qq` and `zotero` are the primary proving grounds because they exercise the exact failure classes the repo needs to stabilize.

The main risks are false fixes caused by global Wayland forcing, IME and clipboard misdiagnosis, and launcher rewrites that only work from one entrypoint. The mitigation pattern is consistent across all four research files: classify apps by observed backend, test both shell and desktop launch paths, validate portal and IME behavior at the session boundary before blaming the app, and keep repair logic declarative so fixes can be audited and repeated.

## Key Findings

### Recommended Stack

The current stack is directionally correct. The repo should continue using Home Manager as the declarative control plane, `nixGL` as the host graphics bridge, and KDE's portal stack as the integration layer for Fedora Plasma Wayland. The missing piece is not a new platform but a more explicit repair strategy inside the existing wrapper system.

The strongest technical recommendation is to replace implicit or binary launch decisions with typed runtime profiles and host-scoped override data. Native Wayland should be the default only for apps verified healthy on Plasma; XWayland remains a first-class fallback, not a failure state. Session-wide environment should stay minimal and portal-oriented, while app-specific backend and flag decisions belong in wrappers or a compatibility override module.

**Core technologies:**
- Home Manager: declarative environment, wrapper generation, and desktop integration surface — keeps repairs reproducible inside the existing repo.
- `nixGL` NVIDIA wrapper (`nixGLNvidia-*`): graphics and GL/Vulkan bridge for Nix GUI apps on Fedora — remains the standard non-NixOS fix for host driver mismatch.
- Fedora KDE Wayland with XWayland available: primary runtime target with compatibility fallback — matches current Linux desktop practice for mixed-quality app ecosystems.
- `xdg-desktop-portal` plus `xdg-desktop-portal-kde`: file chooser, URI open, clipboard-adjacent integration, and desktop-consistent dialogs — required for a stable Plasma Wayland session.
- Fcitx5 environment propagation: IME integration across Electron, Qt, and XWayland paths — necessary to avoid input regressions in wrapped apps.

### Expected Features

The MVP is a repair layer, not a generalized app platform. Table stakes focus on making wrapped apps launch consistently, choose the right backend, and behave correctly whether started from the shell, KDE menu, or file association. The differentiators are maintainability and diagnosis features that reduce future repair cost once the basic runtime paths are stable.

**Must have (table stakes):**
- Per-app backend selection between native Wayland and XWayland — the core repair primitive for `qq`, `zotero`, and similar apps.
- Per-app launch flags and environment overrides — required for Electron Ozone flags, Qt platform selection, and targeted workarounds.
- Stable GPU and GL/Vulkan wrapping — baseline contract for running Nix GUI apps on Fedora through `nixGL`.
- IME propagation into wrapped apps — needed for Chinese input and reliable text entry on KDE Wayland.
- Clipboard-safe launch modes and mitigations — required because messaging and research apps are unusable if copy and paste regress.
- Desktop entry and MIME correctness for wrapped apps — ensures GUI launches and file/URL handling go through the repaired wrapper path.
- Repeatable startup behavior with app-local fallbacks — especially important for crash-prone or bundled-runtime apps.

**Should have (competitive):**
- Named per-app repair profiles such as `wayland`, `xwayland-safe`, and `debug` — makes experimentation and rollback manageable.
- Opt-in diagnostics mode for wrapped apps — enables runtime logging and wrapper inspection without editing package definitions.
- App capability metadata in the catalog — allows shared presets by app family instead of repeated bespoke logic.
- Health checks for generated desktop artifacts — reduces silent breakage from launcher rewriting.
- Verification commands to detect Wayland versus XWayland and inspect applied flags — speeds up regression triage.

**Defer (v2+):**
- Full regression test coverage for wrappers and generated launchers — valuable, but best added after the repair modes for the key apps are encoded and stable.
- Broad renderer fallback matrix beyond immediate known issues — add only after real app-specific evidence justifies it.

### Architecture Approach

The architecture should stay data-driven and layered. Generic wrapper primitives in `nixgl-apps.nix` describe how apps are launched, `modules/nixgl-runtime.nix` exports the resulting catalog, shared modules keep session environment and desktop integration consistent, and a new Fedora KDE Wayland compatibility module supplies host-scoped overrides. The critical boundary is that app-family defaults stay generic, while Fedora-specific routing and temporary repair policy live in one host-owned compatibility layer.

**Major components:**
1. `nixgl-apps.nix` — declares wrapper recipes, metadata, desktop entries, and app-local env or flags.
2. `modules/nixgl-runtime.nix` — evaluates the app catalog once and exposes a stable `config.local.nixgl` interface to the rest of the repo.
3. Session modules such as `modules/environment.nix`, `modules/fcitx.nix`, and `modules/desktop-entries.nix` — handle shared Wayland, portal, IME, and desktop refresh behavior.
4. `modules/compat/fedora-kde-wayland.nix` or equivalent host profile — owns Fedora KDE policy, structured per-app overrides, and temporary host-specific fixes.

### Critical Pitfalls

1. **Forcing Wayland globally instead of deciding per app** — keep shared environment minimal and classify each target app as native Wayland, XWayland, or needs validation before changing wrappers.
2. **Mixing IME strategies without separating Wayland and XWayland paths** — treat Fcitx, text-input, IM modules, and XIM fallback as a matrix and only add app-local overrides when the session path is verified.
3. **Treating clipboard failures as app-only bugs** — debug compositor, session clipboard persistence, IME interaction, and backend mode before shipping app-specific clipboard fixes.
4. **Assuming `nixGL` is only a graphics shim** — validate shell launch, desktop launch, MIME launch, and any D-Bus entrypoints because wrapper behavior affects all of them.
5. **Rewriting desktop or service files without checking outputs** — inspect generated `Exec=` lines, preserve `%U` and `%F` placeholders, and add health checks for critical apps.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Compatibility Boundary And App Classification
**Rationale:** The repo needs a clean place for Fedora KDE Wayland policy before any new fixes land, otherwise host-specific logic will keep leaking into generic wrappers.
**Delivers:** A Fedora KDE compatibility module or profile, a structured override schema for backend/env/flags, and an app inventory that records observed backend and launch path behavior.
**Addresses:** Per-app backend selection, per-app launch overrides, repeatable startup behavior.
**Avoids:** Global Wayland forcing, shell-only fixes, and backend misclassification.

### Phase 2: Session Integration Validation
**Rationale:** Clipboard, IME, and portal issues can masquerade as app bugs. The session boundary needs to be validated before deeper app-specific tuning.
**Delivers:** Verified `environment.d` propagation into `systemd --user` and D-Bus activation, confirmed KDE portal backend behavior, and an IME and clipboard validation matrix for real launch paths.
**Uses:** KDE portal stack, Fcitx environment propagation, Home Manager session exports.
**Implements:** Shared environment and compatibility-system-integration modules.

### Phase 3: Electron Family Repairs
**Rationale:** The known issue set is dominated by Electron-style Wayland, clipboard, and IME behavior, and `qq` is the highest-value repair candidate.
**Delivers:** Named Electron profiles such as `electron-wayland` and `electron-xwayland`, side-by-side validation for `qq`, and explicit launch flags rather than relying on ambient global state.
**Addresses:** Clipboard-safe launch modes, IME stability, repeatable startup, desktop-correct launches.
**Avoids:** Misattributing session bugs to Electron-only causes and overusing global Electron flags.

### Phase 4: Qt And Mixed-Toolkit Repairs
**Rationale:** Once shared session behavior and the wrapper override mechanism are stable, Qt and QtWebEngine apps can be repaired with lower ambiguity.
**Delivers:** `qt-wayland` and `qt-xcb` profiles, a conservative stabilization path for `zotero`, and targeted Qt backend selection captured in wrapper data rather than ad hoc shell logic.
**Uses:** Qt platform selection, existing wrapper generation, host override data.
**Implements:** Per-app Qt fallback policy and app-family-specific repair annotations.

### Phase 5: Desktop Artifact Hardening And Diagnostics
**Rationale:** After the main runtime paths are stable, the repo should make failures observable and prevent regressions in launchers and rewritten desktop metadata.
**Delivers:** Desktop artifact health checks, optional diagnostics profiles, verification commands, and a documented cleanup path for temporary flags.
**Addresses:** Desktop entry correctness, diagnostics mode, future maintainability.
**Avoids:** Silent launcher drift, permanent workaround accumulation, and fragile debugging loops.

### Phase Ordering Rationale

- Compatibility policy comes first because the research is unanimous that Fedora KDE fixes should not be hard-coded into generic app wrappers.
- Session validation comes before app-family repairs because clipboard, IME, and portal failures cross app boundaries and otherwise create false diagnoses.
- Electron repairs come before Qt because the current problem set and highest-priority app, `qq`, sit in the Electron family and are more sensitive to Wayland versus XWayland selection.
- Desktop hardening and diagnostics come last because they are multipliers on a repair strategy that must exist first; otherwise they only validate unstable or ad hoc behavior.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** Clipboard and IME validation may need targeted research if current Fedora Plasma behavior differs from the assumptions in the research, especially around Fcitx launch path and clipboard persistence.
- **Phase 4:** `zotero` crash root cause is not yet proven; additional phase research may be required to separate QtWebEngine, GPU, sandbox, plugin, or IME causes.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Compatibility boundary and override schema are straightforward repo-internal refactors with well-established architecture guidance.
- **Phase 3:** Electron Wayland versus XWayland profile mechanics are well documented and already strongly supported by the research.
- **Phase 5:** Desktop artifact checks and diagnostics are standard hardening work once the wrapper model is settled.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Backed by official Electron, Qt, portal, and nixGL guidance plus direct alignment with current repo structure. |
| Features | HIGH | Derived mostly from direct codebase needs and concrete app-repair expectations, with strong agreement across research outputs. |
| Architecture | HIGH | Based on existing repository seams and a clear generic-versus-host boundary; low speculation beyond introducing a compatibility module. |
| Pitfalls | HIGH | Pitfalls are grounded in known Wayland, IME, portal, and wrapper-surface failure modes and are directly relevant to this repo. |

**Overall confidence:** HIGH

### Gaps to Address

- `qq` clipboard root cause is still an implementation-time question: validate whether the winning fix is backend selection alone or whether session clipboard persistence and IME interaction are involved.
- `zotero` crash causality remains unresolved: planning should treat `qt-xcb` as the safe default while collecting evidence before any attempt to promote it back to native Wayland.
- Actual propagation into desktop-launched and D-Bus-activated processes still needs verification in the live Fedora KDE session: do not assume shell environment equals GUI environment.
- Generated desktop and service rewrite behavior should be validated against real outputs for critical apps because current rewrite mechanics are fragile by nature.

## Sources

### Primary (HIGH confidence)
- `/home/mingshi/.config/home-manager/.planning/research/STACK.md` — recommended runtime stack, wrapper policy, and environment guidance.
- `/home/mingshi/.config/home-manager/.planning/research/FEATURES.md` — table stakes, differentiators, and anti-features for the repair layer.
- `/home/mingshi/.config/home-manager/.planning/research/ARCHITECTURE.md` — component boundaries, override pattern, and build order guidance.
- `/home/mingshi/.config/home-manager/.planning/research/PITFALLS.md` — critical failure modes and phase-specific warnings.
- https://www.electronjs.org/docs/latest/api/command-line-switches — Electron launch flag behavior.
- https://www.electronjs.org/docs/latest/api/environment-variables — Electron runtime environment guidance.
- https://doc.qt.io/qt-6/wayland-and-qt.html — Qt Wayland and X11 backend selection.
- https://flatpak.github.io/xdg-desktop-portal/docs/ — portal behavior and system integration boundaries.
- https://flatpak.github.io/xdg-desktop-portal/docs/system-integration.html — activation environment expectations.
- https://github.com/nix-community/nixGL — non-NixOS graphics compatibility model.

### Secondary (MEDIUM confidence)
- https://wiki.nixos.org/wiki/Wayland — ecosystem guidance on Chromium and Electron Wayland defaults.
- https://wiki.archlinux.org/title/XDG_Desktop_Portal — operational guidance on KDE portal backend behavior.
- https://wiki.archlinux.org/title/Wayland — ecosystem notes on mixed Wayland and XWayland runtime behavior.
- https://wiki.archlinux.org/title/Fcitx5 — operational reference for IME integration pitfalls.

### Tertiary (LOW confidence)
- Repo-local inferences around exact `qq` clipboard and `zotero` crash mechanisms — useful for prioritization, but still need live validation during implementation.

---
*Research completed: 2026-04-02*
*Ready for roadmap: yes*
