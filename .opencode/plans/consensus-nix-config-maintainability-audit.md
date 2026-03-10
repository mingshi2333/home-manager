# Consensus Plan: Nix Config Maintainability Audit

## Requirements Summary

- Keep this to a one-session, maintainability-first refactor: thin the orchestration in `home.nix`, clarify module boundaries, and reduce brittle activation behavior.
- Treat the main risks as structural, not feature gaps: `home.nix`, `profiles/gui.nix`, `profiles/packages.nix`, `modules/desktop-entries.nix`, and the command/NVIDIA metadata path are the highest-leverage files.
- Touch nixGL only where it creates coupling or impure operational burden; do not rewrite `nixgl-noimpure.nix` in this session.
- Preserve behavior first: same host entry in `hosts/mingshi/home.nix`, same wrapped app set from `nixgl-apps.nix`, same desktop-entry sync intent, same optional Plasma restart behavior.
- Update only the structure map and command usage docs after the refactor.

## Acceptance Criteria Mapping

- `Top 3 hotspots identified`
  - `home.nix`: centralizes NVIDIA metadata parsing, nixGL construction, app selection, command aliases, and profile wiring.
  - Module boundary coupling: `profiles/gui.nix` and `profiles/packages.nix` pass runtime data into imported modules instead of letting modules read a stable internal interface.
  - Activation fragility: `modules/desktop-entries.nix` embeds a long imperative shell flow with stateful side effects.
- `Prioritized recommendation list`
  - High: extract runtime/orchestration concerns out of `home.nix`; replace arg-threading with a declared internal option namespace.
  - Medium: move command/NVIDIA metadata orchestration into a focused module; keep desktop-entry behavior unchanged while reducing top-level coupling.
  - Low: document the new structure; leave deeper nixGL and Plasma behavior cleanup for a later pass.
- `Executable refactor guidance`
  - The plan below gives concrete file edits, sequence, and safe stop points.
- `Why home.nix / module boundaries / activation fragility matter`
  - `home.nix` is currently the repo’s de facto control plane, so every new concern increases hidden coupling.
  - Arg-threaded imports make modules harder to reason about, reuse, and test in isolation.
  - Activation scripts are failure-prone because they mix declarative config with mutable filesystem state.
- `nixGL / impurity coverage`
  - Keep the wrapper core intact, but isolate NVIDIA metadata refresh and `--impure` command behavior behind a narrower module boundary.
- `Validation ideas included`
  - Each major step has a corresponding verification command in section 5.

## Concrete Implementation Steps

1. Add `modules/nixgl-runtime.nix` as a declared read-only internal namespace.
   - Declare `options.local.nixgl.*`.
   - Compute `nvidiaVersion`, `nvidiaHash`, `nixGLPackage`, `nixGLBin`, selected apps, desktop-entry names, wrapped app outputs, and shared fcitx env from tracked files plus literals only.
   - Do not derive any `local.nixgl.*` value from `config.xdg.*`, `config.home.file`, or any module that already consumes `local.nixgl.*`.
2. Turn `home.nix` into a thin composition root.
   - Keep `nixpkgs.config.allowUnfree`, `programs.home-manager.enable`, and imports.
   - Import `modules/nixgl-runtime.nix`, a focused commands module, and the existing profiles.
3. Convert profile wiring to config-driven imports.
   - Change `profiles/gui.nix` to plain imports.
   - Change `profiles/packages.nix` to plain imports.
   - Update `modules/packages.nix` and `modules/desktop-entries.nix` to read `config.local.nixgl.*` instead of receiving runtime arguments.
4. Move command orchestration out of `home.nix`.
   - Add `modules/home-manager-commands.nix`.
   - Move `hms`, `hmu`, and `hmr` alias generation plus the NVIDIA metadata refresh helper there.
   - Keep command names and current behavior stable.
5. Only do a verbatim lift for desktop-entry activation logic if needed.
   - Preserve `entryAfter [ "reloadSystemd" ]`, `$DRY_RUN_CMD`, hash short-circuiting, and current sync/dedup semantics exactly.
   - If extraction becomes more than a straight lift, defer it and only switch the module to the new internal namespace.
6. Keep Plasma behavior unchanged in this session.
   - Do not change the `HM_PLASMA_RESTART` contract.
   - Only touch `modules/plasma.nix` if a pure verbatim script extraction is obviously safe; otherwise leave it alone.
7. Update docs last.
   - Update the structure map and command usage sections in `README.md` and `USAGE.md`.

## Risks And Mitigations

- `Evaluation recursion risk`
  - Declare the internal namespace explicitly and compute it in one direction only.
- `Behavior drift in activation logic`
  - Prefer no change; if extraction happens, keep it verbatim.
- `Workflow breakage from command changes`
  - Keep existing command names and behavior stable.
- `Over-scoping into nixGL internals`
  - Treat `nixgl-apps.nix` and `nixgl-noimpure.nix` as stable backends.

## Verification Steps

- `nix eval .#homeConfigurations.mingshi.activationPackage.drvPath`
- `nix build .#homeConfigurations.mingshi.activationPackage`
- Verify aliases still render from `home.file` in the evaluated config.
- Verify desktop entries still build from the evaluated config.
- Optional manual `home-manager switch --flake .#mingshi --impure`
- Optional manual spot checks for desktop symlinks and Plasma log behavior.

## Review Verdict

`PASS_WITH_EDITS` after tightening the internal namespace design, narrowing activation changes, and deferring Plasma/systemd churn.

## Approved Scope

- Extract runtime/nixGL orchestration from `home.nix` into `modules/nixgl-runtime.nix`.
- Convert `profiles/gui.nix` and `profiles/packages.nix` to plain imports.
- Make `modules/packages.nix` and `modules/desktop-entries.nix` read the internal runtime namespace.
- Move `hms`/`hmu`/`hmr` alias generation and NVIDIA metadata refresh out of `home.nix` into `modules/home-manager-commands.nix`.
- Leave `modules/plasma.nix`, `nixgl-apps.nix`, `nixgl-noimpure.nix`, and `modules/systemd-services.nix` behavior unchanged.
