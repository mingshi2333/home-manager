# Home Manager Usage

## Daily Workflow

Apply local changes:

```bash
hms
```

Update flake inputs and apply the result:

```bash
hmu
```

Roll back one generation:

```bash
hmr
```

Build and inspect the activation package without writing `result` in the repo:

```bash
hmb
```

Clean old generations and optimise the Nix store:

```bash
hmgc
```

## What The Aliases Do

`hms` changes into `~/.config/home-manager`, refreshes managed local metadata when
needed, and runs:

```bash
nix run .#home-manager -- switch --flake .
```

`hmu` runs `nix flake update` before the same switch path.

`hmr` uses the flake-locked Home Manager package to roll back the previous generation.

`hmb` builds the local flake from `~/Desktop/home-manager/build/manual` and leaves
the `result` link there.

`hmgc` removes old user profile generations, expires Home Manager generations older
than three days, runs `nix-collect-garbage`, and finishes with `nix-store --optimise`.

## Adding Applications

Add regular nixGL GUI apps to `nixgl-apps.nix`:

```nix
myapp = standardApp {
  pkg = pkgs.myapp;
  platform = "wayland";
  categories = [ "Utility" ];
};
```

Use `customApp` only when the app needs a custom launcher, special desktop entry, or
non-standard command wiring.
Desktop entries default to the `nix` subdirectory inside the XDG download
directory. Use `workingDirectory` only when a GUI app should override that default
or `null` to omit `Path=`.

Put custom package expressions under `packages/` and keep their source metadata under
`sources/`.

## Troubleshooting

If a switch fails, build the activation package first:

```bash
nix build '.#homeConfigurations.mingshi.activationPackage' --no-link
```

If desktop entries do not appear after a switch, refresh KDE caches manually:

```bash
update-desktop-database ~/.local/share/applications
kbuildsycoca6
```

If a GUI app fails to launch, check the user journal:

```bash
journalctl --user -xe
```

## Local Output Directory

Repository tests and manual diagnostics should keep generated logs and `result`
links outside `~/.config/home-manager`. By default, the helper scripts use the XDG
desktop directory under `home-manager/`.

For a manual Home Manager build that leaves a browsable `result` link:

```bash
mkdir -p "$(xdg-user-dir DESKTOP)/home-manager/build/manual"
cd "$(xdg-user-dir DESKTOP)/home-manager/build/manual"
nix run ~/.config/home-manager#home-manager -- build --flake ~/.config/home-manager
```

## Notes

- `hmu` can bring in broad upstream changes through `flake.lock`; use it deliberately.
- `hmgc` deletes unreferenced store paths but keeps anything still reachable from live
  generations.
- Qt apps that are unstable under native Wayland can be forced through XWayland by
  setting the app catalog platform to `xcb`.
