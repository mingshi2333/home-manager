# WPS XWayland Default Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make WPS launch through repo-managed wrappers that force `QT_QPA_PLATFORM=xcb`, so the default WPS and WPS PDF launch surfaces use XWayland on this Fedora KDE Wayland machine.

**Architecture:** Add a focused `modules/wps.nix` module that generates wrapper scripts under `~/.local/bin` and overrides the relevant desktop entries through Home Manager. Keep `pkgs.wpsoffice-cn` installed as-is, but route user-visible launch surfaces through managed wrappers instead of upstream desktop `Exec` lines.

**Tech Stack:** Nix, Home Manager, XDG desktop entries, shell wrapper scripts

---

### Task 1: Add a failing regression test for managed WPS launch surfaces

**Files:**
- Create: `tests/wps-wrapper.sh`
- Test: `tests/wps-wrapper.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

wps_script=$(cd "$repo_root" && nix eval --raw '.#homeConfigurations.mingshi.config.home.file.".local/bin/wps".text')
wpspdf_script=$(cd "$repo_root" && nix eval --raw '.#homeConfigurations.mingshi.config.home.file.".local/bin/wpspdf".text')
wps_desktop=$(cd "$repo_root" && nix eval --raw '.#homeConfigurations.mingshi.config.xdg.desktopEntries."wps-office-prometheus".exec')
wpspdf_desktop=$(cd "$repo_root" && nix eval --raw '.#homeConfigurations.mingshi.config.xdg.desktopEntries."wps-office-pdf".exec')

assert_contains() {
  local text=$1
  local pattern=$2
  local message=$3

  if ! printf '%s\n' "$text" | grep -Eq "$pattern"; then
    echo "$message" >&2
    exit 1
  fi
}

assert_contains "$wps_script" 'QT_QPA_PLATFORM=xcb' 'expected WPS wrapper to force xcb'
assert_contains "$wpspdf_script" 'QT_QPA_PLATFORM=xcb' 'expected WPS PDF wrapper to force xcb'
assert_contains "$wps_desktop" '^/home/mingshi/.local/bin/wps( |$)' 'expected WPS desktop entry to use managed wrapper'
assert_contains "$wpspdf_desktop" '^/home/mingshi/.local/bin/wpspdf( |$)' 'expected WPS PDF desktop entry to use managed wrapper'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/wps-wrapper.sh`
Expected: FAIL because `.local/bin/wps`, `.local/bin/wpspdf`, or the desktop entry overrides do not exist yet.

- [ ] **Step 3: Commit the red test only if your workflow requires checkpointing**

```bash
git add tests/wps-wrapper.sh
git commit -m "test: add WPS wrapper regression coverage"
```

### Task 2: Add the WPS wrapper module

**Files:**
- Create: `modules/wps.nix`
- Modify: `profiles/gui.nix`
- Test: `tests/wps-wrapper.sh`

- [ ] **Step 1: Create the minimal WPS module implementation**

```nix
{ config, pkgs, ... }:

let
  wpsPackage = pkgs.wpsoffice-cn;
  wpsBin = "${wpsPackage}/bin/wps";
  wpsPdfBin = "${wpsPackage}/bin/wpspdf";
in
{
  home.file = {
    ".local/bin/wps" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        export QT_QPA_PLATFORM=xcb
        exec ${wpsBin} "$@"
      '';
      executable = true;
    };

    ".local/bin/wpspdf" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        export QT_QPA_PLATFORM=xcb
        exec ${wpsPdfBin} "$@"
      '';
      executable = true;
    };
  };
}
```

- [ ] **Step 2: Import the module through the GUI profile**

Update `profiles/gui.nix` so the imports list includes `../modules/wps.nix` alongside the existing GUI modules.

```nix
{ ... }:

{
  imports = [
    ../modules/plasma.nix
    ../modules/desktop-entries.nix
    ../modules/wps.nix
  ];
}
```

- [ ] **Step 3: Run the regression test to confirm it still fails for desktop wiring**

Run: `bash tests/wps-wrapper.sh`
Expected: wrapper assertions pass, desktop entry assertions still fail because `xdg.desktopEntries` has not been overridden yet.

- [ ] **Step 4: Commit the wrapper module checkpoint**

```bash
git add modules/wps.nix profiles/gui.nix tests/wps-wrapper.sh
git commit -m "feat: add managed WPS launch wrappers"
```

### Task 3: Override WPS desktop entries to use the managed wrappers

**Files:**
- Modify: `modules/wps.nix`
- Test: `tests/wps-wrapper.sh`

- [ ] **Step 1: Add desktop entry overrides to the WPS module**

Extend `modules/wps.nix` with explicit desktop entry overrides.

```nix
{ config, pkgs, ... }:

let
  wpsPackage = pkgs.wpsoffice-cn;
  homeDir = config.home.homeDirectory;
  wpsWrapper = "${homeDir}/.local/bin/wps";
  wpsPdfWrapper = "${homeDir}/.local/bin/wpspdf";
in
{
  home.file = {
    ".local/bin/wps" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        export QT_QPA_PLATFORM=xcb
        exec ${wpsPackage}/bin/wps "$@"
      '';
      executable = true;
    };

    ".local/bin/wpspdf" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        export QT_QPA_PLATFORM=xcb
        exec ${wpsPackage}/bin/wpspdf "$@"
      '';
      executable = true;
    };
  };

  xdg.desktopEntries = {
    "wps-office-prometheus" = {
      name = "WPS Office";
      genericName = "WPS Office";
      comment = "Use WPS Office through the managed XWayland wrapper";
      exec = "${wpsWrapper} %F";
      terminal = false;
      type = "Application";
      categories = [ "WordProcessor" "Qt" ];
      icon = "wps-office2023-kprometheus";
      startupNotify = false;
      settings = {
        StartupWMClass = "wpsoffice";
        InitialPreference = "3";
      };
    };

    "wps-office-pdf" = {
      name = "WPS PDF";
      genericName = "Kingsoft Pdf Reader";
      comment = "Use WPS PDF through the managed XWayland wrapper";
      exec = "${wpsPdfWrapper} %F";
      terminal = false;
      type = "Application";
      categories = [ "WordProcessor" "Qt" ];
      icon = "wps-office2023-pdfmain";
      startupNotify = false;
      mimeType = [ "application/pdf" ];
      settings = {
        StartupWMClass = "wpspdf";
        InitialPreference = "3";
      };
    };
  };
}
```

- [ ] **Step 2: Run the regression test to verify it passes**

Run: `bash tests/wps-wrapper.sh`
Expected: PASS with no output.

- [ ] **Step 3: Run a Home Manager eval/build verification**

Run: `nix run .#home-manager -- build --flake .`
Expected: build succeeds and generates updated home files.

- [ ] **Step 4: Commit the desktop override change**

```bash
git add modules/wps.nix tests/wps-wrapper.sh
git commit -m "fix: default WPS to xwayland wrapper"
```

### Task 4: Activate and verify the managed WPS surfaces

**Files:**
- Modify: none
- Test: `tests/wps-wrapper.sh`

- [ ] **Step 1: Activate the Home Manager configuration**

Run: `nix run .#home-manager -- switch --flake .`
Expected: activation succeeds and refreshes desktop metadata.

- [ ] **Step 2: Verify the wrapper files exist in the home directory**

Run: `readlink -f ~/.local/bin/wps ~/.local/bin/wpspdf`
Expected: both resolve into the current Home Manager generation.

- [ ] **Step 3: Verify the wrapper content in the activated home**

Run: `sed -n '1,20p' ~/.local/bin/wps ~/.local/bin/wpspdf`
Expected: each script contains `QT_QPA_PLATFORM=xcb` and executes the upstream WPS binary.

- [ ] **Step 4: Verify the desktop entry exec lines in the activated home**

Run: `grep -E '^Exec=' ~/.nix-profile/share/applications/wps-office-prometheus.desktop ~/.nix-profile/share/applications/wps-office-pdf.desktop`
Expected: `Exec=` lines point to `/home/mingshi/.local/bin/wps` and `/home/mingshi/.local/bin/wpspdf`.

- [ ] **Step 5: Manual smoke check**

Run:

```bash
QT_LOGGING_RULES='*.debug=false' ~/.local/bin/wps
QT_LOGGING_RULES='*.debug=false' ~/.local/bin/wpspdf
```

Expected: WPS starts through XWayland instead of crashing immediately during the previous default Wayland session path.
