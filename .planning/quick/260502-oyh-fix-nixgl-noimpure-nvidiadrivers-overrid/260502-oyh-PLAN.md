---
phase: quick
plan: 260502-oyh
type: execute
wave: 1
depends_on: []
files_modified:
  - nixgl-noimpure.nix
autonomous: true
requirements:
  - fix-nixgl-noimpure-nvidiadrivers-kernel-arg
must_haves:
  truths:
    - "nixgl-noimpure.nix evaluates without errors under current nixpkgs"
    - "nix eval succeeds for homeConfigurations.mingshi after the fix"
  artifacts:
    - path: "nixgl-noimpure.nix"
      provides: "nvidiaLibsOnly override without kernel arg"
      contains: "libsOnly = true"
  key_links:
    - from: "nixgl-noimpure.nix"
      to: "pkgs/os-specific/linux/nvidia-x11/generic.nix"
      via: "nvidiaDrivers.override"
      pattern: "nvidiaDrivers\\.override"
---

<objective>
Remove the `kernel = null` argument from the `nvidiaDrivers.override` call in `nixgl-noimpure.nix`.

Purpose: The current nixpkgs revision (15f4ee454b1dce334612fa6843b3e05cf546efab) removed the `kernel` parameter from the nvidia driver inner function. Passing it now causes `error: function 'anonymous lambda' called with unexpected argument 'kernel'`, which blocks all Home Manager evaluation.

Output: `nixgl-noimpure.nix` with a corrected `nvidiaLibsOnly` override that works with both old and new nixpkgs nvidia driver signatures.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/mingshi/.config/home-manager/.planning/STATE.md
@/home/mingshi/.config/home-manager/nixgl-noimpure.nix
</context>

<tasks>

<task type="auto">
  <name>Task 1: Remove kernel = null from nvidiaLibsOnly override</name>
  <files>nixgl-noimpure.nix</files>
  <action>
Edit the `nvidiaLibsOnly` attrset at lines 114-117 of `nixgl-noimpure.nix`. Change:

```nix
nvidiaLibsOnly = nvidiaDrivers.override {
  libsOnly = true;
  kernel = null;
};
```

to:

```nix
nvidiaLibsOnly = nvidiaDrivers.override {
  libsOnly = true;
};
```

Remove only the `kernel = null;` line. Do not touch any surrounding code. The new nvidia driver generic.nix no longer declares `kernel ? null` in its inner function signature, so passing it causes an "unexpected argument" error. `libsOnly = true` alone is sufficient — the upstream assertion `assert !libsOnly -> kernel != null` has also been removed in the new revision.
  </action>
  <verify>
    <automated>cd /home/mingshi/.config/home-manager && nix eval .#homeConfigurations.mingshi.config.home.packages 2>&1 | head -20</automated>
  </verify>
  <done>The `nix eval` command completes without the "unexpected argument 'kernel'" error. The override block contains only `libsOnly = true`.</done>
</task>

<task type="auto">
  <name>Task 2: Commit the fix</name>
  <files>nixgl-noimpure.nix</files>
  <action>
Stage and commit the single-line deletion with a clear message referencing the upstream nixpkgs change.

Run:
```bash
git add nixgl-noimpure.nix
git commit -m "fix(nixgl-noimpure): remove kernel arg from nvidiaDrivers.override

nixpkgs rev 15f4ee454b1dce334612fa6843b3e05cf546efab removed the
kernel parameter from the nvidia driver inner function in
pkgs/os-specific/linux/nvidia-x11/generic.nix. Passing kernel = null
now causes 'unexpected argument kernel'. libsOnly = true is sufficient."
```
  </action>
  <verify>
    <automated>cd /home/mingshi/.config/home-manager && git log --oneline -1</automated>
  </verify>
  <done>The commit appears as the latest entry in git log with the fix message.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| nixpkgs upstream → local nix eval | Upstream API changes can silently break local overrides at eval time |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick-01 | Tampering | nvidiaDrivers.override | accept | Single-argument removal; no logic change; nix eval verifies correct build graph |
</threat_model>

<verification>
After both tasks complete:

1. `nix eval .#homeConfigurations.mingshi.config.home.packages` exits 0 with no "unexpected argument" error
2. `git log --oneline -1` shows the fix commit
3. Optionally: `home-manager switch --flake .` (or the `hms` alias) completes without the kernel-arg error
</verification>

<success_criteria>
- `nixgl-noimpure.nix` contains `nvidiaLibsOnly = nvidiaDrivers.override { libsOnly = true; };` with no `kernel` line
- `nix eval` against the flake succeeds
- Fix is committed to git
</success_criteria>

<output>
After completion, create `.planning/quick/260502-oyh-fix-nixgl-noimpure-nvidiadrivers-overrid/260502-oyh-SUMMARY.md`
</output>
