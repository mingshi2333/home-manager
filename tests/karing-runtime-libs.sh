#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
karing_drv=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' build .#homeConfigurations.mingshi.activationPackage --no-link --print-out-paths | tail -n1)

if [ -z "$karing_drv" ]; then
  echo "failed to build home-manager activation package" >&2
  exit 1
fi

karing_pkg=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval .#homeConfigurations.mingshi.config.home.packages --json | grep -o '/nix/store/[^\"]*-karing-[^\"]*' | head -n1)

if [ -z "$karing_pkg" ]; then
  echo "karing package not found in evaluated home.packages" >&2
  exit 1
fi

karing_bin="$karing_pkg/bin/karing"

if [ -z "$karing_bin" ]; then
  echo "karing binary not found in built home profile" >&2
  exit 1
fi

karing_output=$(timeout 12s "$karing_bin" 2>&1 || true)

if printf '%s\n' "$karing_output" | grep -Fq 'error while loading shared libraries'; then
  echo "karing still fails during dynamic library loading" >&2
  printf '%s\n' "$karing_output" >&2
  exit 1
fi

if printf '%s\n' "$karing_output" | grep -Fq 'libkeybinder-3.0.so.0'; then
  echo "karing still surfaces the missing libkeybinder runtime error" >&2
  printf '%s\n' "$karing_output" >&2
  exit 1
fi
