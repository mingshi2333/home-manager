{ config, pkgs, nixGLBin, enabledApps ? null, ... }:

let
  fcitxEnv = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  wrapWithNixGL = { pkg, name, binary ? null, platform ? "xcb", extraFlags ? [], extraEnv ? {}, aliases ? [], mimeTypes ? [], execArgs ? "", dbusService ? null }:
    let
      bin = if binary != null then binary else (pkg.meta.mainProgram or name);
      isWayland = platform == "wayland";
      platformEnv = if isWayland
        then { ELECTRON_OZONE_PLATFORM_HINT = "wayland"; }
        else { QT_QPA_PLATFORM = "xcb"; };
      waylandFlags = if isWayland
        then [ "--ozone-platform-hint=wayland" "--enable-wayland-ime" ]
        else [];
      allFlags = waylandFlags ++ extraFlags;
      allEnv = fcitxEnv // platformEnv // extraEnv;
    in pkgs.runCommand "${name}-nixgl" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir -p $out/bin $out/share/applications
      if [ -d "${pkg}/share" ]; then
        for item in ${pkg}/share/*; do
          [ -e "$item" ] || continue
          itemName=$(basename "$item")
          [ "$itemName" = "applications" ] && continue
          [ "$itemName" = "dbus-1" ] && continue
          ln -s "$item" "$out/share/" 2>/dev/null || true
        done
      fi
      ${pkgs.lib.optionalString (dbusService != null) ''
        mkdir -p $out/share/dbus-1/services
        if [ -d "${pkg}/share/dbus-1/services" ]; then
          for service in ${pkg}/share/dbus-1/services/*.service; do
            [ -f "$service" ] || continue
            serviceName="${dbusService}"
            cp "$service" "$out/share/dbus-1/services/$serviceName"
            chmod +w "$out/share/dbus-1/services/$serviceName"
            ${pkgs.gnused}/bin/sed -i \
              "s|Exec=${pkg}/bin/.*|Exec=$out/bin/${name}|g" \
              "$out/share/dbus-1/services/$serviceName"
          done
        fi
      ''}
      if [ -d "${pkg}/share/applications" ]; then
        for desktop in ${pkg}/share/applications/*.desktop; do
          [ -f "$desktop" ] || continue
          cp "$desktop" "$out/share/applications/${name}.desktop"
          chmod +w "$out/share/applications/${name}.desktop"
          ${pkgs.gnused}/bin/sed -i \
            "s|Exec=${pkg}/bin/|Exec=$out/bin/|g; \
             s|Exec=${bin}|Exec=$out/bin/${name}|g; \
             s|Exec=env DESKTOPINTEGRATION=1 ${bin}|Exec=$out/bin/${name}|g; \
             s|Exec=env [^ ]* ${bin}|Exec=$out/bin/${name}|g" \
            "$out/share/applications/${name}.desktop"
          ${pkgs.lib.optionalString (dbusService != null) ''
            ${pkgs.gnused}/bin/sed -i "s|^DBusActivatable=.*|DBusActivatable=true|" \
              "$out/share/applications/${name}.desktop"
          ''}
          ${pkgs.lib.optionalString (execArgs != "") ''
            if grep -q "^Exec=" "$out/share/applications/${name}.desktop"; then
              ${pkgs.gnused}/bin/sed -i "s|^\(Exec=.*\)$|\1 ${execArgs}|" "$out/share/applications/${name}.desktop"
            fi
          ''}
          ${pkgs.lib.optionalString (mimeTypes != []) ''
            mimeStr="${pkgs.lib.concatStringsSep ";" mimeTypes};"
            if grep -q "^MimeType=" "$out/share/applications/${name}.desktop"; then
              ${pkgs.gnused}/bin/sed -i "s|^MimeType=.*|MimeType=$mimeStr|" "$out/share/applications/${name}.desktop"
            else
              echo "MimeType=$mimeStr" >> "$out/share/applications/${name}.desktop"
            fi
          ''}
        done
      fi
      makeWrapper ${nixGLBin} $out/bin/${name} \
        --add-flags ${pkg}/bin/${bin} \
        ${pkgs.lib.concatMapStringsSep " \\\n      " (f: "--add-flags \"${f}\"") allFlags} \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.xdg-utils pkgs.coreutils pkgs.gnugrep pkgs.gnused ]} \
        --prefix LD_LIBRARY_PATH : ${pkgs.fcitx5-gtk}/lib \
        ${pkgs.lib.concatStringsSep " \\\n      " (pkgs.lib.mapAttrsToList (k: v: "--set ${k} ${v}") allEnv)}
      ${pkgs.lib.concatMapStringsSep "\n      " (a: "ln -s $out/bin/${name} $out/bin/${a}") aliases}
    '';

  mkNixGLApp = { pkg, name, binary ? null, platform ? "xcb", extraFlags ? [], extraEnv ? {}, aliases ? [], desktopName, comment, categories, icon, mimeTypes ? [], execArgs ? "", dbusService ? null }:
    let
      wrapped = wrapWithNixGL { inherit pkg name binary platform extraFlags extraEnv aliases mimeTypes execArgs dbusService; };
      execPath = "${wrapped}/bin/${name}";
      allNames = [name] ++ aliases;
    in {
      package = wrapped;
      exec = execPath;
      shellAliases = pkgs.lib.listToAttrs (map (a: { name = a; value = execPath; }) allNames);
      binScripts = pkgs.lib.listToAttrs (map (a: {
        name = ".local/bin/${a}";
        value = {
          text = ''
            #!${pkgs.bash}/bin/bash
            exec ${execPath} "$@"
          '';
          executable = true;
        };
      }) allNames);
      desktopEntry = {
        name = desktopName;
        exec = "${execPath}${if execArgs != "" then " ${execArgs}" else ""}";
        terminal = false;
        type = "Application";
        inherit comment categories icon;
      } // pkgs.lib.optionalAttrs (mimeTypes != []) { mimeType = mimeTypes; };
      mimeAssoc = if mimeTypes != [] then pkgs.lib.listToAttrs (map (m: { name = m; value = [ "${name}.desktop" ]; }) mimeTypes) else {};
    };

  allApps = {
    cursor = mkNixGLApp {
      pkg = pkgs.code-cursor;
      name = "cursor";
      platform = "wayland";
      desktopName = "Cursor";
      comment = "Cursor (nixGL)";
      categories = [ "Development" "IDE" ];
      icon = "cursor";
    };
    cider1 = mkNixGLApp {
      pkg = pkgs.cider;
      name = "cider1";
      platform = "x11";
      desktopName = "cider1";
      comment = "cider1 (nixGL)";
      categories = [ "Development" "IDE" ];
      icon = "cider";
    };
    telegram = mkNixGLApp {
      pkg = pkgs.telegram-desktop;
      name = "telegram-desktop";
      binary = "Telegram";
      extraEnv = {
        QT_QPA_PLATFORM = "wayland";
        QTWEBENGINE_DISABLE_SANDBOX = "1";
      };
      aliases = [ "Telegram" "telegram" ];
      desktopName = "Telegram Desktop";
      comment = "Telegram Desktop (nixGL)";
      categories = [ "Network" "InstantMessaging" ];
      icon = "telegram";
      mimeTypes = [ "x-scheme-handler/tg" ];
      dbusService = "org.telegram.desktop.service";
    };


    gearlever = mkNixGLApp {
      pkg = pkgs.gearlever;
      name = "gearlever";
      desktopName = "Gear Lever (nixGL)";
      comment = "Manage AppImages with Gear Lever (wrapped by nixGL)";
      categories = [ "GTK" "Utility" ];
      icon = "it.mijorus.gearlever";
      mimeTypes = [ "application/vnd.appimage" ];
      execArgs = "%U";
    };

    readest = mkNixGLApp {
      pkg = pkgs.readest;
      name = "readest";
      platform = "wayland";
      extraFlags = [
        "--single-instance"
        "--disable-gpu-sandbox"
        "--ignore-gpu-blocklist"
      ];
      desktopName = "Readest (nixGL)";
      comment = "Readest (nixGL)";
      categories = [ "Office" "Utility" ];
      icon = "readest";
      mimeTypes = [
        "x-scheme-handler/readest"
        "application/epub+zip"
        "application/x-mobipocket-ebook"
        "application/vnd.amazon.ebook"
        "application/vnd.amazon.mobi8-ebook"
        "application/x-fictionbook+xml"
        "application/vnd.comicbook+zip"
        "application/pdf"
      ];
      execArgs = "%u";
    };

    podman-desktop = mkNixGLApp {
      pkg = pkgs.podman-desktop;
      name = "podman-desktop";
      platform = "wayland";
      desktopName = "Podman Desktop (nixGL)";
      comment = "Podman Desktop (nixGL)";
      categories = [ "Development" "Utility" "X-Virtualization" ];
      icon = "podman-desktop";
    };

    zotero = mkNixGLApp {
      pkg = pkgs.zotero;
      name = "zotero";
      platform = "wayland";
      extraEnv = {
        GTK_IM_MODULE_FILE = "${config.home.homeDirectory}/.nix-profile/etc/gtk-3.0/immodules.cache";
      };
      desktopName = "Zotero (nixGL)";
      comment = "Zotero (nixGL)";
      categories = [ "Office" "Utility" ];
      icon = "zotero";
    };
  };

  apps = if enabledApps == null then allApps else pkgs.lib.filterAttrs (name: _: pkgs.lib.elem name enabledApps) allApps;

in
{
  packages = pkgs.lib.mapAttrsToList (_: app: app.package) apps;
  shellAliases = pkgs.lib.foldl' (acc: app: acc // app.shellAliases) {} (pkgs.lib.attrValues apps);
  binScripts = pkgs.lib.foldl' (acc: app: acc // app.binScripts) {} (pkgs.lib.attrValues apps);
  desktopEntries = pkgs.lib.mapAttrs (_: app: app.desktopEntry) apps;
  mimeAssociations = pkgs.lib.foldl' (acc: app: acc // app.mimeAssoc) {} (pkgs.lib.attrValues apps);
}
