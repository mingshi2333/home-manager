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
