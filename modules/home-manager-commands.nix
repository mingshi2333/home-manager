{ config, pkgs, ... }:

let
  hmSwitchCmd = "nix run .#home-manager -- switch --flake .";
  hmRollbackCmd = "nix run .#home-manager -- switch --rollback --flake .";
  commandScripts = {
    ".local/bin/hms" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        cd ~/.config/home-manager
        export NIX_SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
        export SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
        locked_rev="$(nix flake metadata --json . | ${pkgs.jq}/bin/jq -r '.locks.nodes."codex-desktop-linux".locked.rev // empty')"
        if ! remote_rev="$(nix flake metadata --json github:ilysenko/codex-desktop-linux | ${pkgs.jq}/bin/jq -r '.revision // .locked.rev // empty')"; then
          echo "[hms] unable to query remote codex-desktop-linux revision" >&2
          exit 1
        fi

        if [ -z "$remote_rev" ]; then
          echo "[hms] unable to resolve remote codex-desktop-linux revision" >&2
          exit 1
        fi

        if [ "$locked_rev" != "$remote_rev" ]; then
          echo "[hms] updating codex-desktop-linux: ''${locked_rev:-missing} -> $remote_rev"
          nix flake update codex-desktop-linux
        else
          echo "[hms] codex-desktop-linux already latest: $locked_rev"
        fi
        exec ${refreshScript}
      '';
      executable = true;
    };
    ".local/bin/hmu" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        cd ~/.config/home-manager
        export NIX_SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
        export SSL_CERT_FILE=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
        nix flake update
        exec ${refreshScript}
      '';
      executable = true;
    };
    ".local/bin/hmr" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        cd ~/.config/home-manager
        exec ${pkgs.runtimeShell} -lc '${hmRollbackCmd}'
      '';
      executable = true;
    };
    ".local/bin/hmgc" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        cd ~/.config/home-manager
        exec ${hmGcCmd}
      '';
      executable = true;
    };
  };
  hmGcCmd = pkgs.writeShellScript "hmgc-cleanup" ''
    set -euo pipefail

    profile_path="${config.xdg.stateHome}/nix/profiles/profile"
    home_manager_path="${config.xdg.stateHome}/nix/profiles/home-manager"

    if [ -e "$profile_path" ]; then
      ${pkgs.nix}/bin/nix-env --profile "$profile_path" --delete-generations old
    fi

    if [ -e "$home_manager_path" ]; then
      ${config.programs.home-manager.package}/bin/home-manager expire-generations "-3 days"
    fi

    ${pkgs.nix}/bin/nix-collect-garbage
    ${pkgs.nix}/bin/nix-store --optimise
  '';
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
  home.file =
    config.local.nixgl.binScripts
    // commandScripts
    // {
      ".zsh_aliases".text =
        let
          escapeAliasValue = v: builtins.replaceStrings [ "'" ] [ "'\\''" ] v;
          allAliases = config.local.nixgl.shellAliases // {
            hms = "~/.local/bin/hms";
            hmu = "~/.local/bin/hmu";
            hmr = "~/.local/bin/hmr";
            hmgc = "~/.local/bin/hmgc";
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
