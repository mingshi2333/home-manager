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

## Bitwarden Auto-Type

Home Manager installs the KDE Wayland path through `rbw`, plain `rofi-rbw`,
`fuzzel`, `wl-clipboard`, `xdotool`, `ydotool`, and `pinentry-qt`. It also owns both
`~/.config/rofi-rbw.rc` and `~/.config/rbw/config.json`.

Declare the account in `config/rbw/config.json`:

```json
{
  "email": "your-email@example.com",
  "base_url": "https://your-vaultwarden.example.com"
}
```

Then apply and unlock:

```bash
hms
rbw sync
rbw unlock
rbw ls
```

Home Manager binds one shortcut to remember:

```text
Ctrl + Alt + B -> Bitwarden action menu
```

The menu has these actions:

```text
Login - username/password
Login + TOTP - same page
Copy TOTP - paste yourself
Type TOTP - current field
X11 Login - fallback
```

`rofi-rbw` does not inspect the target page. If an account needs a remembered
typing order, add a custom Bitwarden field on that item:

```text
_autotype = username:tab:password:tab:totp
```

Use `_autotype = username:tab:password` for normal one-page login forms and
`_autotype = username:tab:password:tab:totp:enter` only when pressing Enter is
safe for that account. Two-step TOTP pages should leave TOTP out of `_autotype`;
after password auto-type, paste the copied TOTP into the second page.

Direct fallback shortcuts still exist, but they are optional:

```text
Ctrl + Alt + O -> username, password, and same-page TOTP
Ctrl + Alt + Shift + B -> xdotool fallback for XWayland/X11 apps
```

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
