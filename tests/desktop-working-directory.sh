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

eval_json() {
  local attr=$1

  (
    cd "$repo_root"
    nix --extra-experimental-features 'nix-command flakes dynamic-derivations' \
      eval ".#homeConfigurations.mingshi.config.${attr}" --json
  )
}

download_dir=$(eval_raw 'xdg.userDirs.download')
expected_working_dir="${download_dir}/nix"
nixgl_entries_json=$(eval_json 'local.nixgl.desktopEntries')
codex_exec=$(eval_raw 'local.nixgl.desktopEntries."codex-desktop".exec')
claude_exec=$(eval_raw 'local.nixgl.desktopEntries."claude-desktop".exec')
wps_writer_path=$(eval_raw 'local.wps.desktopEntries."wps-office-wps".settings.Path')

if ! jq -e --arg path "$expected_working_dir" \
  'to_entries | all(.value.settings.Path == $path)' \
  <<<"$nixgl_entries_json" >/dev/null; then
  echo "expected every nixGL desktop entry to default Path to ${expected_working_dir}" >&2
  exit 1
fi

if [[ "$codex_exec" != *' %u' ]]; then
  echo 'expected Codex desktop entry to preserve URL callback argument' >&2
  exit 1
fi

if [[ "$claude_exec" != *' %u' ]]; then
  echo 'expected Claude desktop entry to preserve URL callback argument' >&2
  exit 1
fi

if [[ "$wps_writer_path" != "$expected_working_dir" ]]; then
  echo "expected WPS desktop entry Path to be ${expected_working_dir}, got ${wps_writer_path}" >&2
  exit 1
fi
