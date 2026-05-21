#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

rg -n 'sources/karing\.nix' packages/karing.nix >/dev/null
rg -n 'sources/karing\.nix' ops/hms-refresh.sh >/dev/null

if rg -n '/etc/sudoers\.d/49-karing-tun|/etc/polkit-1/rules\.d/49-karing-tun|karingService-root' \
  ops modules packages >/dev/null; then
  echo "unexpected host-privileged karing helper management found" >&2
  exit 1
fi

if ! rg -n 'keybinder3' packages/karing.nix >/dev/null; then
  echo "expected karing package to carry the runtime keybinder library fix" >&2
  exit 1
fi
