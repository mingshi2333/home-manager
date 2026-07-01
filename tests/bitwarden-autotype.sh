#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

eval_raw() {
  local attr=$1

  (
    cd "$repo_root"
    nix --extra-experimental-features 'nix-command flakes dynamic-derivations' \
      eval ".#homeConfigurations.mingshi.config.${attr}" --raw
  )
}

eval_json() {
  local attr=$1

  (
    cd "$repo_root"
    nix --extra-experimental-features 'nix-command flakes dynamic-derivations' \
      eval ".#homeConfigurations.mingshi.config.${attr}" --json
  )
}

packages_json=$(eval_json 'home.packages')
rofi_rbw_config=$(eval_raw 'xdg.configFile."rofi-rbw.rc".text')
rbw_config_force=$(eval_json 'xdg.configFile."rbw/config.json".force')
ydotool_exec_json=$(eval_json 'systemd.user.services.ydotool.Service.ExecStart')
shortcut_activation=$(eval_raw 'home.activation.configureRofiRbwShortcut.data')

for package in rbw rofi-rbw fuzzel wl-clipboard xdotool ydotool pinentry-qt; do
  if ! jq -e --arg package "$package" 'any(.[]; contains($package))' <<<"$packages_json" >/dev/null; then
    echo "expected home.packages to include ${package}" >&2
    exit 1
  fi
done

if jq -e 'any(.[]; contains("rofi-rbw-wayland"))' <<<"$packages_json" >/dev/null; then
  echo "rofi-rbw-wayland forces wtype in the Nix wrapper; use plain rofi-rbw with explicit ydotool config" >&2
  exit 1
fi

for expected_line in \
  'selector=fuzzel' \
  'clipboarder=wl-copy' \
  'typer=ydotool' \
  'typing-start-delay=0.5' \
  'typing-key-delay=20' \
  'clear-after=20'; do
  if ! grep -Fxq "$expected_line" <<<"$rofi_rbw_config"; then
    echo "missing rofi-rbw config line: ${expected_line}" >&2
    exit 1
  fi
done

if ! jq -e '.[0] | endswith("/bin/ydotoold")' <<<"$ydotool_exec_json" >/dev/null; then
  echo "expected the user ydotool service to start ydotoold" >&2
  exit 1
fi

if ! rg -n 'Exec=\$\{rofiRbwMenu\}' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected the primary Bitwarden auto-type desktop launcher to open the action menu" >&2
  exit 1
fi

for expected_menu_item in \
  'Login - username/password' \
  'Login + TOTP - same page' \
  'Copy TOTP - paste yourself' \
  'Type TOTP - current field' \
  'X11 Login - fallback'; do
  if ! grep -Fq "$expected_menu_item" "$repo_root/modules/bitwarden-autotype.nix"; then
    echo "missing Bitwarden auto-type menu item: ${expected_menu_item}" >&2
    exit 1
  fi
done

if ! rg -n 'rofi-rbw --action copy --target totp' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected the Bitwarden auto-type menu to offer copy-only TOTP" >&2
  exit 1
fi

if ! rg -n 'rofi-rbw --target totp' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected the Bitwarden auto-type menu to offer type-only TOTP" >&2
  exit 1
fi

if ! rg -n 'Exec=rofi-rbw --typer xdotool --selector fuzzel --clipboarder wl-copy --typing-start-delay 0\.3 --typing-key-delay 10' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected the XWayland Bitwarden auto-type desktop launcher to force xdotool" >&2
  exit 1
fi

if ! rg -n 'Exec=rofi-rbw --target username --target tab --target password --target tab --target totp' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected the same-page TOTP Bitwarden auto-type desktop launcher to type username/password/totp" >&2
  exit 1
fi

if ! rg -n 'X-KDE-Shortcuts=Ctrl\+Alt\+B' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected the Bitwarden auto-type desktop launcher to declare Ctrl+Alt+B" >&2
  exit 1
fi

if ! rg -n 'X-KDE-Shortcuts=Ctrl\+Alt\+Shift\+B' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected the XWayland Bitwarden auto-type desktop launcher to declare Ctrl+Alt+Shift+B" >&2
  exit 1
fi

if ! rg -n 'X-KDE-Shortcuts=Ctrl\+Alt\+O' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected the same-page TOTP Bitwarden auto-type desktop launcher to declare Ctrl+Alt+O" >&2
  exit 1
fi

if ! grep -Fq 'rofi-rbw-autotype.desktop' <<<"$shortcut_activation"; then
  echo "expected activation to bind the rofi-rbw-autotype desktop service" >&2
  exit 1
fi

if ! grep -Fq 'rofi-rbw-autotype-xwayland.desktop' <<<"$shortcut_activation"; then
  echo "expected activation to bind the XWayland rofi-rbw-autotype desktop service" >&2
  exit 1
fi

if ! grep -Fq 'rofi-rbw-autotype-totp.desktop' <<<"$shortcut_activation"; then
  echo "expected activation to bind the same-page TOTP rofi-rbw-autotype desktop service" >&2
  exit 1
fi

if ! grep -Fq 'Ctrl+Alt+B,none,Bitwarden Auto-Type' <<<"$shortcut_activation"; then
  echo "expected activation to bind Ctrl+Alt+B to Bitwarden Auto-Type" >&2
  exit 1
fi

if ! grep -Fq 'Ctrl+Alt+Shift+B,none,Bitwarden Auto-Type XWayland' <<<"$shortcut_activation"; then
  echo "expected activation to bind Ctrl+Alt+Shift+B to Bitwarden Auto-Type XWayland" >&2
  exit 1
fi

if ! grep -Fq 'Ctrl+Alt+O,none,Bitwarden Auto-Type Same-Page TOTP' <<<"$shortcut_activation"; then
  echo "expected activation to bind Ctrl+Alt+O to Bitwarden Auto-Type Same-Page TOTP" >&2
  exit 1
fi

if ! grep -Fq '201326658' <<<"$shortcut_activation"; then
  echo "expected activation to register Ctrl+Alt+B with KGlobalAccel" >&2
  exit 1
fi

if ! grep -Fq '234881090' <<<"$shortcut_activation"; then
  echo "expected activation to register Ctrl+Alt+Shift+B with KGlobalAccel" >&2
  exit 1
fi

if ! grep -Fq '201326671' <<<"$shortcut_activation"; then
  echo "expected activation to register Ctrl+Alt+O with KGlobalAccel" >&2
  exit 1
fi

if [[ "$rbw_config_force" != "true" ]]; then
  echo "expected Home Manager to force-own rbw/config.json" >&2
  exit 1
fi

# The rbw config holds the account email and self-hosted server URL, so it must
# stay OUT of the repo and the Nix store: an out-of-store symlink to
# ~/.secrets/rbw-config.json, never an in-repo file.
if ! rg -n 'mkOutOfStoreSymlink "\$\{config\.home\.homeDirectory\}/\.secrets/rbw-config\.json"' \
  "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected rbw/config.json to be an out-of-store symlink to ~/.secrets/rbw-config.json" >&2
  exit 1
fi

if [ -e "$repo_root/config/rbw" ]; then
  echo "config/rbw must not exist in the repo: rbw secrets live at ~/.secrets/rbw-config.json" >&2
  exit 1
fi

echo "bitwarden autotype checks passed"
