# Consensus Plan: Simplify New App Configuration

## Requirements Summary

- Standard new apps should usually be added in one place, not split between `nixgl-apps.nix` and `modules/nixgl-runtime.nix`.
- Most repeated metadata should be derived automatically in the standard path, with opt-in overrides for fields that are truly app-specific.
- The current output flow must stay recognizable: registry -> `local.nixgl.*` -> packages, aliases, desktop entries, and MIME associations.
- Special-case apps like `modules/lenovo-legion.nix` should remain separate for now, but the repo should document that path explicitly.
- Keep this to a one-session refactor; do not redesign `nixgl-noimpure.nix` or unrelated runtime internals.

## Acceptance Criteria Mapping

- One source of truth: remove the hardcoded standard enablement list in `modules/nixgl-runtime.nix` and derive enabled standard apps from the catalog in `nixgl-apps.nix`.
- Repeated fields derived: add a higher-level helper above `mkNixGLApp` that defaults `binary`, `desktopName`, `comment`, and `icon` where possible, while still allowing overrides.
- Stable naming: use the attr key as the catalog id, but do not rename existing wrapper names in this refactor.
- Standard vs special path: treat `nixgl-apps.nix` as the standard path and `modules/lenovo-legion.nix` as the explicit special-case pattern.
- Output flow preserved: keep `local.nixgl.appPackages`, `shellAliases`, `binScripts`, `desktopEntries`, and `mimeAssociations` as the stable interface consumed by downstream modules.
- Migration story: migrate only straightforward standard apps now and leave non-trivial entries explicit.
- Docs shorter/clearer: rewrite `README.md` and trim `USAGE.md` so the happy path is “add one catalog entry,” with a short separate note for exceptions.

## Concrete Implementation Steps

1. Keep `wrapWithNixGL` and `mkNixGLApp` as the low-level compatibility layer, then add a new standard helper in `nixgl-apps.nix`.
   - Use the attr key as the catalog id.
   - Only default wrapper `name` when the id already matches the desired wrapper and desktop basename.
   - Derive `binary` from `pkg.meta.mainProgram` or `name`.
   - Derive `desktopName` from an explicit `displayName` override or a conservative fallback.
   - Derive `comment` from `pkg.meta.description` or `${desktopName} (nixGL)`.
   - Default `icon` to the app id unless overridden.
   - Keep `categories`, `mimeTypes`, `extraEnv`, `extraFlags`, `execArgs`, `dbusService`, and aliases overrideable.
2. Reshape the standard registry in `nixgl-apps.nix` into a catalog that owns standard-app enablement.
   - Add `enable ? true` per standard app.
   - Keep exported outputs limited to the current runtime surface.
   - Leave the low-level helper available so nonstandard apps can stay on the old helper if needed.
3. In `modules/nixgl-runtime.nix`, switch from “runtime owns enabled app names” to “runtime imports the catalog and exposes its derived state.”
   - Replace `enabledNixglApps` with catalog-derived standard ids.
   - Define `local.nixgl.enabledApps` as enabled standard catalog ids only.
   - Remove `lenovo-legion` from that list; it remains owned by `modules/lenovo-legion.nix`.
   - Keep the `local.nixgl.*` option surface otherwise stable so downstream modules need little or no logic change.
4. Limit migration scope in this session.
   - Migrate only apps whose catalog id, wrapper name, desktop basename, and branding are already aligned.
   - Keep explicit low-level entries for exceptions like `ayugram` and `element` if they do not fit the standard defaults cleanly.
5. Clarify the special-case extension path.
   - Keep `modules/lenovo-legion.nix` behavior unchanged.
   - Document the rule: if an app needs pkexec, custom scripts, or custom desktop file behavior, keep it in its own module instead of forcing it through the standard catalog.
6. Update docs to match the code.
   - Replace the current stale multi-field example in `README.md` with a shorter “standard app” example that shows the minimal required fields plus optional overrides.
   - Add a short “special-case apps” subsection pointing to `modules/lenovo-legion.nix` as the current extension pattern.
   - Shorten `USAGE.md` guidance so users no longer think they must edit runtime/module lists for ordinary apps.
7. Leave these alone unless forced by the refactor.
   - `nixgl-noimpure.nix`
   - `modules/packages.nix`
   - `modules/home-manager-commands.nix`
   - most of `modules/desktop-entries.nix`
   - unrelated host/profile wiring

## Risks And Mitigations

- Metadata derivation may be wrong or missing for some packages.
  - Make defaults conservative and override-first.
- Behavior drift from moving enablement into the catalog.
  - Keep `local.nixgl.*` outputs identical in shape and compare derived ids and output keys before and after.
- Desktop dedup regressions for apps whose desktop file names differ from app ids.
  - Support explicit per-app dedup prefixes and keep legacy Telegram extras as manual overrides.
- Migration scope could grow if every existing app is rewritten.
  - Migrate only straightforward entries and keep `mkNixGLApp` as a fallback.

## Verification Steps

- `home-manager build --flake .#mingshi --impure`
- `nix eval --json .#homeConfigurations.mingshi.config.local.nixgl.enabledApps`
- `nix eval --json --apply builtins.attrNames .#homeConfigurations.mingshi.config.local.nixgl.desktopEntries`
- `nix eval --json .#homeConfigurations.mingshi.config.local.nixgl.mimeAssociations`
- `nix eval --json .#homeConfigurations.mingshi.config.local.nixgl.shellAliases`
- Compare pre/post output shape instead of adding a temporary scratch app entry
- Optional full local apply: `hms`

## Review Verdict

`PASS_WITH_EDITS` after tightening the naming rules, clarifying that `enabledApps` means standard catalog ids only, and limiting migration to straightforward entries.

## Approved Scope

- Add a higher-level standard helper in `nixgl-apps.nix`.
- Move standard-app enablement into the catalog with `enable ? true`.
- Keep `wrapWithNixGL`, `mkNixGLApp`, `modules/lenovo-legion.nix`, and downstream `local.nixgl.*` consumers intact.
- Migrate only straightforward standard apps now; leave non-trivial entries explicit.
- Update `README.md` and `USAGE.md` to document the one-entry path and the special-case module path.
