#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

wps_script=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.home.file.".local/bin/wps".text' --raw)
wpspdf_script=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.home.file.".local/bin/wpspdf".text' --raw)
wps_desktop=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.xdg.desktopEntries."wps-office-prometheus".exec' --raw)
wpspdf_desktop=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.xdg.desktopEntries."wps-office-pdf".exec' --raw)

assert_contains() {
  local text=$1
  local pattern=$2
  local message=$3

  if ! printf '%s\n' "$text" | grep -Eq "$pattern"; then
    echo "$message" >&2
    exit 1
  fi
}

assert_contains "$wps_script" 'QT_QPA_PLATFORM=xcb' 'expected WPS wrapper to force xcb'
assert_contains "$wpspdf_script" 'QT_QPA_PLATFORM=xcb' 'expected WPS PDF wrapper to force xcb'
assert_contains "$wps_desktop" '^/home/mingshi/.local/bin/wps( |$)' 'expected WPS desktop entry to use managed wrapper'
assert_contains "$wpspdf_desktop" '^/home/mingshi/.local/bin/wpspdf( |$)' 'expected WPS PDF desktop entry to use managed wrapper'
