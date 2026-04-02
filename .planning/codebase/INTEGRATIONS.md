# External Integrations

**Analysis Date:** 2026-04-02

## APIs & External Services

**Flake sources:**
- GitHub-hosted flake inputs are the only explicit remote source integrations in `flake.nix`.
  - `nixpkgs` - package source from `github:NixOS/nixpkgs/nixos-unstable`
  - `home-manager` - user environment framework from `github:nix-community/home-manager`
  - `nixGL` - graphics wrapper source from `github:nix-community/nixGL`
  - SDK/Client: native Nix flake fetchers driven by `flake.nix` and pinned in `flake.lock`
  - Auth: Not specified in the repository; uses the host's normal Git/Nix fetch configuration

**Vendor download endpoints:**
- NVIDIA driver download endpoint is hard-coded in `modules/home-manager-commands.nix` and `nixgl-noimpure.nix`.
  - Service: `https://download.nvidia.com/XFree86/Linux-x86_64/<version>/NVIDIA-Linux-x86_64-<version>.run`
  - Purpose: derive an SRI hash and fetch matching NVIDIA userspace libraries for nixGL packaging
  - SDK/Client: `nix-prefetch-url`, `nix hash to-sri`, and `fetchurl`
  - Auth: none

## Data Storage

**Databases:**
- Not detected for application data storage. The repository does not define any SQL, NoSQL, or embedded database client configuration.

**File Storage:**
- Local filesystem only.
- Runtime metadata is persisted in `nvidia/version` and `nvidia/hash`.
- User-generated launchers and aliases are written through Home Manager declarations in `modules/home-manager-commands.nix` and `nixgl-apps.nix`.
- Desktop cache state is written to `$HOME/.cache/hm-desktop-entries.sha256` by `modules/desktop-entries.nix` and `$HOME/.cache/hm-restart-plasma.log` by `modules/plasma.nix`.

**Caching:**
- Local filesystem cache only. No Redis, Memcached, or remote cache configuration is declared in repository code.

## Authentication & Identity

**Auth Provider:**
- No application-level auth provider is implemented.
- Nix/GitHub flake fetching depends on the machine's existing Nix and Git credential setup if private registries were ever added, but this repository itself declares only public GitHub inputs in `flake.nix`.

**Privilege escalation:**
- `pkexec` is used for Lenovo Legion control wrappers in `nixgl-apps.nix`.
  - Implementation: generated scripts `.local/bin/lenovo-legion-pkexec` and `.local/bin/lenovo-legion-gui-pkexec` execute `pkgs.lenovo-legion` subcommands through `pkgs.util-linux` `pkexec`.

## Monitoring & Observability

**Error Tracking:**
- None detected. No Sentry, OpenTelemetry, or external error tracking integration is configured.

**Logs:**
- Local shell log files only.
- Plasma restart activity is appended to `$HOME/.cache/hm-restart-plasma.log` from `modules/plasma.nix`.
- Activation scripts use standard output/error messages during Home Manager switch execution in `modules/home-manager-commands.nix` and `modules/desktop-entries.nix`.

## CI/CD & Deployment

**Hosting:**
- Not applicable as a user configuration repository.
- Deployment target is the local Home Manager profile for `mingshi` via `homeConfigurations."mingshi"` in `flake.nix`.

**CI Pipeline:**
- None detected in repository files. There is no GitHub Actions workflow, Hydra jobset, or other CI definition under the inspected tree.

## Environment Configuration

**Required env vars:**
- Input method variables from `modules/fcitx-env.nix`: `GTK_IM_MODULE`, `QT_IM_MODULE`, `XMODIFIERS`, `SDL_IM_MODULE`, `INPUT_METHOD`.
- Desktop/session variables from `modules/environment.nix`: `EDITOR`, `NIXOS_XDG_OPEN_USE_PORTAL`, `GTK_USE_PORTAL`, `XDG_DATA_DIRS`, `ELECTRON_OZONE_PLATFORM_HINT`, `NIXOS_OZONE_WL`.
- GTK integration variables from `modules/fcitx.nix`: `GTK_IM_MODULE_FILE`, `GTK_PATH`.
- Generated nixGL app wrappers in `nixgl-apps.nix` also inject per-app environment like `QT_QPA_PLATFORM`, `QTWEBENGINE_DISABLE_SANDBOX`, `GDK_DISABLE`, and `GSK_RENDERER` when required by individual packages.

**Secrets location:**
- No secrets files are read by the repository code inspected here.
- No `.env`-style configuration is required by the checked Nix modules.

## System And Host Integrations

**Shell integration:**
- Zsh alias and PATH integration is generated in `modules/home-manager-commands.nix`.
- Aliases `hms`, `hmu`, and `hmr` wrap flake-locked Home Manager operations and NVIDIA metadata refresh.
- The generated `zsh-extra.sh` prepends `/usr/local/bin`, `/usr/bin`, `/usr/local/sbin`, `/usr/sbin`, `$HOME/.cache/.bun/bin`, `$HOME/.nix-profile/bin`, and `/nix/var/nix/profiles/default/bin`.

**Systemd user services:**
- `modules/systemd-services.nix` defines a user service `kbuildsycoca` that runs `${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental`.
- `modules/desktop-entries.nix` and `modules/plasma.nix` interact with `systemctl --user` during activation.

**Desktop environment integration:**
- KDE/Plasma integration is explicit in `modules/plasma.nix`, `modules/systemd-services.nix`, and `modules/desktop-entries.nix`.
- XDG desktop entries and MIME defaults are managed in `modules/desktop-entries.nix`.
- Default MIME handlers include `chromium-browser.desktop` for HTTP, HTTPS, mailto, and PDF.

**Graphics stack integration:**
- `modules/nixgl-runtime.nix` and `nixgl-noimpure.nix` integrate with local GPU drivers, Mesa, GLVND, Vulkan ICD files, and `/proc/driver/nvidia/version`.
- The repo depends on a host-level NVIDIA driver being installed and readable for its reproducible nixGL flow.

**Input method integration:**
- Fcitx integration is centralized in `modules/fcitx.nix` and `modules/fcitx-env.nix`.
- Wrapped GUI apps in `nixgl-apps.nix` merge those environment variables into each launcher.

## Package Registries And Toolchains

**Package registries:**
- Primary registry: `nixpkgs` via flake input in `flake.nix`.
- No npm, PyPI, Cargo, Maven, or Go module manifest was detected in the repository root.

**Additional toolchains available to the user environment:**
- `micromamba` and `pixi` in `modules/packages.nix` expose Conda/Pixi ecosystems for ad hoc project environments.
- `$HOME/.cache/.bun/bin` is added to PATH in `modules/environment.nix` and `modules/home-manager-commands.nix`, so a preexisting Bun installation is expected to be discoverable even though Bun is not provisioned by this repo.

## Networking-Related Interfaces

**Incoming:**
- None defined as web servers, APIs, or webhook receivers.
- D-Bus service files can be repackaged for wrapped applications in `nixgl-apps.nix`; this is local IPC, not network transport.

**Outgoing:**
- `nix flake update` in `modules/home-manager-commands.nix` reaches configured flake remotes, currently GitHub as defined in `flake.nix`.
- NVIDIA metadata refresh in `modules/home-manager-commands.nix` contacts `download.nvidia.com` through `nix-prefetch-url`.
- Package functionality implied by installed apps such as `onedrivegui`, `spotify`, `qq`, `wechat`, `element-desktop`, `ayugram-desktop`, and `podman-desktop` exists at the package level in `modules/packages.nix` and `nixgl-apps.nix`, but this repository does not configure their remote credentials or service endpoints.

## Test And Runtime Integrations

**Runtime command integration:**
- `tests/hms-aliases.sh` uses `nix eval .#homeConfigurations.mingshi.config.home.file.".zsh_aliases".text --raw` to validate generated shell aliases against the flake output.
- This test assumes flake support and the experimental features `nix-command flakes dynamic-derivations` are available to the local `nix` CLI.

**Activation-time integrations:**
- `modules/desktop-entries.nix` calls `update-desktop-database`, `kbuildsycoca6`, or `kbuildsycoca5` when desktop files change.
- `modules/plasma.nix` may restart `plasma-plasmashell.service` or directly relaunch `plasmashell` when `HM_PLASMA_RESTART=1` is present.

## Webhooks & Callbacks

**Incoming:**
- None.

**Outgoing:**
- None implemented as webhook callbacks.

## Absent Integrations

**APIs:**
- No custom HTTP API clients or server integrations are defined beyond flake and NVIDIA fetch endpoints.

**Databases:**
- None configured.

**Message brokers / queues:**
- None configured.

**Cloud auth / secret managers:**
- None detected.

---

*Integration audit: 2026-04-02*
