# Testing Patterns

**Analysis Date:** 2026-04-02

## Test Tooling

**Runner style:**
- The repository does not use a language-specific unit test framework like `pytest`, `jest`, or `vitest`.
- Testing is shell-driven and evaluation-driven. The current explicit test lives at `tests/hms-aliases.sh`.
- The shell test uses `nix eval` against the flake output `.#homeConfigurations.mingshi.config.home.file.".zsh_aliases".text` to validate generated configuration without performing a full switch.

**Embedded checks:**
- `nixgl-noimpure.nix` performs derivation-time validation in `writeExecutable.checkPhase`.
- That check phase runs `${shellcheck}/bin/shellcheck` on generated wrapper scripts and verifies referenced `/nix/store` paths exist using `${pcre}/bin/pcregrep`.

## Test File Organization

**Location:**
- Put repository-level executable verification scripts under `tests/`, following `tests/hms-aliases.sh`.
- Keep tests external to Home Manager modules. Modules such as `modules/home-manager-commands.nix` and `modules/desktop-entries.nix` are validated indirectly through flake evaluation and generated outputs.

**Naming:**
- Use descriptive shell script names that target a single behavior area. `tests/hms-aliases.sh` documents its scope directly in the filename.
- Keep scripts executable and self-contained with a `#!/usr/bin/env bash` shebang and strict mode.

## Current Validation Scripts and Commands

**Repository test script:**
```bash
bash tests/hms-aliases.sh
```

**What `tests/hms-aliases.sh` validates:**
- Confirms aliases `hms` and `hmu` exist in the generated `.zsh_aliases` file.
- Confirms the generated alias text uses `nix run .#home-manager -- switch --flake .`.
- Confirms rollback uses `nix run .#home-manager -- switch --rollback --flake .`.
- Rejects hardcoded store paths for `nix` and `nix-prefetch-url` in alias definitions.

**Direct evaluation commands already implied by the codebase:**
```bash
nix eval .#homeConfigurations.mingshi.config.home.file.".zsh_aliases".text --raw
nix eval .#homeConfigurations.mingshi.config.local.nixgl.enabledApps
nix build .#homeConfigurations.mingshi.activationPackage
```

## Flake Checks

**Status:**
- No `checks` output is defined in `flake.nix`.
- No CI pipeline or automated `nix flake check` harness is present in the repository root.
- `nix flake check` may still evaluate basic flake structure, but there are no custom check derivations to extend it.

**Implication:**
- Additions under `tests/` are not automatically wired into flake checks today.
- Validation currently depends on manual script execution and targeted `nix eval` or `nix build` commands.

## Local Verification Workflow

**Recommended workflow from the repository state:**
1. Format changed Nix files with `nixfmt`, which is installed through `modules/packages.nix`.
2. Run `bash tests/hms-aliases.sh` when touching `modules/home-manager-commands.nix` or alias generation.
3. Run `nix build .#homeConfigurations.mingshi.activationPackage` after changes to module wiring, package generation, or activation scripts.
4. Run `hms` or `nix run .#home-manager -- switch --flake .` for end-to-end local application after the build passes.

**Behavior-specific manual checks:**
- For `modules/desktop-entries.nix`, inspect generated desktop files after a switch under `$HOME/.local/share/applications` and verify MIME association behavior in the desktop environment.
- For `modules/plasma.nix`, set `HM_PLASMA_RESTART=1` and inspect `$HOME/.cache/hm-restart-plasma.log` after a switch.
- For `modules/nixgl-runtime.nix`, verify `nvidia/version` and `nvidia/hash` parsing by evaluating `config.local.nixgl.nvidiaVersion` and `config.local.nixgl.nvidiaHash` through the flake.

## Test Patterns Observed

**Shell test structure:**
```bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
alias_text=$(cd "$repo_root" && nix eval ... --raw)

if ! printf '%s\n' "$alias_text" | grep -q "..."; then
  echo "failure message" >&2
  exit 1
fi
```

**Pattern guidance:**
- Resolve the repository root relative to the script path instead of assuming the current working directory, following `tests/hms-aliases.sh`.
- Prefer evaluating a specific flake output and asserting on the rendered text or attrset value.
- Emit one clear failure message per assertion so regressions are easy to diagnose in terminal output.

## What Gets Tested Implicitly

**Shell wrapper quality:**
- Generated scripts in `nixgl-noimpure.nix` are linted by `shellcheck` during derivation builds.

**Reference integrity:**
- The same `checkPhase` in `nixgl-noimpure.nix` verifies that store paths embedded in generated scripts resolve at build time.

**Module graph validity:**
- Any successful `nix build .#homeConfigurations.mingshi.activationPackage` validates that imported modules like `home.nix`, `profiles/*.nix`, and `modules/*.nix` evaluate together.

## Current Testing Gaps

**Coverage gaps:**
- `modules/desktop-entries.nix` has no dedicated regression test for deduplication, hash caching, or symlink cleanup behavior.
- `modules/plasma.nix` has no automated test for the restart flow, log rotation, or `HM_PLASMA_RESTART` gating.
- `modules/nixgl-runtime.nix` has no explicit test for malformed `nvidia/version` or `nvidia/hash` files beyond runtime `throw` behavior.
- `nixgl-apps.nix` has no catalog-level test that each enabled app produces a consistent package, alias, desktop entry, and MIME association set.
- Documentation in `README.md` and `USAGE.md` is not automatically checked against the actual alias implementation.

**Missing infrastructure:**
- No flake `checks` output to standardize repository validation.
- No CI configuration in the repository root to run `tests/hms-aliases.sh` or a build on every change.
- No fixture-based tests under `tests/` for evaluating module outputs across multiple app definitions or host variants.

## Prescriptive Guidance For New Tests

**Add tests under `tests/`:**
- Keep new checks as small executable scripts beside `tests/hms-aliases.sh`.
- Favor `nix eval` when asserting generated text or attrsets and `nix build` when asserting derivation validity.

**Target high-value areas first:**
- Add a desktop-entry regression script covering `modules/desktop-entries.nix`.
- Add a catalog consistency test for `nixgl-apps.nix` and `modules/nixgl-runtime.nix`.
- Add a build-oriented smoke check that exercises `.#homeConfigurations.mingshi.activationPackage`.

---

*Testing analysis: 2026-04-02*
