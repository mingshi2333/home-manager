#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

wps_script=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.home.file.".local/bin/wps".text' --raw)
wpspdf_script=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.home.file.".local/bin/wpspdf".text' --raw)
wps_et_script=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.home.file.".local/bin/et".text' --raw)
wps_wpp_script=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.home.file.".local/bin/wpp".text' --raw)
wps_desktop=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.local.wps.desktopEntries."wps-office-prometheus".exec' --raw)
wpspdf_desktop=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.local.wps.desktopEntries."wps-office-pdf".exec' --raw)
wps_writer_desktop=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.local.wps.desktopEntries."wps-office-wps".exec' --raw)
wps_et_desktop=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.local.wps.desktopEntries."wps-office-et".exec' --raw)
wps_wpp_desktop=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval '.#homeConfigurations.mingshi.config.local.wps.desktopEntries."wps-office-wpp".exec' --raw)

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
assert_contains "$wps_et_script" 'QT_QPA_PLATFORM=xcb' 'expected WPS Spreadsheets wrapper to force xcb'
assert_contains "$wps_wpp_script" 'QT_QPA_PLATFORM=xcb' 'expected WPS Presentation wrapper to force xcb'
assert_contains "$wps_desktop" '^/home/mingshi/.local/bin/wps( |$)' 'expected WPS desktop entry to use managed wrapper'
assert_contains "$wpspdf_desktop" '^/home/mingshi/.local/bin/wpspdf( |$)' 'expected WPS PDF desktop entry to use managed wrapper'
assert_contains "$wps_writer_desktop" '^/home/mingshi/.local/bin/wps( |$)' 'expected WPS Writer desktop entry to use managed wrapper'
assert_contains "$wps_et_desktop" '^/home/mingshi/.local/bin/et( |$)' 'expected WPS Spreadsheets desktop entry to use managed wrapper'
assert_contains "$wps_wpp_desktop" '^/home/mingshi/.local/bin/wpp( |$)' 'expected WPS Presentation desktop entry to use managed wrapper'
