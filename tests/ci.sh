#!/usr/bin/env bash
# CI-safe test tiers. Run from the repo root (or via `nix run .#test`).
#
# Excludes the live-desktop tests, which need a running Wayland/KDE session and
# must never run headless: session-validation.sh, session-launch-capture.sh,
# karing-runtime-libs.sh (the last one launches the karing GUI binary).
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== tier A: pure static boundary tests (ripgrep only) =="
bash tests/source-boundaries.sh
bash tests/karing-package-boundary.sh

echo "== tier B: eval / build tests (need nix) =="
bash tests/compatibility-boundary.sh
bash tests/bitwarden-autotype.sh
bash tests/desktop-working-directory.sh
bash tests/wps-wrapper.sh
bash tests/hms-aliases.sh

echo "All CI-safe tests passed."
