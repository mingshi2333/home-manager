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
rbw_config=$(jq -c . "$repo_root/config/rbw/config.json")
rbw_config_force=$(eval_json 'xdg.configFile."rbw/config.json".force')
ydotool_exec_json=$(eval_json 'systemd.user.services.ydotool.Service.ExecStart')

for package in rbw rofi-rbw fuzzel wl-clipboard ydotool pinentry-qt; do
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
  'typing-start-delay=500' \
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

if [[ "$rbw_config_force" != "true" ]]; then
  echo "expected Home Manager to force-own rbw/config.json" >&2
  exit 1
fi

if ! rg -n 'source = \.\./config/rbw/config\.json;' "$repo_root/modules/bitwarden-autotype.nix" >/dev/null; then
  echo "expected rbw/config.json to be deployed from config/rbw/config.json" >&2
  exit 1
fi

if ! jq -e '
  (.email == null or (.email | type == "string"))
  and .base_url == null
  and .lock_timeout == 14400
  and .sync_interval == 3600
  and .pinentry == "pinentry-qt"
' <<<"$rbw_config" >/dev/null; then
  echo "expected config/rbw/config.json to define rbw desktop defaults" >&2
  exit 1
fi

echo "bitwarden autotype checks passed"
