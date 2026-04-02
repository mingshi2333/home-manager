<!-- GSD:project-start source:PROJECT.md -->
## Project

**Fedora KDE Wayland 应用兼容性修复**

这是一个基于现有 Home Manager / nixGL 配置仓库的 brownfield 修复项目，目标是在当前 `Fedora + KDE + Wayland` 环境下修复桌面应用的启动失败、运行不稳定和剪贴板异常问题。重点不是重做整套框架，而是在现有声明式配置、启动包装和必要的系统级兼容设置上，把常用应用修到稳定可用。

**Core Value:** 当前这台 `Fedora + KDE + Wayland` 机器上的关键桌面应用必须能稳定启动并持续可用，不再依赖频繁重启来恢复。

### Constraints

- **Environment**: 仅针对当前 `Fedora + KDE + Wayland` 机器修复 — 用户明确本次不要求跨 host 或跨发行版通用
- **Architecture**: 优先保留现有 Home Manager / nixGL 结构 — 仓库已经有明确的模块化入口和包装体系
- **Remediation Style**: 优先配置修复，其次允许必要的系统级兼容调整 — 用户希望优先改配置而不是重做架构
- **Success Bar**: 至少达到“能稳定启动” — 这是用户明确给出的完成标准
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Nix - The repository is almost entirely declarative Nix code in `flake.nix`, `home.nix`, `hosts/mingshi/home.nix`, `profiles/*.nix`, `modules/*.nix`, `nixgl-apps.nix`, and `nixgl-noimpure.nix`.
- POSIX shell / Bash - Activation hooks, generated wrapper scripts, and test automation are implemented in shell inside `modules/home-manager-commands.nix`, `modules/desktop-entries.nix`, `modules/plasma.nix`, `nixgl-apps.nix`, `nixgl-noimpure.nix`, and `tests/hms-aliases.sh`.
- Markdown - Human-facing documentation lives in `README.md` and `USAGE.md`.
## Runtime
- Nix with flakes enabled. The operational commands in `modules/home-manager-commands.nix` use `nix run .#home-manager -- switch --flake .` and `nix flake update`.
- Home Manager on Linux. The host configuration in `hosts/mingshi/home.nix` sets `home.username = "mingshi"`, `home.homeDirectory = "/home/mingshi"`, and `home.stateVersion = "23.11"`.
- Target system is fixed to `x86_64-linux` in `flake.nix`.
- Nix flakes - dependency and package resolution are pinned through `flake.nix` and `flake.lock`.
- Lockfile: present in `flake.lock`.
## Frameworks
- `nixpkgs` from `github:NixOS/nixpkgs/nixos-unstable` in `flake.nix` - base package set and module inputs.
- `home-manager` from `github:nix-community/home-manager` in `flake.nix` - declarative user environment management and activation DAG integration.
- `nixGL` from `github:nix-community/nixGL` in `flake.nix` - OpenGL/Vulkan wrapper strategy for non-NixOS Linux desktop applications.
- Shell-based verification in `tests/hms-aliases.sh` - validates generated alias text by evaluating the Home Manager config with `nix eval`.
- Home Manager module system - composition entry points are `home.nix`, `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- Home Manager activation DAG - used in `modules/desktop-entries.nix` and `modules/plasma.nix` to run post-generation desktop refresh and Plasma restart logic.
- `makeWrapper` from nixpkgs - used in `nixgl-apps.nix` to build wrapped launchers.
## Key Dependencies
- `nix` in `modules/packages.nix` - required both as an installed CLI and as the runtime used by aliases in `modules/home-manager-commands.nix`.
- `config.local.nixgl.package` from `modules/packages.nix` and `modules/nixgl-runtime.nix` - provides the generated NVIDIA-capable `nixGL` wrapper package used by GUI app wrappers.
- `pkgs.gawk`, `pkgs.gnugrep`, and `cmp` usage in `modules/home-manager-commands.nix` - support NVIDIA metadata refresh logic before switching.
- `pkgs.makeWrapper` in `nixgl-apps.nix` - required for generated app wrappers and desktop integration.
- `pkgs.fcitx5-gtk` referenced in `nixgl-apps.nix` - injected into `LD_LIBRARY_PATH` for wrapped GUI apps.
- `pkgs.desktop-file-utils` in `modules/desktop-entries.nix` - updates desktop MIME database after activation.
- `pkgs.kdePackages.kservice` in `modules/systemd-services.nix` - provides `kbuildsycoca6` for KDE application database refresh.
- `pkgs.procps` and `pkgs.util-linux` in `modules/plasma.nix` - used to restart `plasmashell` reliably.
## Declared User Packages
- `nixfmt`, `nix-du`, `nix-index`, `nix-tree` in `modules/packages.nix`.
- `micromamba`, `mamba-cpp`, and `pixi` in `modules/packages.nix`, indicating local Conda/Pixi workflows are expected to coexist with Nix.
- `wpsoffice-cn`, `onedrivegui`, `kdePackages.kate`, `xdg-utils`, `vulkan-tools`, `nsc`, `vivid`, and `spotify` in `modules/packages.nix`.
- GUI applications wrapped through nixGL are declared in `nixgl-apps.nix`, including `gearlever`, `podman-desktop`, `cozy`, `qq`, `wechat`, `zotero`, `tracy`, `element-desktop`, `ayugram-desktop`, and a custom `lenovo-legion` launcher.
## Nix-Related Tooling And Flake Structure
- `flake.nix` defines all inputs and the single output `homeConfigurations."${username}"`.
- `flake.lock` pins exact upstream revisions for `nixpkgs`, `home-manager`, `nixGL`, `flake-utils`, and `systems`.
- `hosts/mingshi/home.nix` is the host-specific entry that imports `home.nix`.
- `home.nix` enables Home Manager and imports `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix` fan out into focused modules under `modules/`.
- `flake.nix` applies an overlay that overrides `dwarfs` to use `boost187`, documenting a repository-specific package compatibility workaround.
- `nixgl-noimpure.nix` vendors a customized nixGL implementation that can consume `nvidia/version` and `nvidia/hash` files instead of depending only on impure detection.
- `modules/nixgl-runtime.nix` exposes a local read-only option namespace `local.nixgl.*` for generated app packages, desktop entries, shell aliases, MIME associations, NVIDIA metadata, and wrapper binaries.
## Configuration
- Persistent session variables are set in `modules/environment.nix` and `modules/fcitx.nix`.
- XDG `environment.d` files are generated in `modules/environment.nix` and `modules/fcitx.nix` to keep user services aligned with interactive shell environment.
- NVIDIA runtime metadata is stored in `nvidia/version` and `nvidia/hash`, then read by `modules/nixgl-runtime.nix`.
- Primary build config files are `flake.nix`, `flake.lock`, `home.nix`, `profiles/*.nix`, and `modules/*.nix`.
- Generated user-facing shell config is written by Home Manager to `.zsh_aliases` and `.config/home-manager/zsh-extra.sh` as declared in `modules/home-manager-commands.nix`.
## Platform Requirements
- Linux desktop with Home Manager and flake-enabled Nix installed.
- The config assumes a user home at `/home/mingshi` in `hosts/mingshi/home.nix`.
- The environment assumes `zsh` will source `.zsh_aliases` and the generated `zsh-extra.sh` path adjustments from `modules/home-manager-commands.nix`.
- Non-NixOS or mixed-driver graphics support is expected because the stack centers on `nixGL` wrappers in `modules/nixgl-runtime.nix` and `nixgl-noimpure.nix`.
- NVIDIA-equipped systems are a first-class target. `modules/home-manager-commands.nix` reads `/proc/driver/nvidia/version` and refreshes `nvidia/hash` from the vendor installer URL when metadata changes.
- This repository deploys to a user profile managed by Home Manager rather than a server or packaged application runtime.
- GUI integration targets a KDE/Plasma desktop session with XDG desktop files, MIME associations, and optional `plasmashell` restart handling in `modules/plasma.nix` and `modules/desktop-entries.nix`.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- Use lowercase kebab-case for reusable Home Manager modules under `modules/`, such as `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, and `modules/desktop-entries.nix`.
- Use lowercase descriptive filenames for profile aggregators under `profiles/`, such as `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- Use host-scoped entrypoints under `hosts/<host>/home.nix`, as in `hosts/mingshi/home.nix`.
- Keep helper data in narrow, single-purpose files when reused across modules, as in `modules/fcitx-env.nix`.
- Use camelCase for local bindings and helper constructors, such as `nvidiaVersionFile`, `updateNvidiaMetadataCmd`, `wrapWithNixGL`, `mkNixGLApp`, `standardApp`, and `customApp` in `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, and `nixgl-apps.nix`.
- Prefix constructor-style helpers with `mk` when they return structured attrsets or wrappers, as in `mkNixGLApp`, `mkCatalogNixGLApp`, and `mkCustomApp` in `nixgl-apps.nix`.
- Use suffixes like `Cmd`, `File`, `Env`, `Bin`, `Packages`, and `Apps` for values whose role should be obvious from the name, following `hmSwitchCmd`, `nvidiaHashFile`, `fcitxEnv`, `nixGLBin`, `nixglPackages`, and `dedupApps`.
- Put custom module API under a `local.*` namespace instead of mixing it into top-level Home Manager options. The current pattern is `local.nixgl.*` in `modules/nixgl-runtime.nix`.
- Name generated collections by output type: `appPackages`, `shellAliases`, `binScripts`, `desktopEntries`, and `mimeAssociations` in `modules/nixgl-runtime.nix` and `nixgl-apps.nix`.
## Code Style
- Follow standard Nix indentation with two-space nesting for attrsets and lists, as seen throughout `flake.nix`, `home.nix`, and `nixgl-apps.nix`.
- Break long `inherit` blocks across lines rather than expanding repeated assignments, as in `modules/nixgl-runtime.nix` and `flake.nix`.
- Use trailing semicolons for every Nix binding and attribute.
- Keep shell snippets inside indented multi-line strings and align continuation lines for readability, as in `modules/home-manager-commands.nix`, `modules/plasma.nix`, and `modules/desktop-entries.nix`.
- `nixfmt` is installed via `modules/packages.nix`, so use `nixfmt` as the default formatter for Nix files.
- There is no repo-local formatter config file in the repository root; match existing file style instead of introducing a different formatter.
## Import Organization
- Use explicit relative paths in `imports` lists rather than dynamic discovery, as in `home.nix`, `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- Keep profile files as thin import aggregators and place implementation in `modules/`.
## Option Wiring Idioms
- Define custom Home Manager state with `lib.mkOption` and explicit `lib.types.*` types, as in `modules/nixgl-runtime.nix`.
- Mark derived internal options `readOnly = true` when they are computed from other files rather than user-settable, matching every field under `options.local.nixgl` in `modules/nixgl-runtime.nix`.
- Compute reusable values in `let` bindings, then expose them once under `config.local.nixgl`, as in `modules/nixgl-runtime.nix`.
- Feed shared generated outputs into consumer modules rather than recomputing them. Current examples: `config.local.nixgl.appPackages` in `modules/packages.nix`, `config.local.nixgl.desktopEntries` and `config.local.nixgl.mimeAssociations` in `modules/desktop-entries.nix`, and `config.local.nixgl.binScripts` and `config.local.nixgl.shellAliases` in `modules/home-manager-commands.nix`.
- Reuse small imported attrsets for environment propagation instead of duplicating literals. The current pattern is `fcitxEnv = import ./fcitx-env.nix` in `modules/fcitx.nix`, `modules/nixgl-runtime.nix`, and `nixgl-apps.nix`.
## Module and Helper Design
- Put composition-only logic in `profiles/*.nix` and keep side-effecting or feature-specific logic in `modules/*.nix`.
- Keep top-level host files minimal. `hosts/mingshi/home.nix` only sets host identity and imports `../../home.nix`.
- Centralize repetitive application wiring behind helper functions instead of duplicating package wrappers. The repository standard is `standardApp` for the common case and `customApp` for exceptional cases in `nixgl-apps.nix`.
- Use `builtins.removeAttrs` to adapt generic argument sets before delegating to lower-level constructors, as in `mkCatalogNixGLApp`, `mkStandardNixGLApp`, `standardApp`, and `customApp` in `nixgl-apps.nix`.
- Return structured attrsets that separate generated artifacts (`package`, `shellAliases`, `binScripts`, `desktopEntry`, `mimeAssoc`) from source inputs, following `mkNixGLApp` in `nixgl-apps.nix`.
## Error Handling and Assertions
- Fail early with `throw` when parsing critical local metadata instead of silently defaulting. Current examples are `throw "Unable to parse NVIDIA version from nvidia/version"` and `throw "Invalid NVIDIA hash in nvidia/hash"` in `modules/nixgl-runtime.nix`.
- Validate parsed values with `builtins.match` before use, then branch explicitly on `null`, as in `modules/nixgl-runtime.nix`.
- Use strict shell mode `set -euo pipefail` in executable test scripts, as in `tests/hms-aliases.sh`.
- Prefer explicit conditional checks with targeted error messages and `exit 1`, as in `tests/hms-aliases.sh` and `modules/home-manager-commands.nix`.
- Where activation behavior must not block a switch, log the failure path and use `|| true` intentionally, as in `modules/plasma.nix` and `modules/desktop-entries.nix`.
## Comments and Documentation
- Add comments for non-obvious behavior, workarounds, or environment-specific constraints. Representative examples include the temporary `dwarfs` overlay comment in `flake.nix`, the `/proc` impurity explanation in `nixgl-noimpure.nix`, and the detaching rationale around `setsid` in `modules/plasma.nix`.
- Keep comments close to the code they justify rather than adding file-level prose blocks.
- Use short English line comments for implementation notes, TODOs, and rationale in code, even though user-facing docs in `README.md` and `USAGE.md` are primarily Chinese.
- Leave commented-out code only when preserving a concrete example or a deferred migration path. The disabled Telegram example in `nixgl-apps.nix` is the current exception, not the general pattern.
## Maintenance Practices
- Use the flake-locked CLI through the generated aliases in `modules/home-manager-commands.nix` rather than calling an arbitrary installed `home-manager` binary.
- Keep operator-facing workflow documented in `README.md` and `USAGE.md`, and keep the implementation aligned with those docs.
- Treat `home.nix` as the stable composition root, and extend behavior by editing `modules/*.nix`, `profiles/*.nix`, or `nixgl-apps.nix` rather than adding ad hoc top-level logic.
- Preserve internal consistency between generated outputs and consuming modules. Any change to application metadata in `nixgl-apps.nix` should be checked against `modules/packages.nix`, `modules/desktop-entries.nix`, and `modules/home-manager-commands.nix`.
- When adding shell wrappers or activation scripts, keep them compatible with derivation-time checks and existing shell style so `shellcheck` usage in `nixgl-noimpure.nix` and the repository test script remain meaningful.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Start evaluation from `flake.nix`, then delegate to one host file at `hosts/mingshi/home.nix`.
- Assemble user configuration through nested `imports` chains in `home.nix` and `profiles/*.nix` rather than one large monolith.
- Expose reusable internal data through `options.local.nixgl` in `modules/nixgl-runtime.nix`, then consume that data from packaging, desktop, and command modules.
## Composition Model
- Purpose: Define inputs, instantiate `pkgs`, and publish `homeConfigurations`.
- Location: `flake.nix`
- Contains: flake inputs, the `pkgs` import with an overlay, `packages.${system}.home-manager`, and `homeConfigurations."${username}"`.
- Depends on: `nixpkgs`, `home-manager`, `nixgl`, and `./hosts/mingshi/home.nix`.
- Used by: `nix run .#home-manager -- switch --flake .` and any `nix eval` against `.#homeConfigurations.mingshi`.
- Purpose: Bind the evaluated configuration to a concrete user and home directory.
- Location: `hosts/mingshi/home.nix`
- Contains: `home.username`, `home.homeDirectory`, `home.stateVersion`, and one import of `../../home.nix`.
- Depends on: the root composition file at `home.nix`.
- Used by: `flake.nix` as the only module passed into `home-manager.lib.homeManagerConfiguration`.
- Purpose: Define the top-level feature set for the selected host.
- Location: `home.nix`
- Contains: global `nixpkgs.config.allowUnfree`, `programs.home-manager.enable`, and imports for `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- Depends on: profile files and cross-cutting modules.
- Used by: `hosts/mingshi/home.nix`.
- Purpose: Group related module imports into coarse feature bundles.
- Location: `profiles/base.nix`, `profiles/gui.nix`, `profiles/packages.nix`
- Contains: import-only modules, where `profiles/base.nix` pulls in `modules/fcitx.nix` and `modules/environment.nix`, `profiles/gui.nix` pulls in `modules/plasma.nix` and `modules/desktop-entries.nix`, and `profiles/packages.nix` pulls in `modules/packages.nix`.
- Depends on: leaf modules under `modules/`.
- Used by: `home.nix`.
- Purpose: Implement concrete Home Manager options and activation behavior.
- Location: `modules/*.nix`
- Contains: session variables, package declarations, activation DAG nodes, user services, aliases, and XDG desktop configuration.
- Depends on: Home Manager `config`, `lib`, `pkgs`, and shared `local.nixgl` data where needed.
- Used by: profiles and `home.nix`.
## Evaluation Flow
- `modules/desktop-entries.nix` registers `home.activation.refreshDesktopDatabase` after `reloadSystemd` using `config.lib.dag.entryAfter`.
- `modules/plasma.nix` registers `home.activation.restartPlasma` after `writeBoundary` using `lib.hm.dag.entryAfter`.
- `modules/home-manager-commands.nix` materializes generated files under `home.file`, including `.zsh_aliases`, `.config/home-manager/zsh-extra.sh`, and the wrapper scripts from `config.local.nixgl.binScripts`.
## Host And Profile Layering
- Keep machine or user identity in `hosts/mingshi/home.nix`.
- This file is the correct place for `home.username`, `home.homeDirectory`, and host state version.
- Current codebase uses one host only; `flake.nix` hardwires `./hosts/mingshi/home.nix`.
- Keep repo-wide toggles in `home.nix`.
- Current examples are `nixpkgs.config.allowUnfree = true;` and `programs.home-manager.enable = true;` in `home.nix`.
- Use `profiles/base.nix` for environment and input-method setup.
- Use `profiles/gui.nix` for graphical-session integration, desktop entries, and Plasma-specific activation.
- Use `profiles/packages.nix` for package aggregation logic.
- Put concrete option assignments and scripts in `modules/*.nix`.
- Current modules are split by concern: `modules/environment.nix`, `modules/fcitx.nix`, `modules/packages.nix`, `modules/desktop-entries.nix`, `modules/plasma.nix`, `modules/home-manager-commands.nix`, `modules/nixgl-runtime.nix`, and `modules/systemd-services.nix`.
## Reusable Abstractions
- Purpose: Centralize computed runtime data and generated artifacts for nixGL-managed applications.
- Definition: `modules/nixgl-runtime.nix`
- Pattern: Define read-only options under `options.local.nixgl`, then populate them under `config.local.nixgl`.
- Consumers: `modules/packages.nix`, `modules/desktop-entries.nix`, and `modules/home-manager-commands.nix`.
- Purpose: Declare GUI applications once and derive packages, aliases, wrapper scripts, desktop entries, and MIME associations from that declaration.
- Definition: `nixgl-apps.nix`
- Key helpers: `wrapWithNixGL`, `mkNixGLApp`, `mkCatalogNixGLApp`, `mkStandardNixGLApp`, `mkCustomApp`, `standardApp`, and `customApp`.
- Pattern: Add an entry to the `apps` attrset, then let the file derive `enabledApps`, `packages`, `shellAliases`, `binScripts`, `desktopEntries`, and `mimeAssociations`.
- Purpose: Reuse the same input-method environment map across GUI wrappers and login/session configuration.
- Definition: `modules/fcitx-env.nix`
- Consumers: `modules/fcitx.nix` and `modules/nixgl-runtime.nix`, which passes it into `nixgl-apps.nix`.
- Purpose: Build a local nixGL wrapper package without relying on impure host detection during normal evaluation.
- Definition: `nixgl-noimpure.nix`
- Consumer: `modules/nixgl-runtime.nix` via `pkgs.callPackage ../nixgl-noimpure.nix { ... }`.
- Pattern: Read version metadata from `nvidia/version` and `nvidia/hash`, then expose `nixGLNvidia` and related wrappers.
## Module Boundaries
- `modules/nixgl-runtime.nix` owns NVIDIA metadata parsing, nixGL package instantiation, app catalog evaluation, dedup prefix assembly, and the internal `local.nixgl` schema.
- `modules/environment.nix` owns generic session variables and `xdg.configFile."environment.d/*"` files.
- `modules/fcitx.nix` owns fcitx session variables and `xdg.configFile."environment.d/99-fcitx5.conf"`.
- `modules/packages.nix` owns `home.packages` and consumes `config.local.nixgl.appPackages` and `config.local.nixgl.package`.
- `modules/desktop-entries.nix` owns `xdg.enable`, `xdg.mimeApps`, `xdg.desktopEntries`, and desktop database refresh/dedup activation.
- `modules/home-manager-commands.nix` owns generated aliases and helper scripts, including `hms`, `hmu`, `hmr`, and `.config/home-manager/zsh-extra.sh`.
- `modules/plasma.nix` owns the conditional Plasma restart activation hook.
- `modules/systemd-services.nix` defines a `systemd.user.services.kbuildsycoca` oneshot service, but it is not imported anywhere from `home.nix` or `profiles/*.nix`, so it is currently outside the active assembly path.
## Configuration Assembly
- Static imports provide the skeleton: `flake.nix` -> `hosts/mingshi/home.nix` -> `home.nix` -> `profiles/*.nix` -> `modules/*.nix`.
- Nix module merging combines all option assignments into one `config` tree.
- Computed nixGL data is produced once in `modules/nixgl-runtime.nix` from `nvidia/version`, `nvidia/hash`, `nixgl-noimpure.nix`, and `nixgl-apps.nix`.
- Downstream modules consume `config.local.nixgl` instead of reimplementing app package, alias, wrapper, or desktop logic.
- Activation-time concerns are attached with Home Manager DAG helpers in `modules/desktop-entries.nix` and `modules/plasma.nix`.
- `config.local.nixgl.shellAliases` and the fixed aliases `hms`, `hmu`, `hmr` are merged into `.zsh_aliases` by `modules/home-manager-commands.nix`.
- `config.local.nixgl.desktopEntries` and `config.local.nixgl.mimeAssociations` feed `xdg.desktopEntries` and `xdg.mimeApps.defaultApplications` in `modules/desktop-entries.nix`.
- `config.local.nixgl.appPackages` is prepended to the normal package list in `modules/packages.nix`.
## Entry Points
- Location: `flake.nix`
- Triggers: `nix run .#home-manager -- switch --flake .`, `nix eval .#homeConfigurations.mingshi`, and related flake commands.
- Responsibilities: instantiate `pkgs`, expose the Home Manager CLI package, and construct `homeConfigurations.mingshi`.
- Location: `hosts/mingshi/home.nix`
- Triggers: module evaluation inside `homeConfigurations.mingshi`.
- Responsibilities: provide user identity and import the shared root module tree.
- Location: `modules/home-manager-commands.nix`
- Triggers: user shell aliases `hms`, `hmu`, and `hmr`, generated into `.zsh_aliases`.
- Responsibilities: refresh `nvidia/version` and `nvidia/hash` when appropriate, then run flake-locked Home Manager commands.
- Location: `tests/hms-aliases.sh`
- Triggers: manual shell execution.
- Responsibilities: evaluate `.#homeConfigurations.mingshi.config.home.file.".zsh_aliases".text` and assert the generated aliases use flake-locked commands rather than hardcoded store paths.
## Error Handling
- `modules/nixgl-runtime.nix` throws on malformed `nvidia/version` or `nvidia/hash` using `throw` if parsing fails.
- Activation scripts in `modules/desktop-entries.nix` and `modules/plasma.nix` use shell guards and `|| true` on non-critical commands so desktop refresh or Plasma restart does not abort the whole switch.
- `modules/home-manager-commands.nix` validates NVIDIA version parsing before regenerating `nvidia/hash` and exits non-zero inside the alias command if metadata cannot be derived.
## Cross-Cutting Concerns
- Evaluation validation in `modules/nixgl-runtime.nix` for NVIDIA metadata.
- Shell-level assertions in `tests/hms-aliases.sh` for alias generation.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
