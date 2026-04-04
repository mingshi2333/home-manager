# Home Manager Evolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reshape the repository so source metadata, package definitions, and host-local operational side effects are more clearly separated without changing the current user-visible desktop workflow.

**Architecture:** Keep `modules/` as declarative integration points, keep `sources/` as the single location for upstream app metadata, and move operational behavior behind explicit repo scripts rather than embedding complex imperative logic directly in Home Manager module bodies. The work is intentionally incremental and preserves the current Fedora KDE Wayland workflow while cleaning the boundaries that have already drifted.

**Tech Stack:** Nix flakes, Home Manager modules, shell scripts, `nix eval`, `home-manager switch`

---

### Task 1: Stabilize The Ops Layer Boundary

**Files:**
- Modify: `modules/home-manager-commands.nix`
- Modify: `hms-refresh.sh`
- Test: `tests/hms-aliases.sh`

- [ ] **Step 1: Write the failing command-surface test expectation**

Create or update the test logic in `tests/hms-aliases.sh` so it checks that the generated `hms` alias points to a repo script path rather than embedding the full operational shell body directly.

```bash
#!/usr/bin/env bash
set -euo pipefail

ALIASES_TEXT=$(nix eval .#homeConfigurations.mingshi.config.home.file.".zsh_aliases".text --raw)

if ! printf '%s\n' "$ALIASES_TEXT" | grep -q "alias hms='cd ~/.config/home-manager && /nix/store/.*-hms-refresh'"; then
  echo "expected hms alias to invoke generated hms-refresh script"
  exit 1
fi
```

- [ ] **Step 2: Run the test to verify it describes the current contract**

Run:

```bash
bash tests/hms-aliases.sh
```

Expected: PASS if `hms` already points to the generated script, or a clear failure message if the alias still embeds operational logic directly.

- [ ] **Step 3: Keep operational logic inside `hms-refresh.sh` and reduce the module surface to command exposure only**

Ensure `modules/home-manager-commands.nix` only does these jobs:

- generate aliases
- expose the generated refresh script
- keep `hmr` rollback simple

The module should continue to look structurally like this:

```nix
{ config, pkgs, ... }:

let
  hmSwitchCmd = "nix run .#home-manager -- switch --flake .";
  hmRollbackCmd = "nix run .#home-manager -- switch --rollback --flake .";
  refreshScript = pkgs.writeShellScript "hms-refresh" (
    builtins.replaceStrings
      [ "@grep_bin@" "@awk_bin@" "@sha256sum_bin@" "@runtime_shell@" ]
      [
        "${pkgs.gnugrep}/bin/grep"
        "${pkgs.gawk}/bin/awk"
        "${pkgs.coreutils}/bin/sha256sum"
        "${pkgs.runtimeShell}"
      ]
      (builtins.readFile ../hms-refresh.sh)
  );
in
{
  home.file = config.local.nixgl.binScripts // {
    ".zsh_aliases".text =
      let
        escapeAliasValue = v: builtins.replaceStrings [ "'" ] [ "'\\''" ] v;
        allAliases = config.local.nixgl.shellAliases // {
          hms = "cd ~/.config/home-manager && ${refreshScript}";
          hmu = "cd ~/.config/home-manager && nix flake update && ${refreshScript}";
          hmr = "cd ~/.config/home-manager && ${hmRollbackCmd}";
        };
      in
      pkgs.lib.concatStringsSep "\n" (
        pkgs.lib.mapAttrsToList (k: v: "alias ${k}='${escapeAliasValue v}'") allAliases
      );
  };
}
```

- [ ] **Step 4: Run the command-surface test again**

Run:

```bash
bash tests/hms-aliases.sh
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add modules/home-manager-commands.nix hms-refresh.sh tests/hms-aliases.sh
git commit -m "refactor: keep hms command module as command surface"
```

### Task 2: Normalize Source Metadata Ownership

**Files:**
- Modify: `sources/qq.nix`
- Modify: `sources/karing.nix`
- Modify: `flake.nix`
- Modify: `karing.nix`
- Modify: `hms-refresh.sh`

- [ ] **Step 1: Write the expected source-layer shape in the source files**

Each source file should stay data-only and use the same top-level pattern:

```nix
{ fetchurl }:
{
  x86_64-linux = {
    version = "...";
    src = fetchurl {
      url = "...";
      hash = "...";
    };
  };
}
```

For `qq`, it is acceptable to keep extra metadata such as `updateChannelVersion` or `src.type = "path"`, but the file should remain strictly metadata, not package logic.

- [ ] **Step 2: Verify that package definitions only consume source data and do not own refresh policy**

Check that:

- `flake.nix` only reads `sources/qq.nix` and applies the override
- `karing.nix` only reads `sources/karing.nix` and performs packaging
- `hms-refresh.sh` is the only place that mutates source files

Run:

```bash
rg -n 'sources/qq.nix|sources/karing.nix' flake.nix karing.nix hms-refresh.sh
```

Expected: references only in those three files.

- [ ] **Step 3: Keep source mutation in `hms-refresh.sh` but ensure the files remain metadata-only**

The script should continue to write data-only files like this for `karing`:

```bash
cat > sources/karing.nix <<EOF
# Generated by hms source refresh. Do not edit manually.
# Last updated: $(date +%F)
{ fetchurl }:
{
  x86_64-linux = {
    version = "$karing_version";
    src = fetchurl {
      url = "$karing_url";
      hash = "$karing_hash";
    };
  };
}
EOF
```

And for `qq` it may write either a `fetchurl` or a local-path source block, but it must still remain metadata-only.

- [ ] **Step 4: Verify the source layer still evaluates**

Run:

```bash
nix eval .#homeConfigurations.mingshi.pkgs.qq.version --raw
nix eval .#homeConfigurations.mingshi.pkgs.callPackage ./karing.nix {}.version --raw
```

Expected: both commands print versions and exit successfully.

- [ ] **Step 5: Commit**

```bash
git add sources/qq.nix sources/karing.nix flake.nix karing.nix hms-refresh.sh
git commit -m "refactor: keep source metadata and packaging concerns separate"
```

### Task 3: Isolate Karing Host-Local Privilege Handling

**Files:**
- Modify: `karing.nix`
- Modify: `hms-refresh.sh`
- Modify: `modules/desktop-entries.nix`

- [ ] **Step 1: Write the expected privilege-boundary rule as a focused check**

The package should own app-specific runtime wrappers, but host-local privilege synchronization must remain in `hms-refresh.sh`, not leak into generic modules.

Use this check:

```bash
rg -n 'karingService-root|49-karing-tun.rules|autostart/karing.desktop' karing.nix hms-refresh.sh modules/desktop-entries.nix
```

Expected:
- `karing.nix` owns wrapper/runtime behavior
- `hms-refresh.sh` owns helper/rule sync
- `modules/desktop-entries.nix` owns autostart/desktop exposure only

- [ ] **Step 2: Keep the app-specific workaround isolated to `karing.nix`**

The package file may continue to include app-local privilege workarounds like:

- `karingService` wrapper selection
- bundled `sudo` shim
- runtime `SHELL=/bin/sh`

But it should not grow any direct Home Manager module logic.

The package should continue to follow this shape:

```nix
makeWrapper $out/share/karing/karing $out/bin/karing \
  --set SHELL /bin/sh \
  --prefix PATH : "$out/libexec/karing" \
  --prefix LD_LIBRARY_PATH : "$out/share/karing/lib:${keybinder3}/lib:/usr/lib64"
```

- [ ] **Step 3: Keep autostart and desktop exposure out of the package file**

`modules/desktop-entries.nix` should continue to own the user-facing autostart exposure:

```nix
home.file.".config/autostart/karing.desktop".source = "${karing}/share/applications/karing.desktop";
```

That keeps desktop exposure separate from package construction.

- [ ] **Step 4: Verify the split still works in practice**

Run:

```bash
nix run .#home-manager -- switch --flake .
ls -l ~/.config/autostart/karing.desktop
stat -c '%a %A %U:%G %n' /usr/local/libexec/karing/karingService-root /etc/polkit-1/rules.d/49-karing-tun.rules
```

Expected:
- switch completes
- autostart link exists
- helper and rule still exist at the system paths

- [ ] **Step 5: Commit**

```bash
git add karing.nix hms-refresh.sh modules/desktop-entries.nix
git commit -m "refactor: isolate karing host-local privilege handling"
```

### Task 4: Add A Small Boundary Review Safety Net

**Files:**
- Modify: `tests/hms-aliases.sh`
- Create: `tests/source-boundaries.sh`

- [ ] **Step 1: Write a small boundary regression script**

Create `tests/source-boundaries.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

rg -n 'telegram-sources\.nix' . && {
  echo "unexpected legacy telegram source reference found"
  exit 1
} || true

rg -n 'sources/qq.nix|sources/karing.nix' flake.nix karing.nix hms-refresh.sh >/dev/null

if rg -n 'sources/qq.nix' modules >/dev/null; then
  echo "modules should not directly own source metadata references"
  exit 1
fi

if rg -n 'sources/karing.nix' modules >/dev/null; then
  echo "modules should not directly own source metadata references"
  exit 1
fi

echo "source boundary checks passed"
```

- [ ] **Step 2: Run the new boundary check and existing alias check**

Run:

```bash
bash tests/source-boundaries.sh
bash tests/hms-aliases.sh
```

Expected:
- `source boundary checks passed`
- alias test passes

- [ ] **Step 3: Keep the test scope intentionally small**

Do not build a giant test suite here. The point is only to protect the newly clarified boundaries:

- source files stay in `sources/`
- command exposure stays thin
- modules do not directly own source refresh policy

- [ ] **Step 4: Re-run the targeted tests after any fixes**

Run:

```bash
bash tests/source-boundaries.sh
bash tests/hms-aliases.sh
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/source-boundaries.sh tests/hms-aliases.sh
git commit -m "test: cover home-manager boundary contracts"
```

## Spec Coverage Check

- **Boundary clarity:** Covered by Tasks 1, 2, and 3.
- **Source layer normalization:** Covered by Task 2.
- **Ops layer isolation:** Covered by Tasks 1 and 3.
- **Maintainability-first evolution:** Covered by the full sequence; no attempt to force a large-scale purity rewrite.
- **Non-goals respected:** No multi-host framework rewrite, no new custom Nix framework, no broad unrelated refactor.

## Placeholder Scan

- No `TBD` / `TODO` / deferred implementation placeholders remain.
- All task steps include exact file paths and commands.
- Code steps include concrete snippets rather than references like "same as before".

## Type And Naming Consistency Check

- Source files are consistently referred to as `sources/qq.nix` and `sources/karing.nix`.
- The operational script is consistently referred to as `hms-refresh.sh`.
- The karing privilege paths are consistently referred to as `/usr/local/libexec/karing/karingService-root` and `/etc/polkit-1/rules.d/49-karing-tun.rules`.
