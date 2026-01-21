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
  };
}
