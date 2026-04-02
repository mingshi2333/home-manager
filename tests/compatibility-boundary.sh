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
electron_profiles_json=$(eval_json electronRepairProfiles)
session_variables_json=$(cd "$repo_root" && nix eval --json '.#homeConfigurations.mingshi.config.home.sessionVariables')

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
if [[ "$qq_platform" != "x11" ]]; then
  echo "qq policy did not export expected safe x11 platform" >&2
  exit 1
fi

qq_profile=$(jq -r '.qq.profile' <<<"$policies_json")
if [[ "$qq_profile" != "xwayland-safe" ]]; then
  echo "qq policy did not export expected default profile metadata" >&2
  exit 1
fi

qq_profile_is_default=$(jq -r '.qq.profileIsDefault' <<<"$policies_json")
if [[ "$qq_profile_is_default" != "true" ]]; then
  echo "qq policy should mark the default profile surface" >&2
  exit 1
fi

qq_wayland_test_platform=$(jq -r '.["qq-wayland-test"].platform' <<<"$policies_json")
if [[ "$qq_wayland_test_platform" != "wayland" ]]; then
  echo "qq-wayland-test policy did not export expected wayland platform" >&2
  exit 1
fi

qq_wayland_test_profile=$(jq -r '.["qq-wayland-test"].profile' <<<"$policies_json")
if [[ "$qq_wayland_test_profile" != "wayland-test" ]]; then
  echo "qq-wayland-test policy did not export expected profile metadata" >&2
  exit 1
fi

qq_wayland_test_default=$(jq -r '.["qq-wayland-test"].profileDefault' <<<"$policies_json")
if [[ "$qq_wayland_test_default" != "xwayland-safe" ]]; then
  echo "qq-wayland-test policy lost default profile linkage" >&2
  exit 1
fi

qq_wayland_test_is_default=$(jq -r '.["qq-wayland-test"].profileIsDefault' <<<"$policies_json")
if [[ "$qq_wayland_test_is_default" != "false" ]]; then
  echo "qq-wayland-test policy must remain explicit opt-in surface" >&2
  exit 1
fi

qq_profile_surfaces=$(jq -r '.qq.profileAvailable | join(",")' <<<"$policies_json")
if [[ "$qq_profile_surfaces" != "xwayland-safe,wayland-test" ]]; then
  echo "qq policy lost exported profile availability metadata" >&2
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

qq_wayland_has_wayland_flag=$(jq -e '.["qq-wayland-test"].extraFlags | index("--ozone-platform-hint=wayland") != null' <<<"$policies_json" >/dev/null && echo true || echo false)
if [[ "$qq_wayland_has_wayland_flag" != "false" ]]; then
  echo "compatibility policy should not leak derived wrapper defaults into qq-wayland-test metadata" >&2
  exit 1
fi

policy_global_env_leaks=$(jq '[to_entries[] | select((.value.extraEnv | has("GTK_USE_PORTAL")) or (.value.extraEnv | has("NIXOS_XDG_OPEN_USE_PORTAL")) or (.value.extraEnv | has("XMODIFIERS")) or (.value.extraEnv | has("GTK_IM_MODULE")) or (.value.extraEnv | has("QT_IM_MODULE"))) | .key]' <<<"$policies_json")

if [[ $(jq 'length' <<<"$policy_global_env_leaks") -ne 0 ]]; then
  echo "compatibility policies leaked session-global environment ownership for: $(jq -r 'join(", ")' <<<"$policy_global_env_leaks")" >&2
  exit 1
fi

policy_electron_env=$(jq '[to_entries[] | select((.value.extraEnv | has("ELECTRON_OZONE_PLATFORM_HINT")) or (.value.extraEnv | has("NIXOS_OZONE_WL"))) | .key]' <<<"$policies_json")
if [[ $(jq 'length' <<<"$policy_electron_env") -lt 2 ]]; then
  echo "profile-aware compatibility policies should export per-profile Electron backend env" >&2
  exit 1
fi

qq_inventory_desktop=$(jq -r '.qq.desktopId' <<<"$inventory_json")
if [[ "$qq_inventory_desktop" != "qq" ]]; then
  echo "qq inventory desktop surface diverged from its default profile id" >&2
  exit 1
fi

qq_wayland_inventory_desktop=$(jq -r '.["qq-wayland-test"].desktopId' <<<"$inventory_json")
if [[ "$qq_wayland_inventory_desktop" != "qq-wayland-test" ]]; then
  echo "qq-wayland-test inventory desktop surface diverged from its profile id" >&2
  exit 1
fi

qq_inventory_profile=$(jq -r '.qq.profile' <<<"$inventory_json")
qq_wayland_inventory_profile=$(jq -r '.["qq-wayland-test"].profile' <<<"$inventory_json")
if [[ "$qq_inventory_profile" != "xwayland-safe" || "$qq_wayland_inventory_profile" != "wayland-test" ]]; then
  echo "inventory export lost qq profile metadata parity" >&2
  exit 1
fi

if ! jq -e '.["xwayland-safe"].platform == "x11" and .["wayland-test"].platform == "wayland"' <<<"$electron_profiles_json" >/dev/null; then
  echo "electron repair profile catalog is missing expected safe/test presets" >&2
  exit 1
fi

if jq -e 'has("ELECTRON_OZONE_PLATFORM_HINT") or has("NIXOS_OZONE_WL")' <<<"$session_variables_json" >/dev/null; then
  echo "session variables still force a global Electron backend" >&2
  exit 1
fi

if rg -n 'ELECTRON_OZONE_PLATFORM_HINT|NIXOS_OZONE_WL' "$repo_root/modules/environment.nix" >/dev/null; then
  echo "modules/environment.nix still owns global Electron backend forcing" >&2
  exit 1
fi

if ! jq -e 'type == "object" and has("GTK_IM_MODULE") and has("QT_IM_MODULE") and has("XMODIFIERS")' <<<"$fcitx_env_json" >/dev/null; then
  echo "fcitxEnv export is missing expected session-level IME variables" >&2
  exit 1
fi
