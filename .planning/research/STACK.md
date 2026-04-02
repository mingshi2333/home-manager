# Technology Stack

**Project:** Fedora KDE Wayland desktop application compatibility repairs
**Researched:** 2026-04-02

## Recommended Stack

### Core Runtime Strategy

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Home Manager (existing repo pattern) | current flake input | Declarative user-level environment, wrappers, desktop entries, `environment.d`, and app-specific launch policy | This repo already centralizes desktop app behavior in Home Manager modules and `nixgl-apps.nix`; repairs should stay there instead of introducing ad hoc shell scripts. Confidence: HIGH |
| `nixGL` NVIDIA wrapper (`nixGLNvidia-*`) | current pinned input | Bridge Nix-packaged GUI apps to Fedora host GL/Vulkan/NVIDIA userspace | On non-NixOS Fedora, this remains the standard fix for OpenGL/Vulkan loader mismatch. It is necessary for Electron, Qt, GTK, and embedded Chromium apps that otherwise pick incompatible GL libraries. Confidence: HIGH |
| Fedora KDE Wayland session with XWayland available | Fedora/KDE host-provided | Primary compositor/runtime target, with compatibility fallback for apps that still regress on native Wayland | 2025-era practice is to prefer native Wayland where app/toolkit support is mature, but keep XWayland available for legacy Electron/Firefox/XUL and some Qt edge cases. Confidence: HIGH |
| `xdg-desktop-portal` + `xdg-desktop-portal-kde` | host package / user service | File chooser, URI open, clipboard/screencast integration, and desktop-consistent dialogs for sandbox-aware toolkits | Portal correctness is now part of a stable Wayland desktop, not optional polish. KDE should be the primary backend on Plasma. Confidence: HIGH |

### Application Runtime Layers

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Native Wayland Electron/Ozone launch profile | Electron 30+ era behavior | Default launch mode for Electron apps that behave correctly on Plasma Wayland | Upstream Electron documents Wayland/Ozone flags and NixOS guidance notes that modern Electron/Chromium increasingly default to native Wayland in Wayland sessions. In this repo, `qq`, `wechat`, `podman-desktop`, and `element-desktop` should use an explicit native Wayland wrapper profile rather than relying on ambient host state. Confidence: HIGH |
| Selective XWayland fallback profile for Electron | per-app fallback | Stabilize apps with broken clipboard, IME, drag/drop, tray, or GPU behavior under native Wayland | The standard repair pattern in 2025 is not “force everything to Wayland”; it is “default to Wayland, fall back per app when behavior proves worse.” This is especially important for proprietary Electron builds that lag upstream Chromium fixes. Confidence: HIGH |
| Native Qt Wayland profile (`QT_QPA_PLATFORM=wayland`) | Qt 6 app class | Run modern Qt apps as Wayland clients when they are healthy on Plasma | Qt upstream supports Wayland natively and Plasma is the best-supported desktop for Qt-native Wayland behavior. Confidence: HIGH |
| Qt XCB fallback profile (`QT_QPA_PLATFORM=xcb`) | per-app fallback | Stabilize Qt apps or QtWebEngine apps that regress under native Wayland | Qt upstream still documents `xcb` as the X11 platform plugin, and XWayland remains the safe fallback for apps with compositor-specific problems. Confidence: HIGH |
| Fcitx5 session env propagation | current host/runtime | Keep IME behavior consistent across wrapped apps, especially Electron and Qt | Input method breakage on Wayland is often an environment propagation problem, not an app bug. This repo already models shared `fcitxEnv`; keep that as a first-class runtime layer. Confidence: HIGH |

### Environment Variables and Wrapper Policy

| Setting / Layer | Use | Why |
|-----------------|-----|-----|
| `NIXOS_OZONE_WL=1` | Keep as a global default in Wayland sessions | Nix ecosystem guidance still treats this as the standard declarative switch for Chromium/Electron Ozone Wayland behavior. It matches the repo’s current model. Confidence: HIGH |
| `ELECTRON_OZONE_PLATFORM_HINT=wayland` | Keep as default for Electron Wayland wrapper profile | Makes launcher intent explicit for wrapped apps instead of depending on toolkit heuristics. Confidence: HIGH |
| `--ozone-platform-hint=wayland` | Add in Electron Wayland wrappers | Electron documents Chromium flags, and explicit flags are more reliable than environment-only behavior for packaged proprietary builds. Confidence: HIGH |
| `--enable-wayland-ime` | Add in Electron Wayland wrappers that need text input stability | This is still a standard Linux/Electron flag for Wayland IME support and belongs in the explicit Wayland wrapper profile. Confidence: MEDIUM-HIGH |
| `QT_QPA_PLATFORM=wayland` | Use only in a dedicated Qt Wayland profile | Correct for Qt apps that are known-good on Plasma Wayland. Do not set globally for every app. Confidence: HIGH |
| `QT_QPA_PLATFORM=xcb` | Use as app-specific fallback, not global default | Needed for breakage cases, but forcing all Qt apps to X11 would throw away Plasma Wayland gains. Confidence: HIGH |
| `GTK_USE_PORTAL=1` and `NIXOS_XDG_OPEN_USE_PORTAL=1` | Keep globally | Good fit for Plasma Wayland and already present in the repo. They reduce host integration drift for file chooser and open-URI behavior. Confidence: HIGH |
| `XDG_CURRENT_DESKTOP=KDE` in user activation environment | Verify it reaches `systemd --user` and D-Bus activation env | Portal backend selection depends on activation environment, not just the interactive shell. This matters for app launches and service-activated portals. Confidence: HIGH |
| `WAYLAND_DISPLAY`, `XDG_SESSION_TYPE`, `XDG_DATA_DIRS`, `PATH` | Ensure they propagate into `systemd --user` and D-Bus activation env | Portal docs explicitly require correct activation environment. Missing propagation is a common root cause of “works in terminal, fails from desktop entry.” Confidence: HIGH |

### System Integration Points

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `~/.config/environment.d/*.conf` via Home Manager | current repo pattern | Make app env visible to desktop-launched processes and user services | This repo already uses `environment.d`; it is the correct place for cross-session desktop variables. Confidence: HIGH |
| App-specific wrapper scripts in `nixgl-apps.nix` | current repo pattern | Encode launch mode, env, flags, desktop entries, aliases, and MIME behavior per app | Stability work belongs in per-app wrapper metadata, not scattered shell aliases. Confidence: HIGH |
| `.desktop` entries rewritten to wrapper executables | current repo pattern | Ensure GUI launches use the same compatibility path as terminal launches | Without this, fixes only apply when launched manually. Confidence: HIGH |
| `portals.conf` override only if KDE backend selection is wrong | optional override | Force Plasma to use KDE backend and GTK fallback only when host auto-selection is incorrect | Use this only as a repair tool, not a default complexity increase. Confidence: MEDIUM-HIGH |
| Host-level Fedora packages for portals and clipboard/IME integration | host-managed | Supply missing non-Nix pieces that Nix apps expect from the desktop session | `nixGL` solves GL loader mismatch, not missing host desktop services. Confidence: HIGH |

## Prescriptive Recommendation For This Repo

Use a four-layer runtime stack:

1. **Host desktop layer:** Fedora KDE Plasma Wayland with `xdg-desktop-portal` and `xdg-desktop-portal-kde` installed and healthy, XWayland enabled, Fcitx5 working in the session.
2. **Session propagation layer:** Home Manager-owned `environment.d` plus any necessary import into `systemd --user` / D-Bus activation environment so portals and desktop-activated services see the same values as shell launches.
3. **Graphics compatibility layer:** existing `local.nixgl.package` / `nixGLNvidia-*` wrapper retained as the only GL bridge for Nix GUI apps on Fedora.
4. **Per-app launcher layer:** app-specific wrapper profiles in `nixgl-apps.nix` selecting one of three modes: `electron-wayland`, `electron-xwayland`, `qt-wayland`, or `qt-xcb`.

That is the standard 2025-era repair shape for this codebase. Do not try to fix all apps with one global environment toggle. Make the compositor choice explicit per app.

## App Class Recommendations

### Electron / Chromium-family apps

Use **native Wayland by default** for apps that already behave on Plasma:

- `NIXOS_OZONE_WL=1`
- `ELECTRON_OZONE_PLATFORM_HINT=wayland`
- `--ozone-platform-hint=wayland`
- `--enable-wayland-ime`

Use **XWayland fallback** for apps with any of these symptoms:

- clipboard sync corruption
- repeated stale paste contents
- broken tray/window activation behavior
- broken drag/drop or global shortcuts
- GPU crashes only on Wayland

For the current repo, `qq` should not be considered permanently correct just because it starts under Wayland. The reported clipboard corruption is exactly the kind of bug that justifies a first-class fallback profile. Repair plan: keep a Wayland profile available, but add a repo-supported XWayland fallback path and compare behavior under both before standardizing.

### Qt / QtWebEngine apps

Use **native Qt Wayland** only for apps verified healthy on Plasma Wayland.

Use **`QT_QPA_PLATFORM=xcb` fallback** for apps with launch instability, input issues, rendering corruption, or crashy QtWebEngine behavior. For this repo, `zotero` being pinned to X11 is directionally correct as a stabilization tactic. Given the existing `SIGSEGV` history, the immediate stack recommendation is to keep Zotero on the fallback profile first, then investigate whether the crash is GPU, sandbox, plugin, or IM module related.

### GTK apps through `nixGL`

Keep portal integration and avoid over-tuning. GTK apps on Plasma often need working portal/backend selection more than display backend forcing. If font/file chooser issues appear, verify `xdg-desktop-portal-kde` plus `xdg-desktop-portal-gtk` fallback presence before changing launcher flags.

## What Not To Use

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Electron strategy | Per-app Wayland or XWayland wrapper mode | One global `ELECTRON_OZONE_PLATFORM_HINT=wayland` and no per-app override | Too blunt. It hides app-specific regressions and makes proprietary Electron builds harder to stabilize. Confidence: HIGH |
| Qt strategy | Per-app `QT_QPA_PLATFORM` selection | Global `QT_QPA_PLATFORM=wayland` for the whole session | Breaks legacy Qt/X11 apps and makes fallback impossible without wrapper surgery. Confidence: HIGH |
| Graphics bridge | `nixGL` wrapper around the app executable | `LD_LIBRARY_PATH` hacks alone | `nixGL` exists specifically to solve host GL loader compatibility; partial library hacks are brittle and incomplete. Confidence: HIGH |
| Portal backend selection | KDE backend by default, optional targeted override | Forcing GTK backend globally on Plasma | Wrong desktop integration layer for a KDE host; use GTK fallback only for interfaces or apps that demonstrably need it. Confidence: HIGH |
| Repair method | Declarative wrapper metadata in `nixgl-apps.nix` | Manual one-off shell aliases or launching apps from a terminal with custom exports | Not reproducible from `.desktop` launches and not roadmap-worthy. Confidence: HIGH |
| Sandbox workaround | Use only when a specific app is proven to need it | Blanket `--no-sandbox` or `QTWEBENGINE_DISABLE_SANDBOX=1` everywhere | This masks root causes and expands blast radius. Keep exceptions narrow and documented. Confidence: HIGH |

## Recommended Repo Changes To Plan

1. Refactor `nixgl-apps.nix` to support explicit runtime profiles instead of a binary `platform = "wayland" | "x11"` toggle.
2. Introduce named profiles such as `electron-wayland`, `electron-xwayland`, `qt-wayland`, `qt-xcb`, and `gtk-default`.
3. Keep global portal-related environment variables in `modules/environment.nix`, but move app-specific display/toolkit behavior fully into wrappers.
4. Add user-environment verification for `XDG_CURRENT_DESKTOP`, `WAYLAND_DISPLAY`, `XDG_DATA_DIRS`, and `PATH` so desktop-activated portals see correct values.
5. Treat `qq` and `zotero` as first repair candidates with side-by-side wrapper modes instead of assuming the current modes are final.

## Suggested Runtime Profiles

| Profile | Wrapper Settings | Use For |
|---------|------------------|---------|
| `electron-wayland` | `NIXOS_OZONE_WL=1`, `ELECTRON_OZONE_PLATFORM_HINT=wayland`, `--ozone-platform-hint=wayland`, `--enable-wayland-ime` | Electron apps verified stable on Plasma Wayland |
| `electron-xwayland` | unset/override Wayland-specific Electron flags, allow X11 path | Electron apps with clipboard, tray, GPU, or IME regressions on Wayland |
| `qt-wayland` | `QT_QPA_PLATFORM=wayland` | Modern Qt apps verified stable on Plasma Wayland |
| `qt-xcb` | `QT_QPA_PLATFORM=xcb` | Qt/QtWebEngine apps with Wayland launch/render/input instability |
| `gtk-default` | `GTK_USE_PORTAL=1`, no forced display backend unless needed | GTK apps on Plasma |

## Installation

```bash
# Core flake inputs already present in this repo
# Host Fedora packages to ensure exist outside Nix
sudo dnf install xdg-desktop-portal xdg-desktop-portal-kde xwayland

# Optional fallback backend for GTK file pickers and edge cases on Plasma
sudo dnf install xdg-desktop-portal-gtk
```

## Confidence Notes

- **HIGH:** `nixGL` remains the right non-NixOS GL compatibility layer.
- **HIGH:** KDE portal backend is the correct primary backend on Fedora Plasma Wayland.
- **HIGH:** Native Wayland should be default for healthy Electron apps, but not universal.
- **HIGH:** Per-app wrapper policy is better than global session forcing.
- **MEDIUM-HIGH:** `--enable-wayland-ime` should remain part of the Electron Wayland profile; upstream Electron documents the flag class, but app-specific behavior still varies.
- **MEDIUM:** Zotero-specific root cause for the observed crash is not proven by upstream docs alone; keeping X11 fallback is justified, but the exact crash mechanism still needs phase-specific debugging.

## Sources

- Electron command-line switches: https://www.electronjs.org/docs/latest/api/command-line-switches
- Electron environment variables: https://www.electronjs.org/docs/latest/api/environment-variables
- Qt Wayland overview: https://doc.qt.io/qt-6/wayland-and-qt.html
- Qt Linux platform dependencies: https://doc.qt.io/qt-6/linux-requirements.html
- XDG Desktop Portal docs: https://flatpak.github.io/xdg-desktop-portal/docs/
- XDG Desktop Portal system integration: https://flatpak.github.io/xdg-desktop-portal/docs/system-integration.html
- XDG Desktop Portal `portals.conf`: https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html
- ArchWiki `XDG Desktop Portal` overview and Plasma backend matrix: https://wiki.archlinux.org/title/XDG_Desktop_Portal
- nixGL README: https://github.com/nix-community/nixGL
- NixOS Wiki `Wayland` page noting 2025-era Chromium/Electron Wayland defaults: https://wiki.nixos.org/wiki/Wayland
