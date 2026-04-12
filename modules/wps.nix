{ config, pkgs, ... }:

let
  wpsPackage = pkgs.wpsoffice-cn;
  homeDir = config.home.homeDirectory;
  wpsWrapper = "${homeDir}/.local/bin/wps";
  wpsPdfWrapper = "${homeDir}/.local/bin/wpspdf";
in
{
  home.file = {
    ".local/bin/wps" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        export QT_QPA_PLATFORM=xcb
        exec ${wpsPackage}/bin/wps "$@"
      '';
      executable = true;
    };

    ".local/bin/wpspdf" = {
      text = ''
        #!${pkgs.runtimeShell}
        set -euo pipefail
        export QT_QPA_PLATFORM=xcb
        exec ${wpsPackage}/bin/wpspdf "$@"
      '';
      executable = true;
    };
  };

  xdg.desktopEntries = {
    "wps-office-prometheus" = {
      name = "WPS Office";
      genericName = "WPS Office";
      comment = "Use WPS Office through the managed XWayland wrapper";
      exec = "${wpsWrapper} %F";
      terminal = false;
      type = "Application";
      categories = [
        "WordProcessor"
        "Qt"
      ];
      icon = "wps-office2023-kprometheus";
      startupNotify = false;
      settings = {
        StartupWMClass = "wpsoffice";
        InitialPreference = "3";
      };
    };

    "wps-office-pdf" = {
      name = "WPS PDF";
      genericName = "Kingsoft Pdf Reader";
      comment = "Use WPS PDF through the managed XWayland wrapper";
      exec = "${wpsPdfWrapper} %F";
      terminal = false;
      type = "Application";
      categories = [
        "WordProcessor"
        "Qt"
      ];
      icon = "wps-office2023-pdfmain";
      startupNotify = false;
      mimeType = [ "application/pdf" ];
      settings = {
        StartupWMClass = "wpspdf";
        InitialPreference = "3";
      };
    };
  };
}
