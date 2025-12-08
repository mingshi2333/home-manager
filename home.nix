{ config, pkgs, ... }:

let
  nixglPackages = pkgs.callPackage ./nixgl-noimpure.nix { };
  nixGLPackage = nixglPackages.auto.nixGLDefault;
  nixGLBin = "${nixGLPackage}/bin/nixGL";

  enabledNixglApps = [
    "podman-desktop"
    "zotero"
    "lenovo-legion"
    "gearlever"
    "ayugram"
  ];

  nixglApps = import ./nixgl-apps.nix {
    inherit config pkgs nixGLBin;
    enabledApps = enabledNixglApps;
  };

  fcitxEnv = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
  };

  dedupApps = (builtins.attrNames nixglApps.desktopEntries)
    ++ [ "telegram-desktop" "org.telegram.desktop" "telegram" ];
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
    qtscrcpy
    xdg-utils
    vulkan-tools
    zoom-us
    nixGLPackage
    nsc
    spotify
    pdfstudioviewer
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

  home.file = nixglApps.binScripts // {
    ".zsh_aliases".text =
      let
        allAliases = nixglApps.shellAliases // {
          hms = "cd ~/.config/home-manager && home-manager switch";
          hmu = "cd ~/.config/home-manager && nix flake update && home-manager switch";
          hmr = "cd ~/.config/home-manager && home-manager switch --rollback";
          legionpk = "lenovo-legion-pkexec";
        };
      in pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (k: v: "alias ${k}='${v}'") allAliases);

    ".local/bin/lenovo-legion-pkexec" = {
      text = ''
        #!${pkgs.bash}/bin/bash
        export SHELL=/bin/bash
        exec pkexec ${pkgs.lenovo-legion}/bin/legion_cli "$@"
      '';
      executable = true;
    };

    ".local/bin/lenovo-legion-gui-pkexec" = {
      text = ''
        #!${pkgs.bash}/bin/bash
        export SHELL=/bin/bash
        exec pkexec ${pkgs.lenovo-legion}/bin/legion_gui "$@"
      '';
      executable = true;
    };

    ".local/share/applications/lenovo-legion-gui-pkexec.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Lenovo Legion Control (pkexec)
        Exec=${config.home.homeDirectory}/.local/bin/lenovo-legion-gui-pkexec
        Icon=computer
        Categories=Utility;
        Terminal=false
      '';
    };
  };

  xdg.enable = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = nixglApps.mimeAssociations // {
      "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
      "application/pdf" = [ "chromium-browser.desktop" ];
    };
  };

  xdg.desktopEntries = nixglApps.desktopEntries;

  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;

  home.activation.restartPlasma = config.lib.dag.entryAfter ["writeBoundary"] ''
    LOG="$HOME/.cache/hm-restart-plasma.log"
    mkdir -p "$(dirname "$LOG")"
    date +"[%F %T] start restartPlasma" >> "$LOG"

    # Prefer systemd user service if present
    if systemctl --user list-units --type=service 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q plasma-plasmashell.service; then
      systemctl --user restart plasma-plasmashell.service >>"$LOG" 2>&1 || true
      date +"[%F %T] systemctl restart plasma-plasmashell.service done" >> "$LOG"
      exit 0
    fi

    PGREP=${pkgs.procps}/bin/pgrep
    if $PGREP plasmashell >/dev/null 2>&1; then
      # pick a running plasmashell binary path
      PID=$(${pkgs.procps}/bin/pgrep -n plasmashell || true)
      PLASMA_BIN=""
      if [ -n "$PID" ] && [ -e "/proc/$PID/exe" ]; then
        PLASMA_BIN="$(readlink -f /proc/$PID/exe || true)"
      fi
      if [ -z "$PLASMA_BIN" ] && [ -x /usr/bin/plasmashell ]; then
        PLASMA_BIN=/usr/bin/plasmashell
      fi

      if [ -n "$PLASMA_BIN" ]; then
        ${pkgs.procps}/bin/pkill plasmashell || true
        ("$PLASMA_BIN" --replace >>"$LOG" 2>&1 &)
        date +"[%F %T] used $PLASMA_BIN --replace" >> "$LOG"
      else
        date +"[%F %T] plasmashell binary not found for --replace" >> "$LOG"
      fi
    else
      date +"[%F %T] plasmashell not running, skip" >> "$LOG"
    fi
  '';

  home.activation.refreshDesktopDatabase = config.lib.dag.entryAfter ["reloadSystemd"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.local/share/applications

    # remove duplicates not pointing to nix-profile for selected app names
    for app in ${pkgs.lib.concatStringsSep " " dedupApps}; do
      for desktop in $HOME/.local/share/applications/$app*.desktop; do
        [ -e "$desktop" ] || continue
        if [ -L "$desktop" ]; then
          target=$(readlink -f "$desktop")
          case "$target" in
            $HOME/.nix-profile/share/applications/*) ;; # keep nix-profile entries
            *) $DRY_RUN_CMD rm -f "$desktop" ;;
          esac
        else
          $DRY_RUN_CMD rm -f "$desktop"
        fi
      done
    done

    # cleanup stale links
    if [ -d "$HOME/.local/share/applications" ]; then
      for desktop in $HOME/.local/share/applications/*.desktop; do
        [ -e "$desktop" ] || continue
        if [ -L "$desktop" ]; then
          target=$(readlink -f "$desktop")
          case "$target" in
            $HOME/.nix-profile/share/applications/*)
              if [ ! -e "$target" ]; then
                $DRY_RUN_CMD rm -f "$desktop"
              fi
              ;;
          esac
        fi
      done
    fi

    if [ -d "$HOME/.nix-profile/share/applications" ]; then
      for desktop in $HOME/.nix-profile/share/applications/*.desktop; do
        [ -f "$desktop" ] || continue
        name=$(basename "$desktop")
        $DRY_RUN_CMD ln -sf "$desktop" "$HOME/.local/share/applications/$name"
      done
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
