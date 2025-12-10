{ config, pkgs, ... }:

{
  systemd.user.services = {
    # KDE application database maintenance service
    kbuildsycoca = {
      Unit = {
        Description = "KDE Application Database Builder";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental";
        ExecStartPost = pkgs.writeShellScript "restart-plasmashell" ''
          # Find plasmashell binary
          PLASMA_BIN=""
          for path in /usr/bin/plasmashell ${pkgs.libsForQt5.plasma-workspace or ""}/bin/plasmashell; do
            if [ -x "$path" ]; then
              PLASMA_BIN="$path"
              break
            fi
          done

          if [ -z "$PLASMA_BIN" ]; then
            echo "plasmashell binary not found"
            exit 0
          fi

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
          
          # Use setsid to completely detach plasmashell from the parent session
          # This prevents SIGHUP when the service exits
          ${pkgs.util-linux}/bin/setsid "$PLASMA_BIN" --replace </dev/null >/dev/null 2>&1 &
          
          # Verify it started successfully
          sleep 1
          if ${pkgs.procps}/bin/pgrep plasmashell >/dev/null 2>&1; then
            echo "plasmashell restarted successfully"
          else
            echo "WARNING: plasmashell failed to start"
          fi
        '';
        RemainAfterExit = false;
      };
    };

    # Plasmashell watchdog service
    plasmashell-watchdog = {
      Unit = {
        Description = "Plasma Shell Watchdog";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "plasmashell-watchdog" ''
          while true; do
            if ! pgrep -x plasmashell > /dev/null; then
              echo "Plasmashell not running, attempting restart..."
              plasmashell &
            fi
            sleep 30
          done
        '';
        Restart = "always";
        RestartSec = 10;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  systemd.user.paths = {
    # Watch for desktop file changes and trigger kbuildsycoca
    desktop-files-watcher = {
      Unit = {
        Description = "Watch for desktop file changes";
      };
      Path = {
        PathChanged = [
          "%h/.local/share/applications"
          "%h/.nix-profile/share/applications"
        ];
        Unit = "kbuildsycoca.service";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  systemd.user.timers = {
    # Periodic kbuildsycoca rebuild (every 5 minutes as fallback)
    kbuildsycoca-timer = {
      Unit = {
        Description = "Periodic KDE Application Database Rebuild";
      };
      Timer = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
        Unit = "kbuildsycoca.service";
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
