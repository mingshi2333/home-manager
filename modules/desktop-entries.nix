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

    # Restart plasmashell to reload the application database
    PLASMA_BIN=""
    for path in /usr/bin/plasmashell ${pkgs.libsForQt5.plasma-workspace or ""}/bin/plasmashell; do
      if [ -x "$path" ]; then
        PLASMA_BIN="$path"
        break
      fi
    done

    if [ -n "$PLASMA_BIN" ]; then
      # Reload systemd user environment to pick up new environment.d configs
      ${pkgs.systemd}/bin/systemctl --user daemon-reload || true
      
      # Import critical environment variables into systemd user session
      export PATH="${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"
      export XDG_DATA_DIRS="${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share"
      ${pkgs.systemd}/bin/systemctl --user import-environment PATH XDG_DATA_DIRS || true
      
      # Kill all plasmashell processes
      ${pkgs.procps}/bin/pkill plasmashell || true
      
      # Wait for processes to fully terminate (with timeout)
      for i in {1..10}; do
        if ! ${pkgs.procps}/bin/pgrep plasmashell >/dev/null 2>&1; then
          break
        fi
        sleep 0.2
      done
      
      # Force kill if still running
      if ${pkgs.procps}/bin/pgrep plasmashell >/dev/null 2>&1; then
        ${pkgs.procps}/bin/pkill -9 plasmashell || true
        sleep 0.5
      fi
      
      # Use systemd-run to start plasmashell with proper environment from systemd user session
      ${pkgs.systemd}/bin/systemd-run --user --scope --slice=app.slice "$PLASMA_BIN" --replace </dev/null >/dev/null 2>&1 &
      
      # Verify it started successfully
      sleep 1
      if ${pkgs.procps}/bin/pgrep plasmashell >/dev/null 2>&1; then
        echo "plasmashell restarted successfully"
      else
        echo "WARNING: plasmashell failed to start"
      fi
    fi
  '';
}
