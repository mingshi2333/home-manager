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
Desktop entries default to `config.xdg.userDirs.download + "/nix"` as their
working directory. Set `workingDirectory` only when an app needs a different
default or `null` to omit `Path=`.

Custom package expressions belong in `packages/`, and their source metadata belongs
in `sources/`. For example, Karing is split between `packages/karing.nix` and
`sources/karing.nix`.

## Validation

One command runs every CI-safe tier (pure boundary tests + eval/build tests):

```bash
bash tests/ci.sh        # or: nix run .#test
```

The flake also wires real gates (note: no `--no-build`, or the check
derivations are instantiated but never run):

```bash
nix flake check         # builds the sandbox-pure boundary checks
nix fmt                 # nixfmt over the tree (CI gates on the --check form)
```

For focused runs, the individual scripts still work (`bash tests/<name>.sh`),
and a broader lint pass is:

```bash
bash -n tests/*.sh ops/hms-refresh.sh
shellcheck tests/*.sh ops/hms-refresh.sh   # .shellcheckrc disables SC2016
nix build '.#homeConfigurations.mingshi.activationPackage' --no-link
```

The live-desktop diagnostics (`session-validation.sh`, `session-launch-capture.sh`,
`karing-runtime-libs.sh`) need a running KDE Wayland session (the last one launches
the karing GUI); they are intentionally excluded from `tests/ci.sh` and CI.

Validation logs and temporary Home Manager build links should stay outside this
repository. The helper tests default to the XDG desktop directory under
`home-manager/`, for example `~/Desktop/home-manager/session-validation/...` and
`~/Desktop/home-manager/build/...`. Use `hmb` for a manual build that leaves
`~/Desktop/home-manager/build/manual/result`.

## Desktop Integration

Home Manager owns the generated desktop entries, MIME associations, wrapper scripts,
and KDE cache refresh hooks. The active modules refresh the desktop database and KDE
service cache on activation, so normal changes should only require `hms`.

Bitwarden auto-type is managed in `modules/bitwarden-autotype.nix`. It installs
`rbw`, plain `rofi-rbw`, `fuzzel`, `wl-clipboard`, `xdotool`, `ydotool`, and `pinentry-qt`;
plain `rofi-rbw` is intentional because the Wayland wrapper forces `wtype` while
this desktop uses `ydotool` for KDE Wayland typing. The `rbw` config lives OUT of
the repo and the Nix store: Home Manager creates an out-of-store symlink
`~/.config/rbw/config.json` -> `~/.secrets/rbw-config.json`, so your account email
and self-hosted server URL are never published. Create that file yourself (see
USAGE.md). The KDE global
shortcut `Ctrl+Alt+B` is bound to the generated `rofi-rbw-autotype.desktop`
launcher during activation and opens a small action menu: normal login,
same-page TOTP login, copy-only TOTP, type-only TOTP, and X11 fallback. Per-account
input order belongs in the Bitwarden item itself via a custom `_autotype` field;
for example, set `_autotype` to `username:tab:password:tab:totp` when that account
uses a one-page TOTP form. Direct shortcuts still exist for common fallback paths:
`Ctrl+Alt+O` runs the same-page TOTP sequence and `Ctrl+Alt+Shift+B` forces
`xdotool` for XWayland/X11 windows.

WPS Office is managed in `modules/wps.nix` because it needs multiple wrapper-backed
desktop entries. Most other GUI apps should stay in the shared `nixgl-apps.nix`
catalog.
