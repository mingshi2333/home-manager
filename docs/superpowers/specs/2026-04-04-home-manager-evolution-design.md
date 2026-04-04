# Home Manager Repo Evolution Design

## Context

This repository is no longer just a small Home Manager config. It already contains:

- declarative Home Manager modules under `modules/`
- a generated application catalog and compatibility layer in `nixgl-apps.nix`
- source metadata for externally managed apps under `sources/`
- operational refresh logic in `hms-refresh.sh`
- host-specific runtime maintenance such as NVIDIA metadata refresh and karing root-helper sync

That growth is useful, but it also means the repository is starting to mix three different concerns in the same places:

1. declarative configuration
2. source/version metadata management
3. host-local operational side effects

The current system still works, but maintainability is already degrading because the boundaries between those concerns are not clean enough.

## Problem Statement

The main issue is not that any one file is "wrong". The issue is that the repository is drifting into a shape where it becomes harder to answer simple questions such as:

- Where should a new upstream app source be defined?
- Where should a host-only maintenance action live?
- When is a change declarative configuration versus imperative local orchestration?
- Which layer owns app update policy versus package wrapping versus desktop integration?

Today, those answers are spread across `flake.nix`, `karing.nix`, `sources/*.nix`, `modules/home-manager-commands.nix`, `hms-refresh.sh`, and `nixgl-apps.nix`.

That shape causes three concrete maintenance problems:

### 1. Command module drift

`modules/home-manager-commands.nix` started as alias generation, but it now exposes a wrapper script that effectively acts as an operations runner. That is workable, but it means the command module is no longer just a UI surface. It is coupled to refresh logic, local state synchronization, and host-specific repair flows.

### 2. Source/package coupling

The repository already has a good idea in practice: app sources are stored separately from package definitions. But the ownership is still not fully regularized. `flake.nix` directly overrides `qq` using `sources/qq.nix`, while `karing.nix` reads `sources/karing.nix` itself, and `hms-refresh.sh` mutates those files. The direction is correct, but the shape is not fully normalized.

### 3. Declarative vs. imperative confusion

The repo is explicitly Home Manager-based, but it also contains host-local orchestration:

- NVIDIA metadata refresh from `/proc`
- source refresh from remote vendor endpoints
- system helper synchronization for `karing`

Those are legitimate needs on this host, but they should be treated as an operations layer, not mixed conceptually into the declarative layer.

## Design Goals

Any evolution of this repository should optimize for maintainability first.

The target qualities are:

1. A contributor can tell where a change belongs without reading half the repo.
2. App source metadata follows one obvious pattern.
3. Home Manager modules remain declarative integration points, not ad hoc orchestration containers.
4. Host-local imperative steps remain possible, but are clearly isolated.
5. Brownfield compatibility fixes like `qq` and `karing` do not pollute generic module boundaries more than necessary.

## Recommended Paradigm

The recommended architecture is a three-layer model:

### Layer 1: Config Layer

This layer contains Home Manager modules and package wiring.

Examples:

- `home.nix`
- `profiles/*.nix`
- `modules/*.nix`
- `nixgl-apps.nix`

Rules for this layer:

- It should describe desired state.
- It may consume generated metadata.
- It should not own complex imperative refresh logic.
- It should remain the place where features are integrated into the Home Manager graph.

### Layer 2: Source Layer

This layer contains upstream source/version/channel metadata.

Examples:

- `sources/qq.nix`
- `sources/karing.nix`

Rules for this layer:

- One app/source file per externally managed app.
- Source files store version/channel/source facts, not package-building logic.
- Package definitions read from source files, but do not decide upstream refresh policy themselves.
- If an app has both a stable downloadable version and a newer update-channel version, that distinction belongs in source metadata, not hidden inside package logic.

### Layer 3: Ops Layer

This layer contains host-local refresh and synchronization actions.

Current example:

- `hms-refresh.sh`

Rules for this layer:

- It owns imperative side effects.
- It may read remote endpoints and rewrite source files.
- It may synchronize host-local helpers or metadata.
- It should be invoked by user commands such as `hms`, but not conceptually treated as part of module design.

## Why This Is The Right Direction

This repo is already too dynamic to pretend it is purely declarative, and forcing it into a fully pure model would make the daily workflow worse.

At the same time, continuing to pile host-local operational logic into modules and package definitions will make future maintenance harder.

The three-layer model keeps the practical workflow that this host needs, while restoring clarity about where responsibilities belong.

In other words:

- do not try to make the repo more pure than the actual operational problem allows
- do make the impurity intentional, explicit, and contained

## Recommended Structural Conventions

### Sources

Keep all externally refreshed app metadata in `sources/`.

Recommended pattern:

- `sources/qq.nix`
- `sources/karing.nix`
- future apps follow the same rule

Each file should ideally answer:

- what version is currently installable
- what update channel says is latest
- what source kind is used (`fetchurl`, local path, etc.)
- what exact artifact is trusted right now

### Packages

Package definitions should read source metadata but remain focused on packaging.

Example expectations:

- `karing.nix` should define how to unpack and wrap karing
- it should not also decide how upstream release discovery works

### Commands

Keep `modules/home-manager-commands.nix` as the user-facing exposure point, but avoid putting long imperative logic directly inside it.

Preferred pattern:

- `modules/home-manager-commands.nix` exposes commands
- a dedicated script in the repo implements the operational workflow

This direction is already partially established with `hms-refresh.sh` and should be preserved.

### Desktop/Runtime Integration

Compatibility wrappers and desktop integration should remain separate from source refresh.

Example expectations:

- `nixgl-apps.nix` owns app launch/wrapper behavior
- `modules/desktop-entries.nix` owns desktop exposure
- source update logic should not drift back into either file

## Known Current Weak Spots

These are the most important issues to watch if no further cleanup is done:

### 1. `hms-refresh.sh` is becoming the real operations brain

That is not inherently bad, but if it keeps absorbing more app-specific quirks, it will become another monolith.

Mitigation:

- keep it as an ops-layer script
- prefer app-local helper functions or future split files if it grows further

### 2. `flake.nix` still contains app-specific override knowledge

The `qq` override is understandable, but over time this can make the flake entrypoint too aware of individual app behavior.

Mitigation:

- tolerate this while the count is small
- if more external-source apps appear, consider moving repeated override patterns into a focused helper file

### 3. `karing` still mixes package wrapping and privilege-path workarounds

This is currently acceptable because the behavior is highly app-specific, but it is a warning sign that some apps may need their own focused package wrappers rather than being treated as normal packages.

Mitigation:

- keep `karing.nix` isolated
- do not let its privilege-repair logic leak into generic modules

## Advanced Paradigm Recommendation

If the question is "what is the most advanced paradigm that still fits this repo?", the answer is not "pure flake minimalism".

The best-fit advanced paradigm here is:

**declarative integration plus explicit operational sidecars**

That means:

- declarative config remains first-class
- mutable vendor/update state is modeled explicitly
- host-local repair flows are treated as operations sidecars, not hidden implementation details

This is more mature than pretending the repo is purely static when the workload is not.

## Non-Goals

This design does not recommend:

- rewriting the repo into a generic multi-host framework right now
- forcing all dynamic behavior out of `hms`
- introducing a heavy framework or custom Nix library layer before the current boundaries are stabilized

## Minimal Evolution Plan

The minimal path forward is:

1. Keep using `sources/` as the only home for app source metadata.
2. Keep package-building logic in app-specific package files.
3. Keep command exposure in `modules/home-manager-commands.nix` but route imperative behavior through repo scripts.
4. Keep host-only repair logic separate from generic Home Manager integration.
5. Only introduce a more formal source registry helper if more external-source apps are added.

## Decision

The repository should evolve toward:

- **modules as declarative integration**
- **sources as authoritative upstream metadata**
- **scripts as operational refresh/sync layer**

This is the most maintainable direction for the current brownfield state of the repo, and the best balance between modern Nix structure and the practical realities of Fedora KDE Wayland desktop repair work.
