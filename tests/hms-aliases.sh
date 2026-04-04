#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
alias_text=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval .#homeConfigurations.mingshi.config.home.file.\".zsh_aliases\".text --raw)

for alias_name in hms hmu; do
  if ! printf '%s\n' "$alias_text" | grep -q "^alias ${alias_name}="; then
    echo "missing alias: ${alias_name}" >&2
    exit 1
  fi
done

if ! printf '%s\n' "$alias_text" | grep -q "alias hms='cd ~/.config/home-manager && /nix/store/.*-hms-refresh'"; then
  echo "expected hms alias to invoke generated hms-refresh script" >&2
  exit 1
fi

if ! printf '%s\n' "$alias_text" | grep -q "alias hmu='cd ~/.config/home-manager && nix flake update && /nix/store/.*-hms-refresh'"; then
  echo "expected hmu alias to invoke generated hms-refresh script after nix flake update" >&2
  exit 1
fi

if ! printf '%s\n' "$alias_text" | grep -F "nix run .#home-manager -- switch --rollback --flake ." >/dev/null; then
  echo "hmr alias does not use the flake-locked home-manager CLI" >&2
  exit 1
fi

if printf '%s\n' "$alias_text" | grep -Eq '/nix/store/[^[:space:]\"'"'"']*-nix-[^/]+/bin/nix( |$)'; then
  echo "hms aliases still hardcode a nix binary from pkgs" >&2
  exit 1
fi

if printf '%s\n' "$alias_text" | grep -Eq '/nix/store/[^[:space:]\"'"'"']*-nix-[^/]+/bin/nix-prefetch-url'; then
  echo "hms aliases still hardcode nix-prefetch-url from pkgs" >&2
  exit 1
fi
