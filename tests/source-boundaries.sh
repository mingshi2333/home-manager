#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if rg -n '(karing|qq|telegram)-sources\.nix' \
  --glob '!docs/**' \
  --glob '!.planning/**' \
  --glob '!README.md' \
  --glob '!USAGE.md' \
  . >/dev/null; then
  echo "unexpected legacy root source metadata reference found" >&2
  exit 1
fi

test -f sources/karing.nix

rg -n 'sources/karing\.nix' packages/karing.nix >/dev/null
rg -n 'sources/karing\.nix' ops/hms-refresh.sh >/dev/null

test -f ops/hms-refresh.sh

if rg -n 'sources/(qq|karing|telegram)\.nix' modules packages --glob '!packages/karing.nix' >/dev/null; then
  echo "unexpected source metadata reference outside the owning package" >&2
  exit 1
fi

echo "source boundary checks passed"
