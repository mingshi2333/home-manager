# Architecture

**Analysis Date:** 2026-04-02

## Pattern Overview

**Overall:** Layered flake-driven Home Manager composition with a single host entry point, profile aggregation, and reusable feature modules.

**Key Characteristics:**
- Start evaluation from `flake.nix`, then delegate to one host file at `hosts/mingshi/home.nix`.
- Assemble user configuration through nested `imports` chains in `home.nix` and `profiles/*.nix` rather than one large monolith.
- Expose reusable internal data through `options.local.nixgl` in `modules/nixgl-runtime.nix`, then consume that data from packaging, desktop, and command modules.

## Composition Model

**Flake Output Layer:**
- Purpose: Define inputs, instantiate `pkgs`, and publish `homeConfigurations`.
- Location: `flake.nix`
- Contains: flake inputs, the `pkgs` import with an overlay, `packages.${system}.home-manager`, and `homeConfigurations."${username}"`.
- Depends on: `nixpkgs`, `home-manager`, `nixgl`, and `./hosts/mingshi/home.nix`.
- Used by: `nix run .#home-manager -- switch --flake .` and any `nix eval` against `.#homeConfigurations.mingshi`.

**Host Layer:**
- Purpose: Bind the evaluated configuration to a concrete user and home directory.
- Location: `hosts/mingshi/home.nix`
- Contains: `home.username`, `home.homeDirectory`, `home.stateVersion`, and one import of `../../home.nix`.
- Depends on: the root composition file at `home.nix`.
- Used by: `flake.nix` as the only module passed into `home-manager.lib.homeManagerConfiguration`.

**Root Assembly Layer:**
- Purpose: Define the top-level feature set for the selected host.
- Location: `home.nix`
- Contains: global `nixpkgs.config.allowUnfree`, `programs.home-manager.enable`, and imports for `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- Depends on: profile files and cross-cutting modules.
- Used by: `hosts/mingshi/home.nix`.

**Profile Layer:**
- Purpose: Group related module imports into coarse feature bundles.
- Location: `profiles/base.nix`, `profiles/gui.nix`, `profiles/packages.nix`
- Contains: import-only modules, where `profiles/base.nix` pulls in `modules/fcitx.nix` and `modules/environment.nix`, `profiles/gui.nix` pulls in `modules/plasma.nix` and `modules/desktop-entries.nix`, and `profiles/packages.nix` pulls in `modules/packages.nix`.
- Depends on: leaf modules under `modules/`.
- Used by: `home.nix`.

**Feature Module Layer:**
- Purpose: Implement concrete Home Manager options and activation behavior.
- Location: `modules/*.nix`
- Contains: session variables, package declarations, activation DAG nodes, user services, aliases, and XDG desktop configuration.
- Depends on: Home Manager `config`, `lib`, `pkgs`, and shared `local.nixgl` data where needed.
- Used by: profiles and `home.nix`.

## Evaluation Flow

**Primary Evaluation Path:**

1. `flake.nix` imports `nixpkgs` for `x86_64-linux`, applies a `dwarfs` overlay, and builds `pkgs`.
2. `flake.nix` calls `home-manager.lib.homeManagerConfiguration` and passes `./hosts/mingshi/home.nix` as the only module in `modules`.
3. `hosts/mingshi/home.nix` sets host-specific identity fields, then imports `../../home.nix`.
4. `home.nix` imports the cross-cutting runtime module `modules/nixgl-runtime.nix`, the command module `modules/home-manager-commands.nix`, and the profile bundles in `profiles/*.nix`.
5. Each profile expands into feature modules under `modules/`, which merge into one Home Manager `config` tree.
6. Consumers such as `modules/packages.nix`, `modules/desktop-entries.nix`, and `modules/home-manager-commands.nix` read from `config.local.nixgl`, which is produced once in `modules/nixgl-runtime.nix`.

**Activation Flow:**
- `modules/desktop-entries.nix` registers `home.activation.refreshDesktopDatabase` after `reloadSystemd` using `config.lib.dag.entryAfter`.
- `modules/plasma.nix` registers `home.activation.restartPlasma` after `writeBoundary` using `lib.hm.dag.entryAfter`.
- `modules/home-manager-commands.nix` materializes generated files under `home.file`, including `.zsh_aliases`, `.config/home-manager/zsh-extra.sh`, and the wrapper scripts from `config.local.nixgl.binScripts`.

## Host And Profile Layering

**Host-specific settings:**
- Keep machine or user identity in `hosts/mingshi/home.nix`.
- This file is the correct place for `home.username`, `home.homeDirectory`, and host state version.
- Current codebase uses one host only; `flake.nix` hardwires `./hosts/mingshi/home.nix`.

**Shared top-level policy:**
- Keep repo-wide toggles in `home.nix`.
- Current examples are `nixpkgs.config.allowUnfree = true;` and `programs.home-manager.enable = true;` in `home.nix`.

**Profile bundles:**
- Use `profiles/base.nix` for environment and input-method setup.
- Use `profiles/gui.nix` for graphical-session integration, desktop entries, and Plasma-specific activation.
- Use `profiles/packages.nix` for package aggregation logic.

**Leaf feature modules:**
- Put concrete option assignments and scripts in `modules/*.nix`.
- Current modules are split by concern: `modules/environment.nix`, `modules/fcitx.nix`, `modules/packages.nix`, `modules/desktop-entries.nix`, `modules/plasma.nix`, `modules/home-manager-commands.nix`, `modules/nixgl-runtime.nix`, and `modules/systemd-services.nix`.

## Reusable Abstractions

**`local.nixgl` internal interface:**
- Purpose: Centralize computed runtime data and generated artifacts for nixGL-managed applications.
- Definition: `modules/nixgl-runtime.nix`
- Pattern: Define read-only options under `options.local.nixgl`, then populate them under `config.local.nixgl`.
- Consumers: `modules/packages.nix`, `modules/desktop-entries.nix`, and `modules/home-manager-commands.nix`.

**nixGL app catalog:**
- Purpose: Declare GUI applications once and derive packages, aliases, wrapper scripts, desktop entries, and MIME associations from that declaration.
- Definition: `nixgl-apps.nix`
- Key helpers: `wrapWithNixGL`, `mkNixGLApp`, `mkCatalogNixGLApp`, `mkStandardNixGLApp`, `mkCustomApp`, `standardApp`, and `customApp`.
- Pattern: Add an entry to the `apps` attrset, then let the file derive `enabledApps`, `packages`, `shellAliases`, `binScripts`, `desktopEntries`, and `mimeAssociations`.

**Shared fcitx environment data:**
- Purpose: Reuse the same input-method environment map across GUI wrappers and login/session configuration.
- Definition: `modules/fcitx-env.nix`
- Consumers: `modules/fcitx.nix` and `modules/nixgl-runtime.nix`, which passes it into `nixgl-apps.nix`.

**Pinned nixGL implementation:**
- Purpose: Build a local nixGL wrapper package without relying on impure host detection during normal evaluation.
- Definition: `nixgl-noimpure.nix`
- Consumer: `modules/nixgl-runtime.nix` via `pkgs.callPackage ../nixgl-noimpure.nix { ... }`.
- Pattern: Read version metadata from `nvidia/version` and `nvidia/hash`, then expose `nixGLNvidia` and related wrappers.

## Module Boundaries

**Runtime/Data producer:**
- `modules/nixgl-runtime.nix` owns NVIDIA metadata parsing, nixGL package instantiation, app catalog evaluation, dedup prefix assembly, and the internal `local.nixgl` schema.

**Environment/session modules:**
- `modules/environment.nix` owns generic session variables and `xdg.configFile."environment.d/*"` files.
- `modules/fcitx.nix` owns fcitx session variables and `xdg.configFile."environment.d/99-fcitx5.conf"`.

**Package and desktop consumers:**
- `modules/packages.nix` owns `home.packages` and consumes `config.local.nixgl.appPackages` and `config.local.nixgl.package`.
- `modules/desktop-entries.nix` owns `xdg.enable`, `xdg.mimeApps`, `xdg.desktopEntries`, and desktop database refresh/dedup activation.

**Command and shell integration:**
- `modules/home-manager-commands.nix` owns generated aliases and helper scripts, including `hms`, `hmu`, `hmr`, and `.config/home-manager/zsh-extra.sh`.

**Graphical-session lifecycle:**
- `modules/plasma.nix` owns the conditional Plasma restart activation hook.
- `modules/systemd-services.nix` defines a `systemd.user.services.kbuildsycoca` oneshot service, but it is not imported anywhere from `home.nix` or `profiles/*.nix`, so it is currently outside the active assembly path.

## Configuration Assembly

**How final configuration is assembled:**
- Static imports provide the skeleton: `flake.nix` -> `hosts/mingshi/home.nix` -> `home.nix` -> `profiles/*.nix` -> `modules/*.nix`.
- Nix module merging combines all option assignments into one `config` tree.
- Computed nixGL data is produced once in `modules/nixgl-runtime.nix` from `nvidia/version`, `nvidia/hash`, `nixgl-noimpure.nix`, and `nixgl-apps.nix`.
- Downstream modules consume `config.local.nixgl` instead of reimplementing app package, alias, wrapper, or desktop logic.
- Activation-time concerns are attached with Home Manager DAG helpers in `modules/desktop-entries.nix` and `modules/plasma.nix`.

**State assembly examples:**
- `config.local.nixgl.shellAliases` and the fixed aliases `hms`, `hmu`, `hmr` are merged into `.zsh_aliases` by `modules/home-manager-commands.nix`.
- `config.local.nixgl.desktopEntries` and `config.local.nixgl.mimeAssociations` feed `xdg.desktopEntries` and `xdg.mimeApps.defaultApplications` in `modules/desktop-entries.nix`.
- `config.local.nixgl.appPackages` is prepended to the normal package list in `modules/packages.nix`.

## Entry Points

**Flake CLI entry point:**
- Location: `flake.nix`
- Triggers: `nix run .#home-manager -- switch --flake .`, `nix eval .#homeConfigurations.mingshi`, and related flake commands.
- Responsibilities: instantiate `pkgs`, expose the Home Manager CLI package, and construct `homeConfigurations.mingshi`.

**Home Manager host entry point:**
- Location: `hosts/mingshi/home.nix`
- Triggers: module evaluation inside `homeConfigurations.mingshi`.
- Responsibilities: provide user identity and import the shared root module tree.

**User command entry points:**
- Location: `modules/home-manager-commands.nix`
- Triggers: user shell aliases `hms`, `hmu`, and `hmr`, generated into `.zsh_aliases`.
- Responsibilities: refresh `nvidia/version` and `nvidia/hash` when appropriate, then run flake-locked Home Manager commands.

**Regression test entry point:**
- Location: `tests/hms-aliases.sh`
- Triggers: manual shell execution.
- Responsibilities: evaluate `.#homeConfigurations.mingshi.config.home.file.".zsh_aliases".text` and assert the generated aliases use flake-locked commands rather than hardcoded store paths.

## Error Handling

**Strategy:** Fail early during evaluation for invalid required metadata; tolerate activation-time desktop and Plasma refresh failures where the configuration can still be applied.

**Patterns:**
- `modules/nixgl-runtime.nix` throws on malformed `nvidia/version` or `nvidia/hash` using `throw` if parsing fails.
- Activation scripts in `modules/desktop-entries.nix` and `modules/plasma.nix` use shell guards and `|| true` on non-critical commands so desktop refresh or Plasma restart does not abort the whole switch.
- `modules/home-manager-commands.nix` validates NVIDIA version parsing before regenerating `nvidia/hash` and exits non-zero inside the alias command if metadata cannot be derived.

## Cross-Cutting Concerns

**Logging:** Minimal shell-script logging to files under `$HOME/.cache`, primarily in `modules/plasma.nix` via `~/.cache/hm-restart-plasma.log`.

**Validation:**
- Evaluation validation in `modules/nixgl-runtime.nix` for NVIDIA metadata.
- Shell-level assertions in `tests/hms-aliases.sh` for alias generation.

**Authentication:** No application-level authentication layer is defined in this repository. Privileged GUI launching is delegated to `pkexec` wrappers generated in `nixgl-apps.nix` for the `lenovo-legion` custom app.

---

*Architecture analysis: 2026-04-02*
