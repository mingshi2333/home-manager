#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

script_path="ops/hms-refresh.sh"

if ! grep -q '/etc/sudoers.d/49-karing-tun' "$script_path"; then
  echo "expected hms-refresh.sh to manage a dedicated karing sudoers rule" >&2
  exit 1
fi

if ! grep -q 'NOPASSWD:' "$script_path"; then
  echo "expected hms-refresh.sh to provision a passwordless karing sudoers entry" >&2
  exit 1
fi

if ! grep -q '/usr/bin/chown' "$script_path"; then
  echo "expected hms-refresh.sh to authorize the karing chown helper path" >&2
  exit 1
fi

if ! grep -q '/usr/bin/chmod +sx /nix/store/\*/share/karing/karingService' "$script_path"; then
  echo "expected hms-refresh.sh to authorize the karing chmod helper path" >&2
  exit 1
fi
