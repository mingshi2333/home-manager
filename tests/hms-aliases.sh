#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
alias_text=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval .#homeConfigurations.mingshi.config.home.file.\".zsh_aliases\".text --raw)
hms_script_text=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval .#homeConfigurations.mingshi.config.home.file.\".local/bin/hms\".text --raw)
hmu_script_text=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval .#homeConfigurations.mingshi.config.home.file.\".local/bin/hmu\".text --raw)
hmr_script_text=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval .#homeConfigurations.mingshi.config.home.file.\".local/bin/hmr\".text --raw)
hmgc_script_text=$(cd "$repo_root" && nix --extra-experimental-features 'nix-command flakes dynamic-derivations' eval .#homeConfigurations.mingshi.config.home.file.\".local/bin/hmgc\".text --raw)

# Keep the command-surface check intentionally narrow: these aliases should
# forward to generated repo-local wrapper scripts rather than hardcoded nix binaries.

hms_alias=$(printf '%s\n' "$alias_text" | grep '^alias hms=' || true)
hmu_alias=$(printf '%s\n' "$alias_text" | grep '^alias hmu=' || true)
hmr_alias=$(printf '%s\n' "$alias_text" | grep '^alias hmr=' || true)
hmgc_alias=$(printf '%s\n' "$alias_text" | grep '^alias hmgc=' || true)

assert_alias_matches() {
  local alias_line=$1
  local pattern=$2
  local message=$3

  if ! printf '%s\n' "$alias_line" | grep -Eq "$pattern"; then
    echo "$message" >&2
    exit 1
  fi
}

for alias_name in hms hmu hmr hmgc; do
  if ! printf '%s\n' "$alias_text" | grep -q "^alias ${alias_name}="; then
    echo "missing alias: ${alias_name}" >&2
    exit 1
  fi
done

assert_script_contains() {
  local script_text=$1
  local pattern=$2
  local message=$3

  if ! printf '%s\n' "$script_text" | grep -Eq "$pattern"; then
    echo "$message" >&2
    exit 1
  fi
}

assert_alias_matches \
  "$hms_alias" \
  "^alias hms='~/.local/bin/hms'$" \
  "expected hms alias to invoke the generated hms wrapper script"

assert_alias_matches \
  "$hmu_alias" \
  "^alias hmu='~/.local/bin/hmu'$" \
  "expected hmu alias to invoke the generated hmu wrapper script"

assert_alias_matches \
  "$hmr_alias" \
  "^alias hmr='~/.local/bin/hmr'$" \
  "expected hmr alias to invoke the generated hmr wrapper script"

assert_alias_matches \
  "$hmgc_alias" \
  "^alias hmgc='~/.local/bin/hmgc'$" \
  "expected hmgc alias to invoke the generated hmgc wrapper script"

assert_script_contains \
  "$hms_script_text" \
  '^exec /nix/store/[^[:space:]]*-hms-refresh$' \
  'expected hms wrapper script to invoke generated hms-refresh script'

assert_script_contains \
  "$hms_script_text" \
  '^export NIX_SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle\.pem$' \
  'expected hms wrapper script to export the Fedora CA bundle for nix HTTPS fetches'

assert_script_contains \
  "$hms_script_text" \
  '^export SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle\.pem$' \
  'expected hms wrapper script to export matching SSL_CERT_FILE for curl-compatible consumers'

assert_script_contains \
  "$hms_script_text" \
  '^locked_rev="\$\(nix flake metadata --json \. \| /nix/store/[^[:space:]]*-jq-[^[:space:]]*/bin/jq -r '\''\.locks\.nodes\."codex-desktop-linux"\.locked\.rev // empty'\''\)"$' \
  'expected hms wrapper script to read the locked Codex Desktop revision before updating'

assert_script_contains \
  "$hms_script_text" \
  '^[[:space:]]*if ! remote_rev="\$\(nix flake metadata --json github:ilysenko/codex-desktop-linux \| /nix/store/[^[:space:]]*-jq-[^[:space:]]*/bin/jq -r '\''\.revision // \.locked\.rev // empty'\''\)"; then$' \
  'expected hms wrapper script to check the remote Codex Desktop revision before updating'

assert_script_contains \
  "$hms_script_text" \
  '^[[:space:]]*if \[ "\$locked_rev" != "\$remote_rev" \]; then$' \
  'expected hms wrapper script to update Codex Desktop only when the remote revision differs'

assert_script_contains \
  "$hms_script_text" \
  '^[[:space:]]*nix flake update codex-desktop-linux$' \
  'expected hms wrapper script to update only the Codex Desktop input when needed'

assert_script_contains \
  "$hmu_script_text" \
  '^export NIX_SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle\.pem$' \
  'expected hmu wrapper script to export the Fedora CA bundle for nix HTTPS fetches'

assert_script_contains \
  "$hmu_script_text" \
  '^export SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle\.pem$' \
  'expected hmu wrapper script to export matching SSL_CERT_FILE for curl-compatible consumers'

assert_script_contains \
  "$hmu_script_text" \
  '^nix flake update$' \
  'expected hmu wrapper script to update the flake before refresh'

assert_script_contains \
  "$hmr_script_text" \
  "nix run \.#home-manager -- switch --rollback --flake \." \
  'expected hmr wrapper script to use the flake-locked home-manager CLI'

assert_script_contains \
  "$hmgc_script_text" \
  '/nix/store/[^[:space:]]*-hmgc-cleanup' \
  'expected hmgc wrapper script to invoke generated cleanup script'

managed_aliases=$(printf '%s\n' "$hms_alias" "$hmu_alias" "$hmr_alias" "$hmgc_alias")

hmgc_script_path=$(cd "$repo_root" && nix run .#home-manager -- build --flake . >/dev/null && sed -n "s/^exec \(\/nix\/store\/[^[:space:]]*-hmgc-cleanup\)$/\1/p" result/home-files/.local/bin/hmgc)

if ! grep -Fq 'home-manager expire-generations "-3 days"' "$hmgc_script_path"; then
  echo 'expected hmgc cleanup script to keep only 3 days of Home Manager generations' >&2
  exit 1
fi

if ! grep -Fq 'nix-store --optimise' "$hmgc_script_path"; then
  echo 'expected hmgc cleanup script to optimise live Nix store paths after GC' >&2
  exit 1
fi

if printf '%s\n' "$managed_aliases" | grep -Eq '/nix/store/[^[:space:]\"'"'"']*-nix-[^/]+/bin/nix( |$)'; then
  echo "hms aliases still hardcode a nix binary from pkgs" >&2
  exit 1
fi

if printf '%s\n' "$managed_aliases" | grep -Eq '/nix/store/[^[:space:]\"'"'"']*-nix-[^/]+/bin/nix-prefetch-url'; then
  echo "hms aliases still hardcode nix-prefetch-url from pkgs" >&2
  exit 1
fi
