{ config, pkgs, ... }:

let
  updateNvidiaMetadataCmd = ''
    if [ -r /proc/driver/nvidia/version ]; then
      current_version="$(${pkgs.gawk}/bin/awk '{for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) {print $i; exit}}' /proc/driver/nvidia/version)"
      stored_version=""
      if [ -f nvidia/version ]; then
        stored_version="$(${pkgs.gawk}/bin/awk '{for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) {print $i; exit}}' nvidia/version)"
      fi

      version_updated=0
      if [ ! -f nvidia/version ] || ! cmp -s /proc/driver/nvidia/version nvidia/version; then
        cat /proc/driver/nvidia/version > nvidia/version
        version_updated=1
        echo "[hms] nvidia/version updated"
      fi

      if [ "$version_updated" -eq 1 ] || [ ! -s nvidia/hash ] || ! ${pkgs.gnugrep}/bin/grep -Eq '^sha256-[A-Za-z0-9+/=]+$' nvidia/hash; then
        if [ -z "$current_version" ]; then
          echo "[hms] unable to parse NVIDIA version for hash update" >&2
          exit 1
        fi
        nvidia_url="https://download.nvidia.com/XFree86/Linux-x86_64/$current_version/NVIDIA-Linux-x86_64-$current_version.run"
        nvidia_hash="$(${pkgs.nix}/bin/nix hash to-sri --type sha256 "$(${pkgs.nix}/bin/nix-prefetch-url "$nvidia_url")")"
        printf '%s\n' "$nvidia_hash" > nvidia/hash
        if [ "$current_version" != "$stored_version" ]; then
          echo "[hms] nvidia/hash updated for $current_version"
        else
          echo "[hms] nvidia/hash refreshed"
        fi
      fi
    fi
  '';
in
{
  home.file = config.local.nixgl.binScripts // {
    ".zsh_aliases".text =
      let
        escapeAliasValue = v: builtins.replaceStrings [ "'" ] [ "'\\''" ] v;
        allAliases = config.local.nixgl.shellAliases // {
          hms = "cd ~/.config/home-manager && { ${updateNvidiaMetadataCmd}; home-manager switch --impure; }";
          hmu = "cd ~/.config/home-manager && { ${updateNvidiaMetadataCmd}; nix flake update && home-manager switch --impure; }";
          hmr = "cd ~/.config/home-manager && home-manager switch --impure --rollback";
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
