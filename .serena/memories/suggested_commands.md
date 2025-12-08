# Suggested commands for this project
- `hms`: `cd ~/.config/home-manager && home-manager switch` (apply current home configuration)
- `hmu`: `cd ~/.config/home-manager && nix flake update && home-manager switch` (update flake inputs then apply)
- `hmr`: `cd ~/.config/home-manager && home-manager switch --rollback` (roll back to previous generation)
- Inspect desktop entries when debugging menus: `ls ~/.local/share/applications | grep <name>` and `readlink -f ~/.local/share/applications/<name>.desktop`