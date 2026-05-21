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

## Notes

- `hmu` can bring in broad upstream changes through `flake.lock`; use it deliberately.
- `hmgc` deletes unreferenced store paths but keeps anything still reachable from live
  generations.
- Qt apps that are unstable under native Wayland can be forced through XWayland by
  setting the app catalog platform to `xcb`.
