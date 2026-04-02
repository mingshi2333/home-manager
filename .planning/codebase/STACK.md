# Technology Stack

**Analysis Date:** 2026-04-02

## Languages

**Primary:**
- Nix - The repository is almost entirely declarative Nix code in `flake.nix`, `home.nix`, `hosts/mingshi/home.nix`, `profiles/*.nix`, `modules/*.nix`, `nixgl-apps.nix`, and `nixgl-noimpure.nix`.

**Secondary:**
- POSIX shell / Bash - Activation hooks, generated wrapper scripts, and test automation are implemented in shell inside `modules/home-manager-commands.nix`, `modules/desktop-entries.nix`, `modules/plasma.nix`, `nixgl-apps.nix`, `nixgl-noimpure.nix`, and `tests/hms-aliases.sh`.
- Markdown - Human-facing documentation lives in `README.md` and `USAGE.md`.

## Runtime

**Environment:**
- Nix with flakes enabled. The operational commands in `modules/home-manager-commands.nix` use `nix run .#home-manager -- switch --flake .` and `nix flake update`.
- Home Manager on Linux. The host configuration in `hosts/mingshi/home.nix` sets `home.username = "mingshi"`, `home.homeDirectory = "/home/mingshi"`, and `home.stateVersion = "23.11"`.
- Target system is fixed to `x86_64-linux` in `flake.nix`.

**Package Manager:**
- Nix flakes - dependency and package resolution are pinned through `flake.nix` and `flake.lock`.
- Lockfile: present in `flake.lock`.

## Frameworks

**Core:**
- `nixpkgs` from `github:NixOS/nixpkgs/nixos-unstable` in `flake.nix` - base package set and module inputs.
- `home-manager` from `github:nix-community/home-manager` in `flake.nix` - declarative user environment management and activation DAG integration.
- `nixGL` from `github:nix-community/nixGL` in `flake.nix` - OpenGL/Vulkan wrapper strategy for non-NixOS Linux desktop applications.

**Testing:**
- Shell-based verification in `tests/hms-aliases.sh` - validates generated alias text by evaluating the Home Manager config with `nix eval`.

**Build/Dev:**
- Home Manager module system - composition entry points are `home.nix`, `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- Home Manager activation DAG - used in `modules/desktop-entries.nix` and `modules/plasma.nix` to run post-generation desktop refresh and Plasma restart logic.
- `makeWrapper` from nixpkgs - used in `nixgl-apps.nix` to build wrapped launchers.

## Key Dependencies

**Critical:**
- `nix` in `modules/packages.nix` - required both as an installed CLI and as the runtime used by aliases in `modules/home-manager-commands.nix`.
- `config.local.nixgl.package` from `modules/packages.nix` and `modules/nixgl-runtime.nix` - provides the generated NVIDIA-capable `nixGL` wrapper package used by GUI app wrappers.
- `pkgs.gawk`, `pkgs.gnugrep`, and `cmp` usage in `modules/home-manager-commands.nix` - support NVIDIA metadata refresh logic before switching.
- `pkgs.makeWrapper` in `nixgl-apps.nix` - required for generated app wrappers and desktop integration.

**Infrastructure:**
- `pkgs.fcitx5-gtk` referenced in `nixgl-apps.nix` - injected into `LD_LIBRARY_PATH` for wrapped GUI apps.
- `pkgs.desktop-file-utils` in `modules/desktop-entries.nix` - updates desktop MIME database after activation.
- `pkgs.kdePackages.kservice` in `modules/systemd-services.nix` - provides `kbuildsycoca6` for KDE application database refresh.
- `pkgs.procps` and `pkgs.util-linux` in `modules/plasma.nix` - used to restart `plasmashell` reliably.

## Declared User Packages

**Developer and Nix tooling:**
- `nixfmt`, `nix-du`, `nix-index`, `nix-tree` in `modules/packages.nix`.
- `micromamba`, `mamba-cpp`, and `pixi` in `modules/packages.nix`, indicating local Conda/Pixi workflows are expected to coexist with Nix.

**Desktop and utility packages:**
- `wpsoffice-cn`, `onedrivegui`, `kdePackages.kate`, `xdg-utils`, `vulkan-tools`, `nsc`, `vivid`, and `spotify` in `modules/packages.nix`.
- GUI applications wrapped through nixGL are declared in `nixgl-apps.nix`, including `gearlever`, `podman-desktop`, `cozy`, `qq`, `wechat`, `zotero`, `tracy`, `element-desktop`, `ayugram-desktop`, and a custom `lenovo-legion` launcher.

## Nix-Related Tooling And Flake Structure

**Flake entry points:**
- `flake.nix` defines all inputs and the single output `homeConfigurations."${username}"`.
- `flake.lock` pins exact upstream revisions for `nixpkgs`, `home-manager`, `nixGL`, `flake-utils`, and `systems`.

**Module graph:**
- `hosts/mingshi/home.nix` is the host-specific entry that imports `home.nix`.
- `home.nix` enables Home Manager and imports `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix`.
- `profiles/base.nix`, `profiles/gui.nix`, and `profiles/packages.nix` fan out into focused modules under `modules/`.

**Custom Nix logic:**
- `flake.nix` applies an overlay that overrides `dwarfs` to use `boost187`, documenting a repository-specific package compatibility workaround.
- `nixgl-noimpure.nix` vendors a customized nixGL implementation that can consume `nvidia/version` and `nvidia/hash` files instead of depending only on impure detection.
- `modules/nixgl-runtime.nix` exposes a local read-only option namespace `local.nixgl.*` for generated app packages, desktop entries, shell aliases, MIME associations, NVIDIA metadata, and wrapper binaries.

## Configuration

**Environment:**
- Persistent session variables are set in `modules/environment.nix` and `modules/fcitx.nix`.
- XDG `environment.d` files are generated in `modules/environment.nix` and `modules/fcitx.nix` to keep user services aligned with interactive shell environment.
- NVIDIA runtime metadata is stored in `nvidia/version` and `nvidia/hash`, then read by `modules/nixgl-runtime.nix`.

**Build:**
- Primary build config files are `flake.nix`, `flake.lock`, `home.nix`, `profiles/*.nix`, and `modules/*.nix`.
- Generated user-facing shell config is written by Home Manager to `.zsh_aliases` and `.config/home-manager/zsh-extra.sh` as declared in `modules/home-manager-commands.nix`.

## Platform Requirements

**Development:**
- Linux desktop with Home Manager and flake-enabled Nix installed.
- The config assumes a user home at `/home/mingshi` in `hosts/mingshi/home.nix`.
- The environment assumes `zsh` will source `.zsh_aliases` and the generated `zsh-extra.sh` path adjustments from `modules/home-manager-commands.nix`.
- Non-NixOS or mixed-driver graphics support is expected because the stack centers on `nixGL` wrappers in `modules/nixgl-runtime.nix` and `nixgl-noimpure.nix`.
- NVIDIA-equipped systems are a first-class target. `modules/home-manager-commands.nix` reads `/proc/driver/nvidia/version` and refreshes `nvidia/hash` from the vendor installer URL when metadata changes.

**Production:**
- This repository deploys to a user profile managed by Home Manager rather than a server or packaged application runtime.
- GUI integration targets a KDE/Plasma desktop session with XDG desktop files, MIME associations, and optional `plasmashell` restart handling in `modules/plasma.nix` and `modules/desktop-entries.nix`.

---

*Stack analysis: 2026-04-02*
