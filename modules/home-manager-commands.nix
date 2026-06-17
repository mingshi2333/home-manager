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
        flake_metadata="$(nix flake metadata --json .)"

        update_input_if_changed() {
          input_name="$1"
          input_url="$2"
          locked_rev="$(printf '%s\n' "$flake_metadata" | ${pkgs.jq}/bin/jq -r --arg input "$input_name" '.locks.nodes[$input].locked.rev // empty')"
          if ! remote_rev="$(nix flake metadata --json "$input_url" | ${pkgs.jq}/bin/jq -r '.revision // .locked.rev // empty')"; then
            echo "[hms] unable to query $input_name revision" >&2
            exit 1
          fi

          if [ -z "$remote_rev" ]; then
            echo "[hms] unable to resolve $input_name revision" >&2
            exit 1
          fi

          if [ "$locked_rev" != "$remote_rev" ]; then
            echo "[hms] updating $input_name: ''${locked_rev:-missing} -> $remote_rev"
            nix flake update "$input_name"
          else
            echo "[hms] $input_name already latest: $locked_rev"
          fi
        }

        update_input_if_changed codex-desktop-linux github:ilysenko/codex-desktop-linux
        update_input_if_changed claude-desktop-debian github:aaddrick/claude-desktop-debian
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
    ".local/bin/hmb" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        repo_dir="$HOME/.config/home-manager"
        desktop_dir=""

        if command -v xdg-user-dir >/dev/null 2>&1; then
          desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
        fi

        if [ -z "$desktop_dir" ] || [ "$desktop_dir" = "$HOME" ]; then
          desktop_dir="$HOME/Desktop"
        fi

        build_dir="$desktop_dir/home-manager/build/manual"
        mkdir -p "$build_dir"
        rm -f "$build_dir/result"
        cd "$build_dir"
        exec nix run "$repo_dir#home-manager" -- build --flake "$repo_dir"
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
        "@curl_bin@"
        "@jq_bin@"
        "@nix_bin@"
        "@nix_instantiate_bin@"
        "@nix_prefetch_url_bin@"
      ]
      [
        "${pkgs.gnugrep}/bin/grep"
        "${pkgs.gawk}/bin/awk"
        "${pkgs.curl}/bin/curl"
        "${pkgs.jq}/bin/jq"
        "${pkgs.nix}/bin/nix"
        "${pkgs.nix}/bin/nix-instantiate"
        "${pkgs.nix}/bin/nix-prefetch-url"
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
            hmb = "~/.local/bin/hmb";
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
