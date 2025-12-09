{
  config,
  pkgs,
  nixGLBin,
  enabledApps ? null,
  ...
}:

let
  fcitxEnv = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
  };

  wrapWithNixGL =
    {
      pkg,
      name,
      binary ? null,
      platform ? "xcb",
      extraFlags ? [ ],
      extraEnv ? { },
      aliases ? [ ],
      mimeTypes ? [ ],
      execArgs ? "",
      dbusService ? null,
    }:
    let
      bin = if binary != null then binary else (pkg.meta.mainProgram or name);
      isWayland = platform == "wayland";
      platformEnv =
        if isWayland then { ELECTRON_OZONE_PLATFORM_HINT = "wayland"; } else { QT_QPA_PLATFORM = "xcb"; };
      waylandFlags =
        if isWayland then
          [
            "--ozone-platform-hint=wayland"
            "--enable-wayland-ime"
          ]
        else
          [ ];
      allFlags = waylandFlags ++ extraFlags;
      allEnv = fcitxEnv // platformEnv // extraEnv;
    in
    pkgs.runCommand "${name}-nixgl"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      ''
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
            ${pkgs.lib.optionalString (mimeTypes != [ ]) ''
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
          --prefix PATH : ${
            pkgs.lib.makeBinPath [
              pkgs.xdg-utils
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gnused
            ]
          } \
          --prefix LD_LIBRARY_PATH : ${pkgs.fcitx5-gtk}/lib \
          ${pkgs.lib.concatStringsSep " \\\n      " (
            pkgs.lib.mapAttrsToList (k: v: "--set ${k} ${v}") allEnv
          )}
        ${pkgs.lib.concatMapStringsSep "\n      " (a: "ln -s $out/bin/${name} $out/bin/${a}") aliases}
      '';

  mkNixGLApp =
    {
      pkg,
      name,
      binary ? null,
      platform ? "xcb",
      extraFlags ? [ ],
      extraEnv ? { },
      aliases ? [ ],
      desktopName,
      comment,
      categories,
      icon,
      mimeTypes ? [ ],
      execArgs ? "",
      dbusService ? null,
    }:
    let
      wrapped = wrapWithNixGL {
        inherit
          pkg
          name
          binary
          platform
          extraFlags
          extraEnv
          aliases
          mimeTypes
          execArgs
          dbusService
          ;
      };
      execPath = "${wrapped}/bin/${name}";
      allNames = [ name ] ++ aliases;
    in
    {
      package = wrapped;
      exec = execPath;
      shellAliases = pkgs.lib.listToAttrs (
        map (a: {
          name = a;
          value = execPath;
        }) allNames
      );
      binScripts = pkgs.lib.listToAttrs (
        map (a: {
          name = ".local/bin/${a}";
          value = {
            text = ''
              #!${pkgs.bash}/bin/bash
              exec ${execPath} "$@"
            '';
            executable = true;
          };
        }) allNames
      );
      desktopEntry = {
        name = desktopName;
        exec = "${execPath}${if execArgs != "" then " ${execArgs}" else ""}";
        terminal = false;
        type = "Application";
        inherit comment categories icon;
      }
      // pkgs.lib.optionalAttrs (mimeTypes != [ ]) { mimeType = mimeTypes; };
      mimeAssoc =
        if mimeTypes != [ ] then
          pkgs.lib.listToAttrs (
            map (m: {
              name = m;
              value = [ "${name}.desktop" ];
            }) mimeTypes
          )
        else
          { };
    };

  apps = {

    # telegram = mkNixGLApp {
    #   pkg = pkgs.telegram-desktop;
    #   name = "telegram-desktop";
    #   binary = "Telegram";
    #   extraEnv = {
    #     QT_QPA_PLATFORM = "wayland";
    #     QTWEBENGINE_DISABLE_SANDBOX = "1";
    #   };
    #   aliases = [ "Telegram" "telegram" ];
    #   desktopName = "Telegram Desktop";
    #   comment = "Telegram Desktop (nixGL)";
    #   categories = [ "Network" "InstantMessaging" ];
    #   icon = "telegram";
    #   mimeTypes = [ "x-scheme-handler/tg" ];
    #   dbusService = "org.telegram.desktop.service";
    # };

    gearlever = mkNixGLApp {
      pkg = pkgs.gearlever;
      name = "gearlever";
      desktopName = "Gear Lever (nixGL)";
      comment = "Manage AppImages with Gear Lever (wrapped by nixGL)";
      categories = [
        "GTK"
        "Utility"
      ];
      icon = "it.mijorus.gearlever";
      mimeTypes = [ "application/vnd.appimage" ];
      execArgs = "%U";
    };

    podman-desktop = mkNixGLApp {
      pkg = pkgs.podman-desktop;
      name = "podman-desktop";
      platform = "wayland";
      desktopName = "Podman Desktop (nixGL)";
      comment = "Podman Desktop (nixGL)";
      categories = [
        "Development"
        "Utility"
        "X-Virtualization"
      ];
      icon = "podman-desktop";
    };
    qq = mkNixGLApp {
      pkg = pkgs.qq;
      name = "qq";
      platform = "wayland";
      desktopName = "QQ (nixGL)";
      comment = "QQ (nixGL)";
      categories = [
        "Development"
        "Utility"
        "X-Virtualization"
      ];
      icon = "qq";
    };

    onlyoffice-desktopeditors = mkNixGLApp {
      pkg = pkgs.onlyoffice-desktopeditors;
      name = "onlyoffice-desktopeditors";
      platform = "wayland";
      desktopName = "onlyoffice-desktopeditors (nixGL)";
      comment = "onlyoffice-desktopeditors (nixGL)";
      categories = [
        "Development"
        "Utility"
        "X-Virtualization"
      ];
      icon = "onlyoffice-desktopeditors";
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
      categories = [
        "Office"
        "Utility"
      ];
      icon = "zotero";
    };
    ayugram = mkNixGLApp {
      pkg = pkgs.ayugram-desktop;
      name = "ayugram-desktop";
      binary = "AyuGram";
      extraEnv = {
        QT_QPA_PLATFORM = "wayland";
        QTWEBENGINE_DISABLE_SANDBOX = "1";
      };
      aliases = [
        "Ayugram"
        "ayugram"
      ];
      desktopName = "Ayugram Desktop";
      comment = "Ayugram Desktop (nixGL)";
      categories = [
        "Network"
        "InstantMessaging"
      ];
      icon = "ayugram";
      mimeTypes = [ "x-scheme-handler/tg" ];
      dbusService = "org.ayugram.desktop.service";
    };
  };

in
let
  # Only build the apps listed in enabledApps (default: all)
  selectedNames = if enabledApps == null then builtins.attrNames apps else enabledApps;
  selectedApps = pkgs.lib.filterAttrs (name: _: pkgs.lib.elem name selectedNames) apps;
in
{
  packages = pkgs.lib.mapAttrsToList (_: app: app.package) selectedApps;
  shellAliases = pkgs.lib.foldl' (acc: app: acc // app.shellAliases) { } (
    pkgs.lib.attrValues selectedApps
  );
  binScripts = pkgs.lib.foldl' (acc: app: acc // app.binScripts) { } (
    pkgs.lib.attrValues selectedApps
  );
  desktopEntries = pkgs.lib.mapAttrs (_: app: app.desktopEntry) selectedApps;
  mimeAssociations = pkgs.lib.foldl' (acc: app: acc // app.mimeAssoc) { } (
    pkgs.lib.attrValues selectedApps
  );
}
