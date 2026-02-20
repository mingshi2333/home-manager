{ config, pkgs, ... }:

let
  # nixGL configuration - use local nixgl with explicit version file
  nvidiaVersionFile = ./nvidia/version;
  nvidiaHashFile = ./nvidia/hash;
  nvidiaVersion =
    let
      versionMatch = builtins.match ".*  ([0-9]+\\.[0-9]+\\.[0-9]+)  .*" (
        builtins.readFile nvidiaVersionFile
      );
    in
    if versionMatch != null then
      builtins.head versionMatch
    else
      throw "Unable to parse NVIDIA version from nvidia/version";
  # Read runfile hash from tracked file; updated by hms when version changes.
  nvidiaHash =
    let
      hash = builtins.replaceStrings [ "\n" "\r" ] [ "" "" ] (builtins.readFile nvidiaHashFile);
    in
    if builtins.match "sha256-[A-Za-z0-9+/=]+" hash != null then
      hash
    else
      throw "Invalid NVIDIA hash in nvidia/hash";
  nixglPackages = pkgs.callPackage ./nixgl-noimpure.nix {
    inherit
      nvidiaVersionFile
      nvidiaVersion
      nvidiaHash
      ;
  };
  nixGLPackage = nixglPackages.nixGLNvidia;
  nixGLBin = "${nixGLPackage}/bin/nixGLNvidia-${nvidiaVersion}";

  # Enabled nixGL applications
  enabledNixglApps = [
    "podman-desktop"
    "zotero"
    "lenovo-legion"
    "gearlever"
    "ayugram"
    "qq"
    "cozy"
    "element"
    "tracy"
    "wechat"
    # "readest"
  ];

  # Fcitx environment variables (shared across modules)
  fcitxEnv = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
  };

  # Import nixGL apps configuration
  nixglApps = import ./nixgl-apps.nix {
    inherit
      config
      pkgs
      nixGLBin
      fcitxEnv
      ;
    enabledApps = enabledNixglApps;
  };

  # Applications to deduplicate in desktop entries
  dedupApps = (builtins.attrNames nixglApps.desktopEntries) ++ [
    "telegram-desktop"
    "org.telegram.desktop"
    "telegram"
  ];
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
  # Basic user configuration
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Import modular configurations
  imports = [
    ./profiles/base.nix
    (import ./profiles/gui.nix {
      inherit
        config
        pkgs
        nixglApps
        dedupApps
        ;
    })
    (import ./profiles/packages.nix {
      inherit
        config
        pkgs
        nixglApps
        nixGLPackage
        ;
    })
  ];

  # Shell aliases and nixGL wrapper scripts
  home.file = nixglApps.binScripts // {
    ".zsh_aliases".text =
      let
        allAliases = nixglApps.shellAliases // {
          hms = "cd ~/.config/home-manager && { ${updateNvidiaMetadataCmd}; home-manager switch --impure; }";
          hmu = "cd ~/.config/home-manager && { ${updateNvidiaMetadataCmd}; nix flake update && home-manager switch --impure; }";
          hmr = "cd ~/.config/home-manager && home-manager switch --impure --rollback";
        };
      in
      pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (k: v: "alias ${k}='${v}'") allAliases);

    ".config/home-manager/zsh-extra.sh".text = ''
      # Prefer system binaries; keep Nix paths at the end
      if [ -n "$ZSH_VERSION" ]; then
        path=(/usr/local/bin /usr/bin /usr/local/sbin /usr/sbin ''${path})
        path=(''${path:#''${HOME}/.nix-profile/bin} ''${path:#/nix/var/nix/profiles/default/bin})
        path+=("''${HOME}/.nix-profile/bin" /nix/var/nix/profiles/default/bin)
        typeset -U path
        export PATH
      fi
    '';
  };

  # Enable home-manager
  programs.home-manager.enable = true;
}
