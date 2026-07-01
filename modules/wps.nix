{
  config,
  lib,
  pkgs,
  ...
}:

let
  wpsPackage = pkgs.wpsoffice-cn;
  homeDir = config.home.homeDirectory;
  defaultWorkingDirectory = "${config.xdg.userDirs.download or "${homeDir}/Downloads"}/nix";

  mkWrapper = binary: ''
    #!${pkgs.runtimeShell}
    set -euo pipefail
    export QT_QPA_PLATFORM=xcb
    exec ${wpsPackage}/bin/${binary} "$@"
  '';

  wrapperPath = binary: "${homeDir}/.local/bin/${binary}";

  mkEntry =
    {
      name,
      genericName,
      comment,
      exec,
      categories,
      icon,
      startupWMClass,
      mimeType ? null,
    }:
    {
      inherit
        name
        genericName
        comment
        exec
        icon
        ;
      terminal = false;
      type = "Application";
      categories = [
        "Office"
      ]
      ++ categories
      ++ [
        "Qt"
      ];
      startupNotify = false;
      settings = {
        Path = defaultWorkingDirectory;
        StartupWMClass = startupWMClass;
        InitialPreference = "3";
        X-DBUS-ServiceName = "";
        X-DBUS-StartupType = "";
        X-KDE-SubstituteUID = "false";
        X-KDE-Username = "";
      };
    }
    // pkgs.lib.optionalAttrs (mimeType != null) { inherit mimeType; };

  mkDesktopItemPackage =
    desktopId: entry:
    pkgs.makeDesktopItem {
      name = desktopId;
      desktopName = entry.name;
      genericName = entry.genericName or null;
      comment = entry.comment or null;
      icon = entry.icon or null;
      type = entry.type or "Application";
      exec = entry.exec or null;
      terminal = entry.terminal or false;
      mimeTypes = entry.mimeType or [ ];
      categories = entry.categories or [ ];
      startupNotify = entry.startupNotify or null;
      extraConfig = entry.settings or { };
    };

  wpsDesktopEntries = {
    "wps-office-prometheus" = mkEntry {
      name = "WPS Office";
      genericName = "WPS Office";
      comment = "Use WPS Office through the managed XWayland wrapper";
      exec = "${wrapperPath "wps"} %F";
      categories = [ "WordProcessor" ];
      icon = "wps-office2023-kprometheus";
      startupWMClass = "wpsoffice";
    };

    "wps-office-wps" = mkEntry {
      name = "WPS Writer";
      genericName = "WPS Writer";
      comment = "Use WPS Writer through the managed XWayland wrapper";
      exec = "${wrapperPath "wps"} %U";
      categories = [ "WordProcessor" ];
      icon = "wps-office2023-wpsmain";
      startupWMClass = "wps";
      mimeType = [
        "application/wps-office.wps"
        "application/wps-office.wpt"
        "application/wps-office.wpso"
        "application/wps-office.wpss"
        "application/wps-office.doc"
        "application/wps-office.dot"
        "application/vnd.ms-word"
        "application/msword"
        "application/x-msword"
        "application/msword-template"
        "application/wps-office.docx"
        "application/wps-office.dotx"
        "application/rtf"
        "application/vnd.ms-word.document.macroEnabled.12"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "x-scheme-handler/ksoqing"
        "x-scheme-handler/ksowps"
        "x-scheme-handler/ksowpp"
        "x-scheme-handler/ksoet"
        "x-scheme-handler/ksowpscloudsvr"
        "x-scheme-handler/ksowebstartupwps"
        "x-scheme-handler/ksowebstartupet"
        "x-scheme-handler/ksowebstartupwpp"
        "application/wps-office.uot3"
        "application/wps-office.uott3"
        "x-scheme-handler/ksodoccenter"
        "application/wps-office.msg"
        "application/wps-office.eml"
      ];
    };

    "wps-office-et" = mkEntry {
      name = "WPS Spreadsheets";
      genericName = "WPS Spreadsheets";
      comment = "Use WPS Spreadsheets through the managed XWayland wrapper";
      exec = "${wrapperPath "et"} %F";
      categories = [ "Spreadsheet" ];
      icon = "wps-office2023-etmain";
      startupWMClass = "et";
      mimeType = [
        "application/wps-office.et"
        "application/wps-office.ett"
        "application/wps-office.ets"
        "application/wps-office.eto"
        "application/wps-office.xls"
        "application/wps-office.xlt"
        "application/vnd.ms-excel"
        "application/msexcel"
        "application/x-msexcel"
        "application/wps-office.xlsx"
        "application/wps-office.xltx"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "application/wps-office.uos"
        "application/wps-office.uos3"
        "application/wps-office.uost3"
      ];
    };

    "wps-office-wpp" = mkEntry {
      name = "WPS Presentation";
      genericName = "WPS Presentation";
      comment = "Use WPS Presentation through the managed XWayland wrapper";
      exec = "${wrapperPath "wpp"} %F";
      categories = [ "Presentation" ];
      icon = "wps-office2023-wppmain";
      startupWMClass = "wpp";
      mimeType = [
        "application/wps-office.dps"
        "application/wps-office.dpt"
        "application/wps-office.dpss"
        "application/wps-office.dpso"
        "application/wps-office.ppt"
        "application/wps-office.pot"
        "application/vnd.ms-powerpoint"
        "application/vnd.mspowerpoint"
        "application/mspowerpoint"
        "application/powerpoint"
        "application/x-mspowerpoint"
        "application/wps-office.pptx"
        "application/wps-office.potx"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
        "application/wps-office.uop"
        "application/wps-office.uop3"
        "application/wps-office.uopt3"
      ];
    };

    "wps-office-pdf" = mkEntry {
      name = "WPS PDF";
      genericName = "Kingsoft Pdf Reader";
      comment = "Use WPS PDF through the managed XWayland wrapper";
      exec = "${wrapperPath "wpspdf"} %F";
      categories = [ "Viewer" ];
      icon = "wps-office2023-pdfmain";
      startupWMClass = "wpspdf";
      mimeType = [ "application/pdf" ];
    };
  };
in
{
  options.local.wps.desktopEntries = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    readOnly = true;
  };

  config = {
    local.wps.desktopEntries = wpsDesktopEntries;

    home.packages = [
      wpsPackage
    ]
    ++ map lib.hiPrio (lib.mapAttrsToList mkDesktopItemPackage wpsDesktopEntries);

    home.file = {
      ".local/bin/wps" = {
        text = mkWrapper "wps";
        executable = true;
      };

      ".local/bin/wpspdf" = {
        text = mkWrapper "wpspdf";
        executable = true;
      };

      ".local/bin/et" = {
        text = mkWrapper "et";
        executable = true;
      };

      ".local/bin/wpp" = {
        text = mkWrapper "wpp";
        executable = true;
      };
    };
  };
}
