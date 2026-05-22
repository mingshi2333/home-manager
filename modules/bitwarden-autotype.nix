{
  config,
  pkgs,
  ...
}:

let
  rofiRbwConfig = ''
    selector=fuzzel
    clipboarder=wl-copy
    typer=ydotool
    typing-start-delay=500
    typing-key-delay=20
    clear-after=20
  '';
in

{
  home.packages = with pkgs; [
    rbw
    rofi-rbw
    fuzzel
    wl-clipboard
    ydotool
    pinentry-qt
  ];

  xdg.configFile."rofi-rbw.rc".text = rofiRbwConfig;
  xdg.configFile."rbw/config.json" = {
    source = ../config/rbw/config.json;
    force = true;
  };

  systemd.user.services.ydotool = {
    Unit = {
      Description = "ydotoold input automation daemon";
      Documentation = [ "man:ydotoold(8)" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
      Restart = "always";
      KillMode = "process";
      TimeoutSec = 180;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
