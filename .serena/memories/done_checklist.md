# What to do when a task is completed
- Run `home-manager switch` (or alias `hms`) to apply configuration changes.
- If flake inputs changed, consider `nix flake update && home-manager switch` (alias `hmu`).
- Verify expected desktop entries/symlinks under `~/.local/share/applications` and `~/.nix-profile/share/applications` when touching nixGL apps.
- If behaviour regresses, use `home-manager switch --rollback` (alias `hmr`).
- No automated tests; manual verification (desktop entry presence, command availability) is typical.