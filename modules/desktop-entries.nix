{
  config,
  lib,
  pkgs,
  ...
}:

let
  managedDesktopFiles = map (name: "${name}.desktop") (
    builtins.attrNames config.local.nixgl.desktopEntries
  );
  managedDesktopFilesText = lib.concatStringsSep " " managedDesktopFiles;
  xdgDataDirs = "${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share";
in

{
  xdg.enable = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = config.local.nixgl.mimeAssociations // {
      "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/mailto" = [ "chromium-browser.desktop" ];
      "application/pdf" = [ "chromium-browser.desktop" ];
    };
  };

  xdg.desktopEntries = config.local.nixgl.desktopEntries;

  home.activation.refreshDesktopDatabase = config.lib.dag.entryAfter [ "reloadSystemd" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.local/share/applications

    for app in ${pkgs.lib.concatStringsSep " " config.local.nixgl.dedupApps}; do
      for desktop in $HOME/.local/share/applications/$app*.desktop; do
        [ -e "$desktop" ] || continue
        if [ -L "$desktop" ]; then
          target=$(readlink -f "$desktop")
          case "$target" in
            $HOME/.nix-profile/share/applications/*) ;;
            *) $DRY_RUN_CMD rm -f "$desktop" ;;
          esac
        else
          $DRY_RUN_CMD rm -f "$desktop"
        fi
      done
    done

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

    managed_desktop_files="${managedDesktopFilesText}"

    if [ -d "$HOME/.nix-profile/share/applications" ]; then
      for desktop in $HOME/.nix-profile/share/applications/*.desktop; do
        [ -f "$desktop" ] || continue
        name=$(basename "$desktop")
        case " $managed_desktop_files " in
          *" $name "*)
            local_link="$HOME/.local/share/applications/$name"
            if [ -L "$local_link" ]; then
              target=$(readlink -f "$local_link")
              case "$target" in
                $HOME/.nix-profile/share/applications/*) $DRY_RUN_CMD rm -f "$local_link" ;;
              esac
            fi
            continue
            ;;
        esac
        $DRY_RUN_CMD ln -sf "$desktop" "$HOME/.local/share/applications/$name"
      done
    fi

    if [ -x "${pkgs.desktop-file-utils}/bin/update-desktop-database" ]; then
      $DRY_RUN_CMD ${pkgs.desktop-file-utils}/bin/update-desktop-database \
        "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    if command -v kbuildsycoca6 &> /dev/null; then
      XDG_DATA_DIRS="${xdgDataDirs}" \
        $DRY_RUN_CMD kbuildsycoca6 2>/dev/null || true
    elif command -v kbuildsycoca5 &> /dev/null; then
      XDG_DATA_DIRS="${xdgDataDirs}" \
        $DRY_RUN_CMD kbuildsycoca5 2>/dev/null || true
    fi
  '';
}
