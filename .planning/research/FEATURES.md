# Feature Landscape

**Domain:** Fedora KDE Wayland desktop application compatibility and repair layer for Home Manager + nixGL
**Researched:** 2026-04-02

## Table Stakes

Features users expect. Missing = desktop apps feel unreliable or broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Per-app backend selection between native Wayland and XWayland | Mature Linux desktop compatibility layers must be able to force the runtime path that actually works for a given app. QQ and Electron-family apps often prefer Wayland flags; legacy or bundled-toolkit apps like Zotero often need XWayland fallback. | Low | This is the baseline repair primitive. In this repo it maps directly to per-app `platform`, `extraEnv`, and `extraFlags` in `nixgl-apps.nix`. |
| Per-app launch flags and environment overrides | Desktop compatibility fixes are usually app-specific, not global. Electron apps need Ozone/IME/logging flags; Qt apps need `QT_QPA_PLATFORM`; GTK apps sometimes need renderer overrides. | Low | Must support both additive flags and env vars without touching upstream packages. |
| Stable GPU and GL/Vulkan wrapping | On Fedora with Home Manager plus `nixGL`, apps must consistently see host graphics drivers or they fail to launch, render incorrectly, or crash. | Medium | This is already the repo's core compatibility contract and remains table stakes, not a differentiator. |
| Input method and IME propagation into wrapped apps | KDE Wayland desktop usage is incomplete if Chinese input or compose/input method behavior breaks in wrapped apps. | Medium | Existing `fcitxEnv` plumbing is the right seam. Repair layer should treat IME propagation as first-class. |
| Clipboard-safe launch modes and mitigations | Copy/paste reliability is table stakes for messaging and research apps. If an app is known to regress under native Wayland, the layer must support forcing XWayland or other app-local mitigations. | Medium | For this milestone, QQ clipboard stability is a primary requirement. Do not promise portal-based clipboard repair for arbitrary apps; most desktop apps still rely on toolkit/native clipboard paths. |
| Desktop entry and MIME correctness for wrapped apps | A repaired app is not actually repaired if the launcher, icon, MIME handler, or D-Bus activation still points at the unwrapped binary. | Medium | Current repo already rewrites `.desktop` and service files. This remains required for stable everyday usage. |
| D-Bus and portal-visible session integration | File pickers, open/save flows, URL launching, and desktop integration should work from the wrapped app, especially under KDE Wayland. | Medium | Prefer compatibility with the host's `xdg-desktop-portal` stack instead of custom hacks. |
| Repeatable startup behavior with app-local fallbacks | Mature repair layers must get from “sometimes launches” to “launches the same way every time,” including conservative defaults for problematic apps. | Medium | For Zotero this means choosing the less modern but more stable path if necessary. |
| Safe desktop cache refresh after wrapper generation | New or modified launchers need to show up in Plasma reliably after a switch. | Low | Existing `update-desktop-database` and `kbuildsycoca` refresh behavior covers this, but it is still a required capability. |

## Differentiators

Features that improve maintainability, diagnosis, and future repairs. Useful, but not required for basic app usability.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Per-app repair profiles with named modes | Makes repairs maintainable by encoding known-good modes such as `wayland`, `xwayland-safe`, or `debug`. | Medium | Better than ad hoc one-off env var edits. Especially useful for QQ/Zotero where multiple launch strategies may need quick comparison. |
| Opt-in diagnostics mode for wrapped apps | Lets the user flip on Electron logging, verbose env dumps, crash-related flags, and wrapper tracing without editing package definitions each time. | Medium | Strong differentiator because this repo currently lacks a proper validation/diagnostics pipeline. |
| App capability metadata in the catalog | Storing whether an app is Electron, Qt, GTK, or X11-only enables standardized repair presets and reduces repeated bespoke logic. | Medium | Best implemented as data in the app catalog, not hand-coded branches scattered across modules. |
| Detection-oriented verification commands | A mature repair layer should help answer “is this app running on Wayland or XWayland?” and “what flags/env were applied?” quickly. | Medium | Useful for KDE Wayland debugging and regression checks after `home-manager switch`. |
| Health checks for generated desktop artifacts | Validate that rewritten `Exec=`, D-Bus service paths, MIME entries, and desktop IDs still point to wrapped binaries. | Medium | Directly addresses fragile desktop-file rewriting noted in `CONCERNS.md`. |
| Crash- and startup-repair annotations per app | Captures learned workarounds near the app definition so future repairs do not rediscover the same failure modes. | Low | High maintenance value for a personal desktop config with brownfield history. |
| Controlled fallback matrix for graphics and renderer quirks | Supports app-local switches like GTK renderer fallback, Qt rounding policy, or XWayland fallback without contaminating the whole session. | Medium | Helps contain blast radius when one app needs a non-default rendering path. |
| Regression test coverage for wrappers and launchers | Turns compatibility knowledge into guardrails so refactors in `nixgl-apps.nix` do not silently break every app. | High | Important differentiator for maintainability, though not strictly needed to make one app work today. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Global session-wide Wayland or X11 forcing for all apps | Different apps need opposite fixes. A global switch would solve one class of problems by breaking another. | Keep backend choice per app, with minimal shared defaults. |
| Rewriting the whole nixGL/Home Manager architecture for this milestone | The project is a brownfield repair effort, not a platform rewrite. | Patch the existing seams in `nixgl-apps.nix`, `modules/nixgl-runtime.nix`, and desktop integration modules. |
| One-off imperative shell hacks outside declarative config | Manual launch scripts drift, are hard to reproduce, and break the repository's value proposition. | Encode repairs as declarative wrapper metadata and generated scripts. |
| Promise of universal native Wayland for every app | Some legacy/bundled-toolkit apps are more stable on XWayland. Treating native Wayland as mandatory causes churn. | Prefer native Wayland when verified stable; otherwise standardize XWayland fallback. |
| Custom clipboard daemon as the first-line solution | Clipboard failures may come from app/toolkit/backend mismatch, not just clipboard persistence. A new daemon adds complexity and may miss the root cause. | First provide backend selection, per-app env/flag tuning, and portal/session verification; add clipboard persistence only if evidence shows source-app ownership loss is the problem. |
| Blanket disabling of sandboxing or security features | Flags like `--no-sandbox` can mask packaging issues while increasing risk and diverging from normal runtime behavior. | Use the narrowest app-specific workaround that is required and document why. |
| Sprawling per-app special cases mixed with generator logic | `nixgl-apps.nix` is already too mixed in responsibility. More ad hoc branches will make repairs slower and riskier. | Keep shared generator logic generic and move app-specific repair data into structured catalog fields. |

## Feature Dependencies

```text
Stable GPU and GL/Vulkan wrapping -> Repeatable startup behavior
Per-app backend selection -> Clipboard-safe launch modes and mitigations
Per-app backend selection -> Repeatable startup behavior with app-local fallbacks
Per-app launch flags and environment overrides -> Per-app backend selection
Per-app launch flags and environment overrides -> Input method and IME propagation into wrapped apps
Per-app launch flags and environment overrides -> D-Bus and portal-visible session integration
Desktop entry and MIME correctness for wrapped apps -> Repeatable startup behavior with app-local fallbacks
Desktop entry and MIME correctness for wrapped apps -> Safe desktop cache refresh after wrapper generation
Per-app repair profiles with named modes -> Opt-in diagnostics mode for wrapped apps
App capability metadata in the catalog -> Per-app repair profiles with named modes
App capability metadata in the catalog -> Controlled fallback matrix for graphics and renderer quirks
Health checks for generated desktop artifacts -> Regression test coverage for wrappers and launchers
Detection-oriented verification commands -> Opt-in diagnostics mode for wrapped apps
```

## MVP Recommendation

Prioritize:
1. Per-app backend selection between native Wayland and XWayland
2. Per-app launch flags and environment overrides
3. Clipboard-safe launch modes and mitigations
4. Repeatable startup behavior with app-local fallbacks
5. Desktop entry and MIME correctness for wrapped apps

Defer: Regression test coverage for wrappers and launchers: high value, but it should follow after the repo has encoded the known-good repair modes for QQ and Zotero.

## Sources

- Project context: `/home/mingshi/.config/home-manager/.planning/PROJECT.md` (HIGH confidence)
- Codebase constraints: `/home/mingshi/.config/home-manager/.planning/codebase/CONCERNS.md` (HIGH confidence)
- Repo structure: `/home/mingshi/.config/home-manager/.planning/codebase/STRUCTURE.md` (HIGH confidence)
- Existing wrapper implementation: `/home/mingshi/.config/home-manager/nixgl-apps.nix` (HIGH confidence)
- Existing nixGL runtime wiring: `/home/mingshi/.config/home-manager/modules/nixgl-runtime.nix` (HIGH confidence)
- Existing desktop integration behavior: `/home/mingshi/.config/home-manager/modules/desktop-entries.nix` (HIGH confidence)
- nixGL README: https://github.com/nix-community/nixGL (MEDIUM confidence: official upstream README, not versioned docs)
- XDG Desktop Portal docs index: https://flatpak.github.io/xdg-desktop-portal/docs/ (HIGH confidence)
- XDG Desktop Portal Clipboard API: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Clipboard.html (HIGH confidence)
- XDG Desktop Portal FileChooser API: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.FileChooser.html (HIGH confidence)
- Electron supported command-line switches: https://www.electronjs.org/docs/latest/api/command-line-switches (HIGH confidence)
- Qt Wayland documentation: https://doc.qt.io/qt-6/wayland-and-qt.html (HIGH confidence)
- ArchWiki Wayland overview and toolkit notes: https://wiki.archlinux.org/title/Wayland (LOW confidence for ecosystem guidance; used only as secondary operational context)
