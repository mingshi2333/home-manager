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
  defaultWorkingDirectory = "${
    config.xdg.userDirs.download or "${config.home.homeDirectory}/Downloads"
  }/nix";
  xdgDataDirs = "${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share";
  mkDesktopItemPackage =
    desktopId: entry:
    pkgs.makeDesktopItem {
      name = desktopId;
      desktopName = entry.name;
      genericName = entry.genericName or null;
      noDisplay = entry.noDisplay or null;
      comment = entry.comment or null;
      icon = entry.icon or null;
      type = entry.type or "Application";
      exec = entry.exec or null;
      terminal = entry.terminal or false;
      actions = entry.actions or { };
      mimeTypes = entry.mimeType or [ ];
      categories = entry.categories or [ ];
      startupNotify = entry.startupNotify or null;
      prefersNonDefaultGPU = entry.prefersNonDefaultGPU or null;
      extraConfig = entry.settings or { };
    };
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

  home.packages = map lib.hiPrio (
    lib.mapAttrsToList mkDesktopItemPackage config.local.nixgl.desktopEntries
  );

  home.activation.refreshDesktopDatabase = config.lib.dag.entryAfter [ "reloadSystemd" ] ''
    $DRY_RUN_CMD mkdir -p "${defaultWorkingDirectory}"
    $DRY_RUN_CMD mkdir -p $HOME/.local/share/applications

    for app in ${pkgs.lib.concatStringsSep " " config.local.nixgl.dedupApps}; do
      for desktop in $HOME/.local/share/applications/$app*.desktop; do
        # Keep broken symlinks in scope too ([ -e ] follows the link).
        [ -e "$desktop" ] || [ -L "$desktop" ] || continue
        if [ -L "$desktop" ]; then
          # Compare the RAW link target. $HOME/.nix-profile is itself a symlink,
          # so `readlink -f` would resolve it to the /nix/store profile path and
          # the $HOME/.nix-profile prefix below would never match.
          case "$(readlink "$desktop")" in
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
        # Prune orphaned symlinks into the HM profile (app removed/renamed).
        # Must include BROKEN symlinks: [ -e ] is false once the target is gone,
        # so guard on [ -L ] and skip only links whose target still exists.
        [ -L "$desktop" ] || continue
        [ -e "$desktop" ] && continue
        case "$(readlink "$desktop")" in
          $HOME/.nix-profile/share/applications/*) $DRY_RUN_CMD rm -f "$desktop" ;;
        esac
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
              target=$(readlink "$local_link")
              case "$target" in
                $HOME/.nix-profile/share/applications/*) $DRY_RUN_CMD rm -f "$local_link" ;;
              esac
            fi
            $DRY_RUN_CMD ln -sf "$desktop" "$local_link"
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
