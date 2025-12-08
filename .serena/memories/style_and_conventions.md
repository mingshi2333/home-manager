# Style and conventions
- Nix/Home Manager based; primary modules: `home.nix` (main), `nixgl-apps.nix` (nixGL-wrapped apps), `nixgl-noimpure.nix` (nixGL wrapper package set).
- Apps enabled by editing `enabledNixglApps` in `home.nix`; app definitions live in `allApps` inside `nixgl-apps.nix` using `mkNixGLApp` and `wrapWithNixGL`.
- Environment variables and input method config centralized in `fcitxEnv` and shared across env files and wrappers.
- Desktop entry dedup/refresh handled in `home.activation.refreshDesktopDatabase`; prefers symlinks from `~/.nix-profile/share/applications` to `~/.local/share/applications` and removes non-profile duplicates for known prefixes.
- Shell aliases defined in `home.file.".zsh_aliases"` merging `nixglApps.shellAliases` with local helpers (hms/hmu/hmr, legionpk).
- Keep edits minimal and declarative; avoid introducing non-ASCII unless already present (files are UTF-8).