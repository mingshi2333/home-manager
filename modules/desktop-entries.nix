{
  config,
  pkgs,
  nixglApps,
  dedupApps,
  ...
}:

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

  # Only add custom desktop entries for nixGL apps, don't override system entries
  xdg.desktopEntries = nixglApps.desktopEntries;

  # Don't force override - let system MIME associations coexist
  # xdg.configFile."mimeapps.list".force = true;
  # xdg.dataFile."applications/mimeapps.list".force = true;

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

    # Skip expensive refresh when desktop entries are unchanged
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
