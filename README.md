# Home Manager Configuration

Fedora KDE Wayland desktop configuration managed with Nix flakes and Home Manager.

This repository is intentionally kept as a deployable configuration repo: Nix modules,
package expressions, source pins, operational scripts, and tests. Local workspaces,
generated planning notes, cache files, and editor state are ignored.

## Layout

- `flake.nix` / `flake.lock` - pinned flake inputs and the `mingshi` Home Manager output
- `home.nix` - shared composition root
- `hosts/mingshi/home.nix` - host identity and home directory
- `profiles/` - thin module groups
- `modules/` - Home Manager modules and activation hooks
- `nixgl-apps.nix` - nixGL-wrapped GUI application catalog
- `nixgl-noimpure.nix` - local nixGL wrapper implementation
- `packages/` - custom package expressions
- `sources/` - source metadata for custom packages
- `nvidia/` - NVIDIA runtime metadata consumed by nixGL
- `ops/` - maintenance scripts used by helper aliases
- `tests/` - shell checks for generated config boundaries

## Common Commands

```bash
hms   # refresh managed metadata, then switch through the flake-locked Home Manager
hmu   # update flake inputs, refresh metadata, then switch
hmr   # roll back the previous Home Manager generation
hmb   # build into the desktop output directory and leave a browsable result link
hmgc  # clean old generations, run Nix GC, then optimise the Nix store
```

The direct switch command is:

```bash
nix run .#home-manager -- switch --flake .
```

## Adding GUI Apps

Regular nixGL-wrapped applications belong in `nixgl-apps.nix`:

```nix
myapp = standardApp {
  pkg = pkgs.myapp;
  platform = "wayland";
  categories = [ "Utility" ];
  mimeTypes = [ "x-scheme-handler/myapp" ];
  execArgs = "%U";
};
```

Use `standardApp` for normal nixGL wrappers and `customApp` for hand-written
launchers, `pkexec` helpers, or applications that need unusual desktop metadata.

Custom package expressions belong in `packages/`, and their source metadata belongs
in `sources/`. For example, Karing is split between `packages/karing.nix` and
`sources/karing.nix`.

## Validation

Run focused checks before committing:

```bash
bash tests/source-boundaries.sh
bash tests/karing-package-boundary.sh
bash tests/wps-wrapper.sh
bash tests/hms-aliases.sh
nix build '.#homeConfigurations.mingshi.activationPackage' --no-link
```

For a broader smoke pass:

```bash
bash -n tests/*.sh ops/hms-refresh.sh
shellcheck tests/*.sh ops/hms-refresh.sh
nix flake check --no-build --extra-experimental-features 'nix-command flakes'
```

Validation logs and temporary Home Manager build links should stay outside this
repository. The helper tests default to the XDG desktop directory under
`home-manager/`, for example `~/Desktop/home-manager/session-validation/...` and
`~/Desktop/home-manager/build/...`. Use `hmb` for a manual build that leaves
`~/Desktop/home-manager/build/manual/result`.

## Desktop Integration

Home Manager owns the generated desktop entries, MIME associations, wrapper scripts,
and KDE cache refresh hooks. The active modules refresh the desktop database and KDE
service cache on activation, so normal changes should only require `hms`.

WPS Office is managed in `modules/wps.nix` because it needs multiple wrapper-backed
desktop entries. Most other GUI apps should stay in the shared `nixgl-apps.nix`
catalog.
