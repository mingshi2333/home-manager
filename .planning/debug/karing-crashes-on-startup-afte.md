---
status: investigating
trigger: "/gsd:debug karing crashes on startup after being packaged from upstream AppImage in Home Manager. Investigate the current local package definition, reproduce the startup failure on Fedora KDE Wayland, identify the minimal runtime/package fix, implement it, and verify whether karing can launch successfully."
created: 2026-04-03T00:00:00Z
updated: 2026-04-03T00:27:00Z
---

## Current Focus

hypothesis: the Nix-generated appimageTools wrapper is the differentiator; either its sandbox/container helper crashes, or it launches karing with an incompatible library search path
test: trace the generated wrapper execution and compare it with direct AppRun behavior
expecting: wrapper tracing will show whether the segfault happens in bubblewrap/container-init or after handoff to karing
next_action: rerun the generated wrapper under bash -x with corrected shell capture and inspect the final executed command

## Symptoms

expected: karing launches successfully after being packaged from upstream AppImage in Home Manager
actual: karing crashes on startup after packaging from upstream AppImage in Home Manager
errors: unknown
reproduction: launch the packaged karing app on Fedora KDE Wayland
started: after packaging from upstream AppImage in Home Manager

## Eliminated

## Evidence

- timestamp: 2026-04-03T00:04:30Z
  checked: .planning/debug/knowledge-base.md
  found: knowledge base file does not exist yet
  implication: no prior resolved pattern is available for this bug

- timestamp: 2026-04-03T00:04:30Z
  checked: repository search for karing
  found: repository contains a dedicated package definition at karing.nix
  implication: the startup failure likely originates in that local package or its integration

- timestamp: 2026-04-03T00:06:30Z
  checked: karing.nix
  found: karing is packaged with appimageTools.wrapType2 from upstream AppImage version 1.2.15.1806, with extraPkgs limited to libepoxy and zstd, and the desktop entry Exec line rewritten to plain karing
  implication: if the AppImage expects additional system libraries or environment variables, the current wrapper may be incomplete

- timestamp: 2026-04-03T00:06:30Z
  checked: modules/packages.nix references
  found: Home Manager includes karing via pkgs.callPackage ../karing.nix { } and adds it to home.packages
  implication: reproducing the issue can be done by building this local derivation directly

- timestamp: 2026-04-03T00:09:45Z
  checked: nix build .#homeConfigurations.mingshi.config.home.packages
  found: build command failed because home.packages is a list attribute, not a derivation
  implication: need to build the karing derivation directly rather than through the aggregate Home Manager package list

- timestamp: 2026-04-03T00:11:15Z
  checked: direct build of pkgs.callPackage ./karing.nix {}
  found: the derivation builds successfully to /nix/store/70w5592wkfj9wy3hkbl93py2f99mc9ig-karing-1.2.15.1806
  implication: the issue is not a build-time packaging failure but a runtime launch failure

- timestamp: 2026-04-03T00:11:30Z
  checked: direct execution of the built karing binary
  found: process exits with code 139 and no user-facing stderr output
  implication: the app is crashing with a segmentation fault very early in startup, before producing normal diagnostics

- timestamp: 2026-04-03T00:13:30Z
  checked: generated wrapper script and installed desktop file
  found: the installed launcher is the standard appimageTools bubblewrap wrapper and the desktop entry now calls plain karing %u
  implication: the desktop entry rewrite itself is not the immediate crash point; the failure is likely inside the FHS/AppImage runtime startup path

- timestamp: 2026-04-03T00:16:30Z
  checked: generated FHS rootfs contents
  found: the FHS environment contains broad GTK/Wayland/X11 libraries already, so the issue is not obviously explained by a single missing common GUI runtime library in extraPkgs
  implication: need to inspect the extracted upstream AppImage payload itself rather than only the generated rootfs

- timestamp: 2026-04-03T00:19:30Z
  checked: raw extracted AppImage contents
  found: the upstream AppImage contains an AppRun script that does only cd to its directory, sets LD_LIBRARY_PATH=usr/lib, and execs ./karing; the desktop entry matches this expectation
  implication: the package must preserve the executable's relative asset paths and its bundled usr/lib behavior, or replace them with a known-good runtime setup

- timestamp: 2026-04-03T00:21:45Z
  checked: direct execution of extracted AppRun without timeout guard
  found: command did not terminate within 120s and did not immediately segfault like the wrapped binary
  implication: the upstream payload likely starts and remains running, so the crash is more likely introduced by the Nix wrapper launch environment than by the AppImage contents alone

- timestamp: 2026-04-03T00:25:30Z
  checked: direct AppRun with timeout and ldd on extracted binaries
  found: direct AppRun does not reproduce the immediate crash, while ldd shows at least one optional plugin dependency unresolved (libkeybinder-3.0.so.0) but the app still starts without an instant segfault
  implication: unresolved plugin deps alone do not explain the wrapped crash; the stronger lead is the appimageTools wrapper launch environment

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
