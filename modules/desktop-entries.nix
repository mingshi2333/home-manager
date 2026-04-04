{ config, pkgs, ... }:

let
  karing = pkgs.callPackage ../karing.nix { };
in

{
  xdg.enable = true;

  # Keep Karing desktop/autostart exposure in the desktop module rather than in
  # the package derivation or host-local refresh script.
  home.file.".config/autostart/karing.desktop".source = "${karing}/share/applications/karing.desktop";

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

    if [ -d "$HOME/.nix-profile/share/applications" ]; then
      for desktop in $HOME/.nix-profile/share/applications/*.desktop; do
        [ -f "$desktop" ] || continue
        name=$(basename "$desktop")
        $DRY_RUN_CMD ln -sf "$desktop" "$HOME/.local/share/applications/$name"
      done
    fi

    hash_file="$HOME/.cache/hm-desktop-entries.sha256"
    tmp_hash=""
    if command -v ${pkgs.coreutils}/bin/sha256sum >/dev/null 2>&1; then
      tmp_hash=$(find "$HOME/.local/share/applications" "$HOME/.nix-profile/share/applications" \
        -maxdepth 1 -type f -name "*.desktop" -print0 2>/dev/null \
        | sort -z \
        | xargs -0 ${pkgs.coreutils}/bin/sha256sum 2>/dev/null \
        | ${pkgs.coreutils}/bin/sha256sum \
        | ${pkgs.coreutils}/bin/cut -d ' ' -f 1 || true)
    fi

    if [ -n "$tmp_hash" ] && [ -f "$hash_file" ]; then
      prev_hash=$(cat "$hash_file" 2>/dev/null || true)
      if [ "$tmp_hash" = "$prev_hash" ]; then
        exit 0
      fi
    fi

    if [ -n "$tmp_hash" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.cache"
      $DRY_RUN_CMD printf "%s" "$tmp_hash" > "$hash_file"
    fi

    if [ -x "${pkgs.desktop-file-utils}/bin/update-desktop-database" ]; then
      $DRY_RUN_CMD ${pkgs.desktop-file-utils}/bin/update-desktop-database \
        "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    if command -v kbuildsycoca6 &> /dev/null; then
      XDG_DATA_DIRS="${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share" \
        $DRY_RUN_CMD kbuildsycoca6 2>/dev/null || true
    elif command -v kbuildsycoca5 &> /dev/null; then
      XDG_DATA_DIRS="${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share" \
        $DRY_RUN_CMD kbuildsycoca5 2>/dev/null || true
    fi
  '';
}
