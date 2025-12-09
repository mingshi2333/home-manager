{ config, pkgs, ... }:

let
  # Lenovo Legion CLI wrapper with pkexec
  legionCliPkexec = pkgs.writeShellScript "lenovo-legion-pkexec" ''
    export SHELL=/bin/bash
    exec ${pkgs.util-linux}/bin/pkexec ${pkgs.lenovo-legion}/bin/legion_cli "$@"
  '';

  # Lenovo Legion GUI wrapper with pkexec
  legionGuiPkexec = pkgs.writeShellScript "lenovo-legion-gui-pkexec" ''
    export SHELL=/bin/bash
    exec ${pkgs.util-linux}/bin/pkexec ${pkgs.lenovo-legion}/bin/legion_gui "$@"
  '';
in
{
  home.file = {
    ".local/bin/lenovo-legion-pkexec" = {
      source = legionCliPkexec;
      executable = true;
    };

    ".local/bin/lenovo-legion-gui-pkexec" = {
      source = legionGuiPkexec;
      executable = true;
    };

    ".local/share/applications/lenovo-legion-gui-pkexec.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Lenovo Legion Control (pkexec)
        Exec=${config.home.homeDirectory}/.local/bin/lenovo-legion-gui-pkexec
        Icon=computer
        Categories=Utility;System;
        Terminal=false
      '';
    };
  };

  # Shell alias for convenience
  home.shellAliases = {
    legionpk = "lenovo-legion-pkexec";
  };
}
