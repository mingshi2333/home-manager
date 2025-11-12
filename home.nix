{ config, pkgs, ... }:

let
  nixglPackages = pkgs.callPackage ./nixgl-noimpure.nix { };
  nixGLPackage = nixglPackages.auto.nixGLDefault;
  nixGLBin = "${nixGLPackage}/bin/nixGL";

  nixglApps = import ./nixgl-apps.nix { inherit config pkgs nixGLBin; };

  fcitxEnv = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
  };
in
{
  home.username = "mingshi";
  home.homeDirectory = "/home/mingshi";

  nixpkgs.config.allowUnfree = true;

  home.packages = nixglApps.packages ++ (with pkgs; [
    onedrivegui
    kdePackages.kate
    nix
    nix-du
    pdfstudioviewer
    qtscrcpy
    xdg-utils
    vulkan-tools
    zoom-us
    nixGLPackage
    nsc
  ]);

  home.sessionVariables = fcitxEnv // {
    EDITOR = "vim";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    GTK_USE_PORTAL = "1";
    GTK_IM_MODULE_FILE = "${config.home.homeDirectory}/.nix-profile/etc/gtk-3.0/immodules.cache";
    GTK_PATH = "${config.home.homeDirectory}/.nix-profile/lib/gtk-3.0";
    XDG_DATA_DIRS = "${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  xdg.configFile."environment.d/99-fcitx5.conf".text = pkgs.lib.concatStringsSep "\n"
    (pkgs.lib.mapAttrsToList (k: v: "${k}=${v}") fcitxEnv);

  xdg.configFile."environment.d/20-electron-wayland.conf".text = ''
    ELECTRON_OZONE_PLATFORM_HINT=wayland
    NIXOS_OZONE_WL=1
  '';

  xdg.configFile."environment.d/10-xdg-data-dirs.conf".text = ''
    XDG_DATA_DIRS=${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share
  '';

  xdg.configFile."environment.d/30-xdg-portal.conf".text = ''
    NIXOS_XDG_OPEN_USE_PORTAL=1
    GTK_USE_PORTAL=1
  '';

  programs.zsh.initExtra = ''
    ${pkgs.lib.concatStringsSep "\n    " (pkgs.lib.mapAttrsToList (k: v: "export ${k}=${v}") fcitxEnv)}
    export ELECTRON_OZONE_PLATFORM_HINT=wayland
    export NIXOS_OZONE_WL=1
  '';

  programs.zsh.shellAliases = nixglApps.shellAliases // {
    hms = "cd ~/.config/home-manager && home-manager switch";
    hmu = "cd ~/.config/home-manager && nix flake update && home-manager switch";
    hmr = "cd ~/.config/home-manager && home-manager switch --rollback";
  };

  home.file = nixglApps.binScripts;

  xdg.enable = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = nixglApps.mimeAssociations // {
      "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
      "application/pdf" = [ "chromium-browser.desktop" ];
    };
  };

  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;

  home.activation.refreshDesktopDatabase = config.lib.dag.entryAfter ["reloadSystemd"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.local/share/applications

    if [ -d "$HOME/.nix-profile/share/applications" ]; then
      $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -av --ignore-existing \
        "$HOME/.nix-profile/share/applications/"*.desktop \
        "$HOME/.local/share/applications/" 2>/dev/null || true
    fi

    if [ -x "${pkgs.desktop-file-utils}/bin/update-desktop-database" ]; then
      $DRY_RUN_CMD ${pkgs.desktop-file-utils}/bin/update-desktop-database \
        "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    if command -v kbuildsycoca6 &> /dev/null; then
      $DRY_RUN_CMD kbuildsycoca6 2>/dev/null || true
    elif command -v kbuildsycoca5 &> /dev/null; then
      $DRY_RUN_CMD kbuildsycoca5 2>/dev/null || true
    fi
  '';

  programs.home-manager.enable = true;
  home.stateVersion = "23.11";
}
