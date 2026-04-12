# WPS XWayland Default Design

## Goal

Make `wpsoffice-cn` start through a repo-managed XWayland-safe wrapper by default on the current Fedora KDE Wayland machine, without changing the upstream package itself.

## Problem

- `wpsoffice-cn` is currently installed directly from `modules/packages.nix`.
- It is not part of the existing managed app wrapper pipeline in `nixgl-apps.nix`.
- Desktop launch currently goes through upstream entries such as `wps-office-prometheus.desktop`, which execute the upstream `bin/wps` script directly.
- Crash evidence shows `wpsoffice /prometheus` segfaulting during Qt XCB platform initialization.

## Recommended Approach

Use a small repo-managed wrapper layer for WPS and route default launch surfaces through it.

### Scope

- Keep `pkgs.wpsoffice-cn` unchanged.
- Generate wrapper scripts for the default WPS launch surfaces.
- Force `QT_QPA_PLATFORM=xcb` in those wrappers so WPS launches through XWayland by default.
- Override desktop entries so launcher and file association paths use the wrapper instead of upstream `bin/wps` or `bin/wpspdf` directly.

## Design

### Components

1. A new focused module, likely `modules/wps.nix`
2. Wrapper scripts generated into `~/.local/bin/`
3. Home Manager desktop entry overrides for WPS launcher surfaces

### Initial Surfaces

- `wps`
- `wpspdf`

These are the minimum surfaces needed to fix the default office launcher and the PDF launcher. Additional WPS subcommands can be added later if needed.

### Wrapper Behavior

Each wrapper should:

1. Export `QT_QPA_PLATFORM=xcb`
2. Execute the upstream WPS command with original arguments preserved

Example shape:

```bash
#!/usr/bin/env bash
set -euo pipefail
export QT_QPA_PLATFORM=xcb
exec /nix/store/...-wpsoffice-cn.../bin/wps "$@"
```

### Desktop Behavior

Override the relevant desktop entries so they use the managed wrappers, not the upstream executables.

The intended result is:

- menu launch uses wrapper
- file association launch uses wrapper
- shell launch via `wps` and `wpspdf` uses wrapper

## Why This Approach

- Minimal change surface
- Matches the repository's existing Home Manager managed-launch pattern
- Does not force global Qt X11 behavior onto unrelated applications
- Avoids mixing this WPS-specific Qt/XWayland issue into the existing nixGL app catalog unless later needed

## Rejected Alternatives

### Global Qt X11 override

Rejected because it would affect unrelated Qt applications and could regress apps already tuned for Wayland.

### Full migration into `nixgl-apps.nix`

Rejected for now because the current issue is not primarily a nixGL problem. The smallest correct change is a focused WPS wrapper layer.

## Verification

Implementation should be considered correct only if all of the following are true:

1. Managed wrapper files for `wps` and `wpspdf` exist under `~/.local/bin/`
2. Wrapper content includes `QT_QPA_PLATFORM=xcb`
3. Managed desktop entries point to those wrappers
4. Default launch no longer goes directly to upstream `bin/wps` / `bin/wpspdf`

## Open Question

If WPS still crashes after forcing `QT_QPA_PLATFORM=xcb`, the next diagnostic step is to test whether the global fcitx Qt input-method environment also needs to be locally neutralized for WPS. That is explicitly out of scope for this first fix.
