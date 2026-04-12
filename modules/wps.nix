{ pkgs, ... }:

let
  wpsPackage = pkgs.wpsoffice-cn;
  wpsBin = "${wpsPackage}/bin/wps";
  wpsPdfBin = "${wpsPackage}/bin/wpspdf";
in
{
  home.file = {
    ".local/bin/wps" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        export QT_QPA_PLATFORM=xcb
        exec ${wpsBin} "$@"
      '';
      executable = true;
    };

    ".local/bin/wpspdf" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        export QT_QPA_PLATFORM=xcb
        exec ${wpsPdfBin} "$@"
      '';
      executable = true;
    };
  };
}
