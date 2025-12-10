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
              ${pkgs.libsForQt5.plasma-workspace}/bin/plasmashell &
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
