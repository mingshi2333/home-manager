---
status: fixing
trigger: "Investigate and fix the hmu SSL certificate failure in this repository."
created: 2026-04-16T00:00:00Z
updated: 2026-04-16T00:08:00Z
---

## Current Focus

hypothesis: `hmu` fails because its standalone wrapper invokes `nix flake update` without exporting a Fedora CA bundle path, so libcurl/Nix cannot validate HTTPS certificates on this machine.
test: Patch `modules/home-manager-commands.nix` so generated `hmu` exports `NIX_SSL_CERT_FILE` and `SSL_CERT_FILE` to `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` before `nix flake update`, then rerun the regression test.
expecting: The targeted test should pass once the generated wrapper includes both exports before the update command.
next_action: patch modules/home-manager-commands.nix with minimal CA-bundle exports for hmu

## Symptoms

expected: `hmu` runs `nix flake update` and then the normal refresh flow successfully on this Fedora machine.
actual: `nix` HTTPS fetches fail with `SSL certificate problem: unable to get local issuer certificate`.
errors: reproduced with `nix flake metadata github:NixOS/nixpkgs --extra-experimental-features 'nix-command flakes'`, which fails without cert env and succeeds when `NIX_SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` is set.
reproduction: from repo root, run `nix flake metadata github:NixOS/nixpkgs --extra-experimental-features 'nix-command flakes'`; then rerun with `NIX_SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` exported and observe success.
started: current repo state; likely exposed after `hmu` became a standalone wrapper script without any SSL certificate environment setup.

## Eliminated

## Evidence

- timestamp: 2026-04-16T00:00:00Z
  checked: modules/home-manager-commands.nix
  found: The generated `.local/bin/hmu` script changes into `~/.config/home-manager`, runs `nix flake update`, then execs the refresh script, with no CA bundle environment export.
  implication: The current wrapper does not carry machine-specific SSL trust configuration into the `nix flake update` step.

- timestamp: 2026-04-16T00:05:00Z
  checked: tests/hms-aliases.sh
  found: Existing command-surface tests assert that `hmu` runs `nix flake update`, but they do not check for any SSL trust environment setup.
  implication: The current test suite would not catch regression of Fedora CA-bundle handling for `hmu`.

- timestamp: 2026-04-16T00:05:00Z
  checked: common bug patterns + knowledge base
  found: Symptom matches Environment/Config category (missing or wrong environment variable / machine-specific path). No debug knowledge-base file exists yet.
  implication: The most likely root cause is missing trust-store environment wiring, and there is no prior session to reuse.

- timestamp: 2026-04-16T00:08:00Z
  checked: bash tests/hms-aliases.sh
  found: The new regression test fails with `expected hmu wrapper script to export the Fedora CA bundle for nix HTTPS fetches`.
  implication: The current generated `hmu` script is missing the CA-bundle exports required by the bug reproduction, confirming the hypothesis.

## Resolution

root_cause: The standalone `hmu` wrapper runs `nix flake update` without exporting the Fedora CA trust bundle path, so Nix HTTPS fetches cannot validate remote certificates on this machine.
fix:
verification:
files_changed: []
