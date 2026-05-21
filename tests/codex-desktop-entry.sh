#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

eval_raw() {
  local attr=$1

  (
    cd "$repo_root"
    nix --extra-experimental-features 'nix-command flakes dynamic-derivations' \
      eval ".#homeConfigurations.mingshi.config.${attr}" --raw
  )
}

codex_exec=$(eval_raw 'xdg.desktopEntries."codex-desktop".exec')
codex_path=$(eval_raw 'xdg.desktopEntries."codex-desktop".settings.Path')
home_dir=$(eval_raw 'home.homeDirectory')

if [[ "$codex_exec" != *' %u' ]]; then
  echo 'expected Codex desktop entry to preserve URL callback argument' >&2
  exit 1
fi

if [[ "$codex_path" != "$home_dir" ]]; then
  echo "expected Codex desktop entry Path to be ${home_dir}, got ${codex_path}" >&2
  exit 1
fi
