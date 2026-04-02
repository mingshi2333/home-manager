# Codebase Concerns

**Analysis Date:** 2026-04-02

## Tech Debt

**Custom nixGL fork and wrapper layer:**
- Issue: `nixgl-noimpure.nix` vendors a large customized copy of nixGL logic instead of depending only on upstream `nix-community/nixGL`, which increases upgrade effort and makes local fixes easy to diverge from upstream behavior.
- Files: `nixgl-noimpure.nix`, `modules/nixgl-runtime.nix`, `nixgl-apps.nix`, `flake.nix`
- Impact: Upgrading `nixpkgs`, `home-manager`, or `nixGL` can break GPU wrapping, Vulkan setup, or desktop launch behavior without a clear migration path.
- Fix approach: Isolate local deltas behind smaller helper modules or overlays, document why the fork exists, and keep only the minimum custom surface in `nixgl-noimpure.nix`.

**Large catalog file with mixed responsibilities:**
- Issue: `nixgl-apps.nix` combines wrapper generation, desktop file rewriting, D-Bus service rewriting, alias generation, local bin script generation, MIME association generation, and the full application catalog in one 538-line file.
- Files: `nixgl-apps.nix`
- Impact: Small changes have wide blast radius, review cost is high, and mistakes in one helper can silently affect every wrapped application.
- Fix approach: Split helper functions from app catalog data, and move special cases such as `lenovo-legion` into dedicated module files.

**Activation hooks performing imperative filesystem cleanup:**
- Issue: `modules/desktop-entries.nix` and `modules/plasma.nix` perform deletion, symlink mutation, process inspection, and process restart work during activation.
- Files: `modules/desktop-entries.nix`, `modules/plasma.nix`
- Impact: Home Manager apply becomes stateful and harder to reason about; failures can leave partial desktop state or interrupt the user session.
- Fix approach: Reduce activation logic to idempotent operations, prefer declarative Home Manager facilities where possible, and gate risky runtime actions behind explicit options.

## Known Bugs

**Documentation and implementation disagree on `--impure` behavior:**
- Symptoms: Docs instruct users that `hms`, `hmu`, and `hmr` run `home-manager switch --impure`, but the alias implementation uses `nix run .#home-manager -- switch --flake .` without `--impure`.
- Files: `modules/home-manager-commands.nix`, `README.md`, `USAGE.md`, `tests/hms-aliases.sh`
- Trigger: Following the documentation instead of the generated alias behavior.
- Workaround: Trust the alias implementation in `modules/home-manager-commands.nix` rather than the prose in `README.md` and `USAGE.md`.

**32-bit GPU wrapper paths are explicitly untested:**
- Symptoms: NVIDIA wrapper code contains repeated TODO notes for 32-bit support and does not demonstrate repository-level validation for those paths.
- Files: `nixgl-noimpure.nix`
- Trigger: Running 32-bit OpenGL or Vulkan applications through the generated wrappers.
- Workaround: None in repo beyond avoiding those code paths.

## Security Considerations

**Repository mutation from convenience aliases:**
- Risk: Running `hms` or `hmu` writes `nvidia/version` and `nvidia/hash` inside the repo before switching configuration.
- Files: `modules/home-manager-commands.nix`, `modules/nixgl-runtime.nix`, `nvidia/version`, `nvidia/hash`
- Current mitigation: `modules/nixgl-runtime.nix` validates version parsing and hash format before consuming the files.
- Recommendations: Separate generated host metadata from tracked source, or gate these writes behind an explicit maintenance command so routine apply operations stay read-only.

**Privileged desktop launcher via `pkexec`:**
- Risk: The custom Lenovo Legion launcher exposes privileged GUI and CLI entry points through wrappers in the user profile.
- Files: `nixgl-apps.nix`
- Current mitigation: The launcher shells directly to packaged binaries instead of arbitrary user input.
- Recommendations: Document expected polkit behavior, confirm the package paths are stable, and add a smoke test for the generated desktop entry and shell wrapper names.

**No secret files detected, but safety posture is mostly by convention:**
- Risk: The repository does not expose `.env`, key, or credential files in the scanned tree, but shell-heavy modules manipulate external commands and user-local state without strong validation around command success.
- Files: `modules/home-manager-commands.nix`, `modules/desktop-entries.nix`, `modules/plasma.nix`
- Current mitigation: Some commands use format checks and `|| true` to avoid hard failure.
- Recommendations: Replace broad error suppression with targeted checks and log explicit failure conditions for risky operations.

## Performance Bottlenecks

**Activation-time desktop database rebuilds and directory hashing:**
- Problem: Every activation walks `~/.local/share/applications` and `~/.nix-profile/share/applications`, computes hashes, rewrites symlinks, and may rebuild desktop caches.
- Files: `modules/desktop-entries.nix`
- Cause: Desktop synchronization is implemented as a shell script rather than by narrower declarative outputs.
- Improvement path: Limit the work to generated entries only, avoid full-directory scans where possible, and add logging to quantify slow paths.

**Repeated flake evaluation in tests and aliases:**
- Problem: The only test and the user aliases rely on `nix eval` or `nix run` over the whole flake, which is heavier than validating individual modules.
- Files: `tests/hms-aliases.sh`, `modules/home-manager-commands.nix`, `flake.nix`
- Cause: Validation is centered on end-to-end command strings rather than narrower checks.
- Improvement path: Add `checks` in `flake.nix` for targeted assertions and keep shell-based smoke tests as a thin outer layer.

## Fragile Areas

**Hardcoded host and platform assumptions:**
- Files: `flake.nix`, `hosts/mingshi/home.nix`, `modules/environment.nix`, `modules/plasma.nix`
- Why fragile: The configuration hardcodes `system = "x86_64-linux"`, `home.username = "mingshi"`, `home.homeDirectory = "/home/mingshi"`, `/usr/bin/plasmashell`, and multiple `/usr` search paths.
- Safe modification: Change host identity and platform values together, then verify all generated paths and activation scripts.
- Test coverage: No test covers alternate usernames, alternate home directories, non-KDE sessions, or non-`x86_64-linux` systems.

**Cross-module environment duplication:**
- Files: `modules/environment.nix`, `modules/fcitx.nix`, `modules/fcitx-env.nix`, `modules/desktop-entries.nix`, `nixgl-apps.nix`, `modules/home-manager-commands.nix`
- Why fragile: PATH, XDG data dirs, GTK input method values, and Wayland-related variables are assembled in multiple places with slightly different mechanisms.
- Safe modification: Centralize shared environment construction in one helper and import it from runtime, activation, and wrapper code.
- Test coverage: No test asserts that shell aliases, `environment.d` files, desktop activation, and wrapper scripts stay consistent.

**Shell-based desktop file rewriting:**
- Files: `nixgl-apps.nix`
- Why fragile: `sed -i` rewrites `Exec=` and `MimeType=` lines using pattern assumptions that may not hold for every packaged `.desktop` file or D-Bus service file.
- Safe modification: Add assertions for missing matches, and validate a sample of generated desktop files for each rewriting mode.
- Test coverage: No automated test covers wrapper output, desktop file correctness, or D-Bus service patching.

## Scaling Limits

**Application catalog growth:**
- Current capacity: The catalog works for the current small-to-medium set of wrapped GUI apps.
- Limit: As more apps with special-case launch requirements are added, the single-file catalog in `nixgl-apps.nix` becomes harder to audit and more expensive to safely change.
- Scaling path: Move to per-app definitions or category-based files while keeping shared wrapper helpers separate.

**Single-host repository model:**
- Current capacity: One host import chain centered on `hosts/mingshi/home.nix`.
- Limit: Additional machines, users, or Linux distributions will require either conditionals across many modules or duplicated host trees.
- Scaling path: Parameterize username, home directory, and platform-specific behavior via options or per-host modules.

## Dependencies at Risk

**`nixos-unstable` without repository-level compatibility checks:**
- Risk: `flake.nix` tracks `github:NixOS/nixpkgs/nixos-unstable`, and the repo contains a local overlay workaround for `dwarfs` versus `boost` compatibility.
- Impact: Upstream package set churn can break packages, wrappers, or activation-time commands unexpectedly.
- Migration plan: Add `checks` to `flake.nix`, keep compatibility overrides narrowly scoped, and document which packages are known to require pinning.

**Custom override for `dwarfs`:**
- Risk: The overlay pins `dwarfs` to `boost187` as a temporary workaround.
- Impact: Future `nixpkgs` updates may invalidate the override or hide when the workaround is no longer needed.
- Migration plan: Track the upstream fix condition and remove the override as soon as `nixpkgs` no longer requires it.

## Missing Critical Features

**No flake `checks` or comprehensive validation pipeline:**
- Problem: `flake.nix` exposes a Home Manager package and configuration but no `checks` output.
- Blocks: Reliable CI-style validation for generated wrappers, desktop entries, activation scripts, and documentation drift.

**No automated verification for activation and wrapper side effects:**
- Problem: Only `tests/hms-aliases.sh` exists, and it validates command strings rather than the generated desktop entries, bin scripts, or runtime behavior.
- Blocks: Safe refactoring of `nixgl-apps.nix`, `modules/desktop-entries.nix`, and `modules/plasma.nix`.

## Test Coverage Gaps

**nixGL runtime and metadata ingestion:**
- What's not tested: Parsing of `nvidia/version`, validation of `nvidia/hash`, and failure behavior in `modules/nixgl-runtime.nix`.
- Files: `modules/nixgl-runtime.nix`, `modules/home-manager-commands.nix`, `nvidia/version`, `nvidia/hash`
- Risk: A malformed metadata update can break evaluation or produce wrappers that fail only at runtime.
- Priority: High

**Desktop entry generation and cleanup:**
- What's not tested: Symlink deduplication, hash caching, MIME association output, and `update-desktop-database` / `kbuildsycoca` invocation logic.
- Files: `modules/desktop-entries.nix`, `nixgl-apps.nix`
- Risk: Menu entries can disappear, duplicate, or point at broken wrappers without being caught before activation.
- Priority: High

**Plasma restart behavior:**
- What's not tested: Process restart logic, fallback to `/usr/bin/plasmashell`, and behavior when `HM_PLASMA_RESTART=1` in mixed session states.
- Files: `modules/plasma.nix`
- Risk: Applying the configuration can destabilize the running desktop session.
- Priority: Medium

---

*Concerns audit: 2026-04-02*
