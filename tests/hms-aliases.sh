#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
alias_text=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval .#homeConfigurations.mingshi.config.home.file.\".zsh_aliases\".text --raw)

# Keep the command-surface check intentionally narrow: these aliases should
# point at the generated repo script or rollback command without hardcoded nix binaries.

hms_alias=$(printf '%s\n' "$alias_text" | grep '^alias hms=' || true)
hmu_alias=$(printf '%s\n' "$alias_text" | grep '^alias hmu=' || true)
hmr_alias=$(printf '%s\n' "$alias_text" | grep '^alias hmr=' || true)

assert_alias_matches() {
  local alias_line=$1
  local pattern=$2
  local message=$3

  if ! printf '%s\n' "$alias_line" | grep -Eq "$pattern"; then
    echo "$message" >&2
    exit 1
  fi
}

for alias_name in hms hmu hmr; do
  if ! printf '%s\n' "$alias_text" | grep -q "^alias ${alias_name}="; then
    echo "missing alias: ${alias_name}" >&2
    exit 1
  fi
done

assert_alias_matches \
  "$hms_alias" \
  "^alias hms='cd ~/.config/home-manager && /nix/store/[^']*-hms-refresh'$" \
  "expected hms alias to invoke generated hms-refresh script"

assert_alias_matches \
  "$hmu_alias" \
  "^alias hmu='cd ~/.config/home-manager && nix flake update && /nix/store/[^']*-hms-refresh'$" \
  "expected hmu alias to invoke generated hms-refresh script after nix flake update"

assert_alias_matches \
  "$hmr_alias" \
  "^alias hmr='cd ~/.config/home-manager && nix run .#home-manager -- switch --rollback --flake \\.'$" \
  "hmr alias does not use the flake-locked home-manager CLI"

managed_aliases=$(printf '%s\n' "$hms_alias" "$hmu_alias" "$hmr_alias")

if printf '%s\n' "$managed_aliases" | grep -Eq '/nix/store/[^[:space:]\"'"'"']*-nix-[^/]+/bin/nix( |$)'; then
  echo "hms aliases still hardcode a nix binary from pkgs" >&2
  exit 1
fi

if printf '%s\n' "$managed_aliases" | grep -Eq '/nix/store/[^[:space:]\"'"'"']*-nix-[^/]+/bin/nix-prefetch-url'; then
  echo "hms aliases still hardcode nix-prefetch-url from pkgs" >&2
  exit 1
fi
