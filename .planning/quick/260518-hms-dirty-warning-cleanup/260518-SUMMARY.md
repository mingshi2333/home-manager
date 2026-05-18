---
phase: quick
plan: 260518
subsystem: home-manager-hms
tags: [home-manager, hms, nixgl, codex-desktop, cleanup]
dependency_graph:
  requires: []
  provides: [hms-clean-switch, codex-desktop-lock-follow, generated-symlink-ignore]
  affects:
    - flake.nix
    - flake.lock
    - modules/desktop-entries.nix
    - ops/hms-refresh.sh
    - .gitignore
    - nvidia/version
    - tests/hms-aliases.sh
key_files:
  created:
    - .planning/quick/260518-hms-dirty-warning-cleanup/260518-PLAN.md
    - .planning/quick/260518-hms-dirty-warning-cleanup/260518-SUMMARY.md
  modified:
    - .gitignore
    - flake.nix
    - flake.lock
    - modules/desktop-entries.nix
    - ops/hms-refresh.sh
    - nvidia/version
    - tests/hms-aliases.sh
  removed_from_git_tracking:
    - result
    - zsh-extra.sh
decisions:
  - Keep the currently successful nixpkgs/home-manager baseline instead of rolling it back; tighten Codex Desktop follow wiring so no extra nixpkgs node is introduced.
  - Treat result and zsh-extra.sh as generated symlinks; remove them from git tracking and ignore them.
  - Remove stale Home Manager current-home gcroot because it pointed at a January generation and caused repeated orphan cleanup warnings.
metrics:
  completed: "2026-05-18T00:41:03Z"
  tasks_completed: 5
  tasks_total: 5
  committed: false
---

# Quick Fix 260518: hms dirty warning cleanup

**One-liner:** `hms` now completes without the old orphan-link warnings, generated metadata no longer trips `git diff --check`, Codex Desktop follows the repo nixpkgs, and generated symlinks are no longer tracked.

## What Was Done

- Added `codex-desktop-linux.inputs.nixpkgs.follows = "nixpkgs"` and `inputs.flake-utils.follows = "nixgl/flake-utils"` so the lock graph has one root nixpkgs node.
- Regenerated `flake.lock` with `nix flake lock`; current root `nixpkgs` remains `d233902339c02a9c334e7e593de68855ad26c4cb`.
- Normalized `ops/hms-refresh.sh` so `nvidia/version` is copied through trailing-whitespace stripping.
- Cleaned current `nvidia/version` trailing whitespace.
- Updated `modules/desktop-entries.nix` so profile desktop files do not replace Home Manager managed desktop entries.
- Removed tracked generated symlinks `result` and `zsh-extra.sh` from the git index and added them to `.gitignore`.
- Made `tests/hms-aliases.sh` executable.
- Removed stale live gcroot `~/.local/state/home-manager/gcroots/current-home`; it pointed at an old January generation and caused repeated orphan cleanup warnings for already-removed paths.

## Verification

- `git diff --check` exits 0.
- `./tests/hms-aliases.sh` exits 0.
- `nix eval --raw .#homeConfigurations.mingshi.activationPackage.drvPath` exits 0.
- `nix flake metadata --json .` shows root `nixpkgs = "nixpkgs"` and no `nixpkgs_2`.
- `~/.local/bin/hms` exits 0.
- The final `hms` output no longer includes the old:
  - `/home/mingshi/.local/bin/qq`
  - `/home/mingshi/.local/share/applications/lenovo-legion-gui-pkexec.desktop`
  - `/home/mingshi/.config/environment.d/20-electron-wayland.conf`

## Commit

No commit was created. The worktree already contained related but pre-existing Codex Desktop/Home Manager edits, so committing now would mix this cleanup with earlier uncommitted work.

