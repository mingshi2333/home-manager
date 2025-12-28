{ config, pkgs, ... }:

let
  # nixGL configuration - use local nixgl with explicit version file
  nvidiaVersionFile = ./nvidia/version;
  nvidiaVersion =
    let
      versionMatch =
        builtins.match ".*  ([0-9]+\\.[0-9]+\\.[0-9]+)  .*" (builtins.readFile nvidiaVersionFile);
    in
      if versionMatch != null then
        builtins.head versionMatch
      else
        throw "Unable to parse NVIDIA version from nvidia/version";
  nixglPackages = pkgs.callPackage ./nixgl-noimpure.nix {
    inherit nvidiaVersionFile;
  };
  nixGLPackage = nixglPackages.auto.nixGLNvidia;
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
  updateNvidiaVersionCmd = pkgs.lib.concatStringsSep " " [
    "if [ -r /proc/driver/nvidia/version ]; then"
    "if [ ! -f nvidia/version ] || ! cmp -s /proc/driver/nvidia/version nvidia/version; then"
    "cat /proc/driver/nvidia/version > nvidia/version;"
    "echo \"[hms] nvidia/version updated\";"
    "fi; fi"
  ];
in
{
  # Basic user configuration
  home.username = "mingshi";
  home.homeDirectory = "/home/mingshi";
  home.stateVersion = "23.11";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Import modular configurations
  imports = [
    ./modules/fcitx.nix
    ./modules/environment.nix
    ./modules/plasma.nix
    ./modules/lenovo-legion.nix
    (import ./modules/packages.nix {
      inherit
        config
        pkgs
        nixglApps
        nixGLPackage
        ;
    })
    (import ./modules/desktop-entries.nix {
      inherit
        config
        pkgs
        nixglApps
        dedupApps
        ;
    })
  ];

  # Shell aliases and nixGL wrapper scripts
  home.file = nixglApps.binScripts // {
    ".zsh_aliases".text =
      let
        allAliases = nixglApps.shellAliases // {
          hms = "cd ~/.config/home-manager && { ${updateNvidiaVersionCmd}; home-manager switch --impure; }";
          hmu = "cd ~/.config/home-manager && { ${updateNvidiaVersionCmd}; nix flake update && home-manager switch --impure; }";
          hmr = "cd ~/.config/home-manager && home-manager switch --impure --rollback";
        };
      in
      pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (k: v: "alias ${k}='${v}'") allAliases);
  };

  # Enable home-manager
  programs.home-manager.enable = true;
}
