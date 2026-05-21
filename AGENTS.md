# Agent Instructions

## Project Scope

This repository manages the local Home Manager and nixGL configuration for the current `/home/mingshi` Fedora KDE Wayland machine.

Keep changes scoped to the existing Nix/Home Manager structure. Prefer declarative fixes in `modules/`, `profiles/`, `hosts/`, `nixgl-apps.nix`, or `flake.nix` over ad hoc local state.

## Context Hygiene

Do not load, inline, or summarize AI-generated workflow artifacts as default GPT/Codex context. Treat these as local workflow state only, unless the user explicitly asks for them:

- `.planning/`
- `docs/superpowers/`
- `.claude/`
- `outputs/`
- `cache.db`

Keep this file concise. Do not paste generated GSD, Superpowers, research, plan, verification, or handoff documents into `AGENTS.md`.

## Working Rules

- Preserve existing user changes; inspect `git status` before editing and do not revert unrelated files.
- Follow the existing module boundaries and naming style.
- Use `rg`/`rg --files` for code search.
- Use `nixfmt` for changed Nix files.
- For library, framework, SDK, API, CLI, or cloud-service documentation, follow the global `ctx7` instruction when available.
- If the user explicitly asks for GSD and the local GSD tooling is available, use it. Do not create new planning artifacts for routine cleanup or maintenance.

## Verification

For Nix/config changes, run the narrowest relevant checks first, then broader Home Manager evaluation when needed. Common checks in this repo include:

- `bash tests/hms-aliases.sh`
- `nix build '.#homeConfigurations.mingshi.activationPackage' --no-link`
