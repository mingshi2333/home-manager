{ config, pkgs, nixglApps, dedupApps, ... }:

{
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

  # Desktop database refresh and deduplication
  home.activation.refreshDesktopDatabase = config.lib.dag.entryAfter [ "reloadSystemd" ] ''
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
}
