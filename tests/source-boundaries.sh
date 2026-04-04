#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if rg -n 'telegram-sources\.nix' \
  --glob '!docs/**' \
  --glob '!.planning/**' \
  --glob '!README.md' \
  --glob '!USAGE.md' \
  . >/dev/null; then
  echo "unexpected legacy telegram source reference found" >&2
  exit 1
fi

rg -n 'sources/qq\.nix' flake.nix >/dev/null
rg -n 'sources/karing\.nix' karing.nix >/dev/null
rg -n 'sources/qq\.nix' hms-refresh.sh >/dev/null
rg -n 'sources/karing\.nix' hms-refresh.sh >/dev/null

if rg -n 'sources/qq.nix|sources/karing.nix' modules >/dev/null; then
  echo "modules should not directly own source metadata references" >&2
  exit 1
fi

echo "source boundary checks passed"
