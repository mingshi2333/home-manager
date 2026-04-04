{ config, pkgs, ... }:

let
  hmSwitchCmd = "nix run .#home-manager -- switch --flake .";
  hmRollbackCmd = "nix run .#home-manager -- switch --rollback --flake .";
  refreshScript = pkgs.writeShellScript "hms-refresh" (
    builtins.replaceStrings
      [
        "@grep_bin@"
        "@awk_bin@"
        "@sha256sum_bin@"
        "@runtime_shell@"
      ]
      [
        "${pkgs.gnugrep}/bin/grep"
        "${pkgs.gawk}/bin/awk"
        "${pkgs.coreutils}/bin/sha256sum"
        "${pkgs.runtimeShell}"
      ]
      (builtins.readFile ../ops/hms-refresh.sh)
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

    ".config/home-manager/zsh-extra.sh".text = ''
      if [ -n "$ZSH_VERSION" ]; then
        path=(/usr/local/bin /usr/bin /usr/local/sbin /usr/sbin ''${HOME}/.cache/.bun/bin ''${path})
        path=(''${path:#''${HOME}/.nix-profile/bin} ''${path:#/nix/var/nix/profiles/default/bin})
        path+=("''${HOME}/.nix-profile/bin" /nix/var/nix/profiles/default/bin)
        typeset -U path
        export PATH
      fi
    '';
  };
}
