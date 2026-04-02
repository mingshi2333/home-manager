# Codebase Structure

**Analysis Date:** 2026-04-02

## Directory Layout

```text
home-manager/
├── flake.nix                 # Flake entry point and homeConfigurations output
├── home.nix                  # Root composition module for shared imports
├── hosts/                    # Host-specific identity and entry modules
├── profiles/                 # Import-only bundles for major feature areas
├── modules/                  # Leaf Home Manager modules by concern
├── nvidia/                   # NVIDIA metadata files consumed during evaluation
├── nixgl-apps.nix            # nixGL app catalog and generation helpers
├── nixgl-noimpure.nix        # Local nixGL implementation used by runtime module
├── tests/                    # Shell-level regression checks
├── README.md                 # Repository architecture and usage notes
├── USAGE.md                  # Contributor-oriented usage documentation
└── .planning/codebase/       # Generated codebase mapping documents
```

## Directory Purposes

**`hosts/`:**
- Purpose: Hold per-host Home Manager entry modules.
- Contains: one host file at `hosts/mingshi/home.nix`.
- Key files: `hosts/mingshi/home.nix`.

**`profiles/`:**
- Purpose: Group imports into coarse bundles so `home.nix` stays short.
- Contains: import aggregators only, not deep implementation logic.
- Key files: `profiles/base.nix`, `profiles/gui.nix`, `profiles/packages.nix`.

**`modules/`:**
- Purpose: Store feature-specific Home Manager modules and internal reusable building blocks.
- Contains: leaf modules such as `modules/environment.nix`, `modules/fcitx.nix`, `modules/packages.nix`, `modules/desktop-entries.nix`, `modules/plasma.nix`, `modules/home-manager-commands.nix`, `modules/nixgl-runtime.nix`, and the shared data file `modules/fcitx-env.nix`.
- Key files: `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, `modules/desktop-entries.nix`.

**`nvidia/`:**
- Purpose: Keep evaluation inputs for NVIDIA driver wrapping.
- Contains: `nvidia/version` and `nvidia/hash`.
- Key files: `nvidia/version`, `nvidia/hash`.

**`tests/`:**
- Purpose: Hold executable checks against evaluated outputs.
- Contains: shell tests.
- Key files: `tests/hms-aliases.sh`.

**`.planning/codebase/`:**
- Purpose: Store generated reference documents for planning and execution workflows.
- Contains: mapper output markdown documents.
- Key files: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`.

## Key File Locations

**Entry Points:**
- `flake.nix`: top-level flake entry point and the source of `homeConfigurations.mingshi`.
- `hosts/mingshi/home.nix`: active host module selected by `flake.nix`.
- `home.nix`: shared root module imported by the host file.

**Configuration Composition:**
- `profiles/base.nix`: imports `modules/fcitx.nix` and `modules/environment.nix`.
- `profiles/gui.nix`: imports `modules/plasma.nix` and `modules/desktop-entries.nix`.
- `profiles/packages.nix`: imports `modules/packages.nix`.

**Core Logic:**
- `modules/nixgl-runtime.nix`: computes `config.local.nixgl` and defines the internal runtime interface.
- `nixgl-apps.nix`: defines the app catalog and generators for wrappers, aliases, desktop files, and MIME mappings.
- `nixgl-noimpure.nix`: implements nixGL wrapper derivations used by the runtime module.

**User Environment:**
- `modules/environment.nix`: generic session variables and `environment.d` files.
- `modules/fcitx.nix`: input method environment wiring.
- `modules/packages.nix`: package list assembly.
- `modules/desktop-entries.nix`: XDG desktop entries, MIME defaults, and refresh activation.
- `modules/home-manager-commands.nix`: generated aliases and helper scripts.
- `modules/plasma.nix`: Plasma restart activation hook.

**Testing:**
- `tests/hms-aliases.sh`: regression check for generated alias content.

**Documentation:**
- `README.md`: architecture summary and nixGL app catalog usage.
- `USAGE.md`: contributor workflow and alias behavior.

## Subsystem Ownership

**Flake and host selection:**
- Primary files: `flake.nix`, `hosts/mingshi/home.nix`.
- Change here when adding a new host entry, adjusting `extraSpecialArgs`, or changing the flake output shape.

**Shared composition policy:**
- Primary file: `home.nix`.
- Change here when enabling or removing top-level modules or profile bundles.

**nixGL runtime and generated app artifacts:**
- Primary files: `modules/nixgl-runtime.nix`, `nixgl-apps.nix`, `nixgl-noimpure.nix`, `nvidia/version`, `nvidia/hash`.
- Change here when adding wrapped GUI apps, modifying wrapper generation, or adjusting NVIDIA metadata handling.

**Session environment and input method:**
- Primary files: `modules/environment.nix`, `modules/fcitx.nix`, `modules/fcitx-env.nix`.
- Change here for environment variables, `environment.d` files, or fcitx integration.

**Desktop and Plasma behavior:**
- Primary files: `modules/desktop-entries.nix`, `modules/plasma.nix`.
- Change here for MIME defaults, desktop file synchronization, KDE cache refresh, or Plasma restart logic.

**Packages and command aliases:**
- Primary files: `modules/packages.nix`, `modules/home-manager-commands.nix`.
- Change here for package installation policy, generated shell aliases, or helper scripts under `home.file`.

## Naming Conventions

**Files:**
- Use lowercase kebab-case for module files under `modules/`, such as `modules/home-manager-commands.nix` and `modules/desktop-entries.nix`.
- Use lowercase simple names for profile aggregators under `profiles/`, such as `profiles/base.nix` and `profiles/gui.nix`.
- Use `home.nix` as the entry filename for both the repository root and host directories: `home.nix`, `hosts/mingshi/home.nix`.

**Directories:**
- Use plural nouns for code groupings: `hosts/`, `profiles/`, `modules/`, `tests/`.
- Put host-specific code one level below `hosts/`, as shown by `hosts/mingshi/`.

**Attributes and internal APIs:**
- Use `local.*` for internal cross-module interfaces, specifically `local.nixgl` in `modules/nixgl-runtime.nix`.
- Use attrset-based catalogs for reusable generated resources, as shown by the `apps = { ... };` declaration in `nixgl-apps.nix`.

## Where To Add New Code

**New host:**
- Primary code: add a new directory and `home.nix` under `hosts/<host>/home.nix`.
- Flake wiring: register it from `flake.nix` under `homeConfigurations`.

**New shared feature module:**
- Implementation: add `modules/<feature>.nix`.
- Assembly: import it from an existing profile in `profiles/*.nix` or directly from `home.nix` if it is cross-cutting.

**New profile bundle:**
- Implementation: add `profiles/<name>.nix` with an `imports = [ ... ];` list.
- Assembly: add that profile to `home.nix`.

**New nixGL-wrapped application:**
- Primary code: add an entry to the `apps` attrset in `nixgl-apps.nix`.
- Use `standardApp` for normal wrappers and `customApp` for pkexec or custom-script launchers.
- Do not add generated aliases, desktop entries, or wrapper scripts directly in multiple modules; let `nixgl-apps.nix` feed `config.local.nixgl` and let downstream modules consume it.

**New session variable or environment.d file:**
- Generic environment: `modules/environment.nix`.
- Input-method-specific environment: `modules/fcitx.nix` or `modules/fcitx-env.nix`.

**New package that is not part of the nixGL app catalog:**
- Primary code: `modules/packages.nix`.

**New desktop/MIME behavior:**
- Primary code: `modules/desktop-entries.nix`.

**New shell alias or generated helper file:**
- Primary code: `modules/home-manager-commands.nix`.

**New test:**
- Primary code: `tests/`.
- Match the current executable shell-script style used by `tests/hms-aliases.sh`.

## Common Task Lookup

**Find how configuration is assembled:**
- Start at `flake.nix`, then read `hosts/mingshi/home.nix`, then `home.nix`, then the relevant `profiles/*.nix` file.

**Find where GUI app wrappers come from:**
- Read `modules/nixgl-runtime.nix` and `nixgl-apps.nix` first.

**Find why a desktop entry or MIME association exists:**
- Read `nixgl-apps.nix` for the source declaration, then `modules/desktop-entries.nix` for export and refresh behavior.

**Find why an alias exists or what `hms` does:**
- Read `modules/home-manager-commands.nix`, then validate with `tests/hms-aliases.sh`.

**Find environment-variable behavior:**
- Read `modules/environment.nix`, `modules/fcitx.nix`, and `modules/fcitx-env.nix`.

**Find KDE or Plasma lifecycle behavior:**
- Read `modules/plasma.nix` and `modules/desktop-entries.nix`.

## Special Directories And Files

**`nvidia/`:**
- Purpose: runtime metadata source for deterministic NVIDIA wrapper generation.
- Generated: yes, refreshed by the commands in `modules/home-manager-commands.nix`.
- Committed: yes, the repository contains `nvidia/version` and `nvidia/hash`.

**`result` and `result-1`:**
- Purpose: Nix build result symlinks at repository root.
- Generated: yes.
- Committed: no as normal source files; they are symlinks created by local builds.

**`modules/systemd-services.nix`:**
- Purpose: defines `systemd.user.services.kbuildsycoca`.
- Generated: no.
- Committed: yes.
- Active status: currently not imported by `home.nix` or any `profiles/*.nix`, so contributors should not expect it to affect the active configuration unless they wire it in.

---

*Structure analysis: 2026-04-02*
