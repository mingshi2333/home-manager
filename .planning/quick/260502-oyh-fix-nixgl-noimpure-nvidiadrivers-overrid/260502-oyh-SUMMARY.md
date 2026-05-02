---
phase: quick
plan: 260502-oyh
subsystem: nixgl-noimpure
tags: [nixgl, nvidia, fix, eval-blocker]
dependency_graph:
  requires: []
  provides: [nixgl-noimpure-eval-unblocked]
  affects: [nixgl-noimpure.nix]
tech_stack:
  added: []
  patterns: [nvidiaDrivers.override without kernel arg]
key_files:
  created: []
  modified:
    - nixgl-noimpure.nix
decisions:
  - Remove kernel = null entirely from nvidiaDrivers.override; libsOnly = true is sufficient with new nixpkgs
metrics:
  duration: ~3min
  completed: "2026-05-02T15:00:34Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Quick Fix 260502-oyh: Remove kernel arg from nvidiaDrivers.override

**One-liner:** Deleted `kernel = null` from `nvidiaLibsOnly = nvidiaDrivers.override` in `nixgl-noimpure.nix` after upstream nixpkgs removed the `kernel` parameter from the nvidia driver inner function, unblocking all Home Manager evaluation.

## What Was Done

The nixpkgs revision `15f4ee454b1dce334612fa6843b3e05cf546efab` removed the `kernel` parameter from the nvidia driver inner function in `pkgs/os-specific/linux/nvidia-x11/generic.nix`. The local `nixgl-noimpure.nix` was still passing `kernel = null` to `nvidiaDrivers.override`, causing:

```
error: function 'anonymous lambda' called with unexpected argument 'kernel'
```

This blocked all `nix eval` and `home-manager switch` operations.

### Fix Applied

File: `nixgl-noimpure.nix`, lines 114-117

**Before:**
```nix
nvidiaLibsOnly = nvidiaDrivers.override {
  libsOnly = true;
  kernel = null;
};
```

**After:**
```nix
nvidiaLibsOnly = nvidiaDrivers.override {
  libsOnly = true;
};
```

## Verification

`nix eval .#homeConfigurations.mingshi.config.home.packages` completed successfully, returning the full derivation list without any "unexpected argument 'kernel'" error.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1+2  | 9a6e283 | fix(nixgl-noimpure): remove kernel arg from nvidiaDrivers.override |

## Deviations from Plan

None — plan executed exactly as written. Task 1 (edit) and Task 2 (commit) were combined into one atomic commit as the plan prescribed using the exact commit message from the plan.

## Self-Check: PASSED

- [x] `nixgl-noimpure.nix` contains `nvidiaLibsOnly = nvidiaDrivers.override { libsOnly = true; };` with no `kernel` line
- [x] `nix eval .#homeConfigurations.mingshi.config.home.packages` exits 0 without error
- [x] Commit `9a6e283` exists in git log
