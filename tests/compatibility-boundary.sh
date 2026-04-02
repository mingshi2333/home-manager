#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
flake_ref='.#homeConfigurations.mingshi.config.local.nixgl'

eval_json() {
  local attr=$1
  cd "$repo_root" && nix eval --json "${flake_ref}.${attr}"
}

enabled_apps_json=$(eval_json enabledApps)
inventory_json=$(eval_json appInventory)
policies_json=$(eval_json compatibilityPolicies)
fcitx_env_json=$(eval_json fcitxEnv)

enabled_count=$(jq 'length' <<<"$enabled_apps_json")
inventory_count=$(jq 'keys | length' <<<"$inventory_json")
policy_count=$(jq 'keys | length' <<<"$policies_json")

if (( inventory_count < enabled_count )); then
  echo "inventory does not cover the full wrapped GUI catalog" >&2
  exit 1
fi

if (( inventory_count != policy_count )); then
  echo "inventory and compatibility policy exports diverged" >&2
  exit 1
fi

missing_enabled=$(jq -n \
  --argjson enabled "$enabled_apps_json" \
  --argjson inventory "$inventory_json" \
  '$enabled - ($inventory | keys)')

if [[ $(jq 'length' <<<"$missing_enabled") -ne 0 ]]; then
  echo "inventory is missing enabled apps: $(jq -r 'join(", ")' <<<"$missing_enabled")" >&2
  exit 1
fi

invalid_health=$(jq '[to_entries[] | select(.value.health | IN("affected", "suspected", "healthy", "unknown") | not) | .key]' <<<"$inventory_json")

if [[ $(jq 'length' <<<"$invalid_health") -ne 0 ]]; then
  echo "inventory exports invalid health states for: $(jq -r 'join(", ")' <<<"$invalid_health")" >&2
  exit 1
fi

qq_platform=$(jq -r '.qq.platform' <<<"$policies_json")
if [[ "$qq_platform" != "wayland" ]]; then
  echo "qq policy did not export expected wayland platform" >&2
  exit 1
fi

zotero_platform=$(jq -r '.zotero.platform' <<<"$policies_json")
if [[ "$zotero_platform" != "x11" ]]; then
  echo "zotero policy did not export expected x11 platform" >&2
  exit 1
fi

zotero_im_module=$(jq -r '.zotero.extraEnv.GTK_IM_MODULE_FILE' <<<"$policies_json")
if [[ "$zotero_im_module" != "/home/mingshi/.nix-profile/etc/gtk-3.0/immodules.cache" ]]; then
  echo "zotero policy did not export expected GTK_IM_MODULE_FILE override" >&2
  exit 1
fi

qq_has_wayland_flag=$(jq -e '.qq.extraFlags | index("--ozone-platform-hint=wayland") != null' <<<"$policies_json" >/dev/null && echo true || echo false)
if [[ "$qq_has_wayland_flag" != "false" ]]; then
  echo "compatibility policy should expose only raw per-app extraFlags, not derived wrapper defaults" >&2
  exit 1
fi

policy_global_env_leaks=$(jq '[to_entries[] | select((.value.extraEnv | has("GTK_USE_PORTAL")) or (.value.extraEnv | has("NIXOS_XDG_OPEN_USE_PORTAL")) or (.value.extraEnv | has("XMODIFIERS")) or (.value.extraEnv | has("GTK_IM_MODULE")) or (.value.extraEnv | has("QT_IM_MODULE"))) | .key]' <<<"$policies_json")

if [[ $(jq 'length' <<<"$policy_global_env_leaks") -ne 0 ]]; then
  echo "compatibility policies leaked session-global environment ownership for: $(jq -r 'join(", ")' <<<"$policy_global_env_leaks")" >&2
  exit 1
fi

if ! jq -e 'type == "object" and has("GTK_IM_MODULE") and has("QT_IM_MODULE") and has("XMODIFIERS")' <<<"$fcitx_env_json" >/dev/null; then
  echo "fcitxEnv export is missing expected session-level IME variables" >&2
  exit 1
fi
