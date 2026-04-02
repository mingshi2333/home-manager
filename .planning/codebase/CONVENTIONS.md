# Coding Conventions

**Analysis Date:** 2026-04-02

## Naming Patterns

**Files:**
- Use lowercase kebab-case for reusable Home Manager modules under `modules/`, such as `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, and `modules/desktop-entries.nix`.
- Use lowercase descriptive filenames for profile aggregators under `profiles/`, such as `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- Use host-scoped entrypoints under `hosts/<host>/home.nix`, as in `hosts/mingshi/home.nix`.
- Keep helper data in narrow, single-purpose files when reused across modules, as in `modules/fcitx-env.nix`.

**Functions and locals:**
- Use camelCase for local bindings and helper constructors, such as `nvidiaVersionFile`, `updateNvidiaMetadataCmd`, `wrapWithNixGL`, `mkNixGLApp`, `standardApp`, and `customApp` in `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, and `nixgl-apps.nix`.
- Prefix constructor-style helpers with `mk` when they return structured attrsets or wrappers, as in `mkNixGLApp`, `mkCatalogNixGLApp`, and `mkCustomApp` in `nixgl-apps.nix`.
- Use suffixes like `Cmd`, `File`, `Env`, `Bin`, `Packages`, and `Apps` for values whose role should be obvious from the name, following `hmSwitchCmd`, `nvidiaHashFile`, `fcitxEnv`, `nixGLBin`, `nixglPackages`, and `dedupApps`.

**Options and attributes:**
- Put custom module API under a `local.*` namespace instead of mixing it into top-level Home Manager options. The current pattern is `local.nixgl.*` in `modules/nixgl-runtime.nix`.
- Name generated collections by output type: `appPackages`, `shellAliases`, `binScripts`, `desktopEntries`, and `mimeAssociations` in `modules/nixgl-runtime.nix` and `nixgl-apps.nix`.

## Code Style

**Formatting:**
- Follow standard Nix indentation with two-space nesting for attrsets and lists, as seen throughout `flake.nix`, `home.nix`, and `nixgl-apps.nix`.
- Break long `inherit` blocks across lines rather than expanding repeated assignments, as in `modules/nixgl-runtime.nix` and `flake.nix`.
- Use trailing semicolons for every Nix binding and attribute.
- Keep shell snippets inside indented multi-line strings and align continuation lines for readability, as in `modules/home-manager-commands.nix`, `modules/plasma.nix`, and `modules/desktop-entries.nix`.

**Formatting tools:**
- `nixfmt` is installed via `modules/packages.nix`, so use `nixfmt` as the default formatter for Nix files.
- There is no repo-local formatter config file in the repository root; match existing file style instead of introducing a different formatter.

## Import Organization

**Order:**
1. Function arguments at the top of each module, usually `{ config, pkgs, lib, ... }:` or a reduced subset, as in `modules/environment.nix` and `modules/plasma.nix`.
2. A `let` section for derived values and reusable helpers, as in `modules/nixgl-runtime.nix` and `nixgl-apps.nix`.
3. The final attrset body with `options = { ... };`, `config = { ... };`, or direct module output.

**Imports:**
- Use explicit relative paths in `imports` lists rather than dynamic discovery, as in `home.nix`, `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- Keep profile files as thin import aggregators and place implementation in `modules/`.

## Option Wiring Idioms

**Custom option definitions:**
- Define custom Home Manager state with `lib.mkOption` and explicit `lib.types.*` types, as in `modules/nixgl-runtime.nix`.
- Mark derived internal options `readOnly = true` when they are computed from other files rather than user-settable, matching every field under `options.local.nixgl` in `modules/nixgl-runtime.nix`.

**Derived config exposure:**
- Compute reusable values in `let` bindings, then expose them once under `config.local.nixgl`, as in `modules/nixgl-runtime.nix`.
- Feed shared generated outputs into consumer modules rather than recomputing them. Current examples: `config.local.nixgl.appPackages` in `modules/packages.nix`, `config.local.nixgl.desktopEntries` and `config.local.nixgl.mimeAssociations` in `modules/desktop-entries.nix`, and `config.local.nixgl.binScripts` and `config.local.nixgl.shellAliases` in `modules/home-manager-commands.nix`.
- Reuse small imported attrsets for environment propagation instead of duplicating literals. The current pattern is `fcitxEnv = import ./fcitx-env.nix` in `modules/fcitx.nix`, `modules/nixgl-runtime.nix`, and `nixgl-apps.nix`.

## Module and Helper Design

**Profiles vs modules:**
- Put composition-only logic in `profiles/*.nix` and keep side-effecting or feature-specific logic in `modules/*.nix`.
- Keep top-level host files minimal. `hosts/mingshi/home.nix` only sets host identity and imports `../../home.nix`.

**Helper constructors:**
- Centralize repetitive application wiring behind helper functions instead of duplicating package wrappers. The repository standard is `standardApp` for the common case and `customApp` for exceptional cases in `nixgl-apps.nix`.
- Use `builtins.removeAttrs` to adapt generic argument sets before delegating to lower-level constructors, as in `mkCatalogNixGLApp`, `mkStandardNixGLApp`, `standardApp`, and `customApp` in `nixgl-apps.nix`.
- Return structured attrsets that separate generated artifacts (`package`, `shellAliases`, `binScripts`, `desktopEntry`, `mimeAssoc`) from source inputs, following `mkNixGLApp` in `nixgl-apps.nix`.

## Error Handling and Assertions

**Nix-level failures:**
- Fail early with `throw` when parsing critical local metadata instead of silently defaulting. Current examples are `throw "Unable to parse NVIDIA version from nvidia/version"` and `throw "Invalid NVIDIA hash in nvidia/hash"` in `modules/nixgl-runtime.nix`.
- Validate parsed values with `builtins.match` before use, then branch explicitly on `null`, as in `modules/nixgl-runtime.nix`.

**Shell-level guards:**
- Use strict shell mode `set -euo pipefail` in executable test scripts, as in `tests/hms-aliases.sh`.
- Prefer explicit conditional checks with targeted error messages and `exit 1`, as in `tests/hms-aliases.sh` and `modules/home-manager-commands.nix`.
- Where activation behavior must not block a switch, log the failure path and use `|| true` intentionally, as in `modules/plasma.nix` and `modules/desktop-entries.nix`.

## Comments and Documentation

**When to comment:**
- Add comments for non-obvious behavior, workarounds, or environment-specific constraints. Representative examples include the temporary `dwarfs` overlay comment in `flake.nix`, the `/proc` impurity explanation in `nixgl-noimpure.nix`, and the detaching rationale around `setsid` in `modules/plasma.nix`.
- Keep comments close to the code they justify rather than adding file-level prose blocks.

**Comment style:**
- Use short English line comments for implementation notes, TODOs, and rationale in code, even though user-facing docs in `README.md` and `USAGE.md` are primarily Chinese.
- Leave commented-out code only when preserving a concrete example or a deferred migration path. The disabled Telegram example in `nixgl-apps.nix` is the current exception, not the general pattern.

## Maintenance Practices

**Operational workflow:**
- Use the flake-locked CLI through the generated aliases in `modules/home-manager-commands.nix` rather than calling an arbitrary installed `home-manager` binary.
- Keep operator-facing workflow documented in `README.md` and `USAGE.md`, and keep the implementation aligned with those docs.
- Treat `home.nix` as the stable composition root, and extend behavior by editing `modules/*.nix`, `profiles/*.nix`, or `nixgl-apps.nix` rather than adding ad hoc top-level logic.

**Quality maintenance:**
- Preserve internal consistency between generated outputs and consuming modules. Any change to application metadata in `nixgl-apps.nix` should be checked against `modules/packages.nix`, `modules/desktop-entries.nix`, and `modules/home-manager-commands.nix`.
- When adding shell wrappers or activation scripts, keep them compatible with derivation-time checks and existing shell style so `shellcheck` usage in `nixgl-noimpure.nix` and the repository test script remain meaningful.

---

*Convention analysis: 2026-04-02*
