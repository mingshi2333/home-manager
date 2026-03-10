{
  config,
  pkgs,
  nixGLBin,
  fcitxEnv,
  enabledApps ? null,
  ...
}:

let

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

  mkCatalogNixGLApp =
    catalogId:
    {
      enable ? true,
      name ? catalogId,
      ...
    }@args:
    {
      inherit enable;
      app =
        (mkNixGLApp (
          builtins.removeAttrs args [ "enable" ]
          // {
            inherit name;
          }
        ))
        // {
          desktopId = name;
        };
    };

  mkStandardNixGLApp =
    catalogId:
    {
      enable ? true,
      name ? catalogId,
      pkg,
      desktopName ? "${name} (nixGL)",
      comment ? desktopName,
      icon ? name,
      ...
    }@args:
    mkCatalogNixGLApp catalogId (
      builtins.removeAttrs args [ "enable" ]
      // {
        inherit
          enable
          name
          pkg
          desktopName
          comment
          icon
          ;
      }
    );

  mkCustomApp =
    catalogId:
    {
      enable ? true,
      package ? null,
      shellAliases ? { },
      binScripts ? { },
      desktopId ? catalogId,
      desktopEntry,
      mimeAssoc ? { },
    }:
    {
      inherit enable;
      app = {
        inherit
          package
          shellAliases
          binScripts
          desktopId
          desktopEntry
          mimeAssoc
          ;
      };
    };

  standardApp =
    args@{
      enable ? true,
      ...
    }:
    {
      inherit enable;
      render = catalogId: (mkStandardNixGLApp catalogId (builtins.removeAttrs args [ "enable" ])).app;
    };

  customApp =
    args@{
      enable ? true,
      ...
    }:
    {
      inherit enable;
      render = catalogId: (mkCustomApp catalogId (builtins.removeAttrs args [ "enable" ])).app;
    };

  lenovoLegionBinScripts = {
    ".local/bin/lenovo-legion-pkexec" = {
      text = ''
        #!${pkgs.bash}/bin/bash
        export SHELL=/bin/bash
        exec ${pkgs.util-linux}/bin/pkexec ${pkgs.lenovo-legion}/bin/legion_cli "$@"
      '';
      executable = true;
    };

    ".local/bin/lenovo-legion-gui-pkexec" = {
      text = ''
        #!${pkgs.bash}/bin/bash
        export SHELL=/bin/bash
        exec ${pkgs.util-linux}/bin/pkexec ${pkgs.lenovo-legion}/bin/legion_gui "$@"
      '';
      executable = true;
    };
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

    gearlever = standardApp {
      pkg = pkgs.gearlever;
      extraEnv = {
        GSK_RENDERER = "gl";
      };
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

    podman-desktop = standardApp {
      pkg = pkgs.podman-desktop;
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

    cozy = standardApp {
      pkg = pkgs.cozy;
      platform = "x11";
      desktopName = "cozy (nixGL)";
      comment = "cozy (nixGL)";
      categories = [
        "Development"
        "Utility"
        "X-Virtualization"
      ];
      icon = "cozy";
    };

    qq = standardApp {
      pkg = pkgs.qq;
      platform = "wayland";
      desktopName = "QQ (nixGL)";
      comment = "QQ Instant Messaging (nixGL)";
      categories = [
        "Network"
        "InstantMessaging"
      ];
      icon = "qq";
    };

    wechat = standardApp {
      pkg = pkgs.wechat;
      platform = "wayland";
      desktopName = "wechat (nixGL)";
      comment = "wechat Instant Messaging (nixGL)";
      categories = [
        "Network"
        "InstantMessaging"
      ];
      icon = "wechat";
    };

    zotero = standardApp {
      pkg = pkgs.zotero;
      platform = "x11";
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

    tracy = standardApp {
      pkg = pkgs.tracy;
      platform = "x11";
      desktopName = "Tracy Profiler (nixGL)";
      comment = "Real-time frame profiler (nixGL)";
      categories = [
        "Development"
        "Debugger"
        "Profiling"
      ];
      icon = "tracy";
    };
    element = standardApp {
      pkg = pkgs.element-desktop;
      name = "element-desktop";
      platform = "wayland";
      desktopName = "element-desktop (nixGL)";
      comment = "element-desktop (nixGL)";
      categories = [
        "Network"
        "InstantMessaging"
      ];
      icon = "element-desktop";
    };

    ayugram = standardApp {
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

    lenovo-legion = customApp {
      shellAliases = {
        legionpk = "lenovo-legion-pkexec";
      };
      binScripts = lenovoLegionBinScripts;
      desktopId = "lenovo-legion-gui-pkexec";
      desktopEntry = {
        name = "Lenovo Legion Control (pkexec)";
        exec = "${config.home.homeDirectory}/.local/bin/lenovo-legion-gui-pkexec";
        terminal = false;
        type = "Application";
        comment = "Lenovo Legion Control via pkexec";
        categories = [
          "Utility"
          "System"
        ];
        icon = "computer";
      };
    };

    # readest = mkNixGLApp {
    #   pkg = pkgs.readest;
    #   name = "readest";
    #   platform = "wayland";
    #   desktopName = "Readest (nixGL)";
    #   comment = "Modern ebook reader supporting EPUB, PDF, MOBI and more (nixGL)";
    #   categories = [
    #     "Office"
    #     "Viewer"
    #   ];
    #   icon = "readest";
    #   mimeTypes = [
    #     # EPUB formats
    #     "application/epub+zip"
    #     # PDF
    #     "application/pdf"
    #     # MOBI and AZW formats
    #     "application/x-mobipocket-ebook"
    #     "application/vnd.amazon.ebook"
    #     "application/vnd.amazon.mobi8-ebook"
    #     # Comic book formats
    #     "application/x-cbz"
    #     "application/x-cbr"
    #     "application/x-cb7"
    #     "application/x-cbt"
    #     # Fiction Book
    #     "application/x-fictionbook+xml"
    #     "application/x-zip-compressed-fb2"
    #     # Other ebook formats
    #     "application/x-sony-bbeb"
    #     "text/plain"
    #   ];
    #   execArgs = "%U";
    # };
  };

in
let
  enabledCatalogApps = pkgs.lib.filterAttrs (_: app: app.enable) apps;
  requestedAppIds =
    if enabledApps == null then builtins.attrNames enabledCatalogApps else enabledApps;
  selectedAppDefs = pkgs.lib.filterAttrs (name: _: pkgs.lib.elem name requestedAppIds) apps;
  selectedApps = pkgs.lib.mapAttrs (catalogId: value: value.render catalogId) selectedAppDefs;
in
{
  enabledApps = builtins.attrNames selectedAppDefs;
  packages = pkgs.lib.filter (pkg: pkg != null) (
    pkgs.lib.mapAttrsToList (_: app: app.package) selectedApps
  );
  shellAliases = pkgs.lib.foldl' (acc: app: acc // app.shellAliases) { } (
    pkgs.lib.attrValues selectedApps
  );
  binScripts = pkgs.lib.foldl' (acc: app: acc // app.binScripts) { } (
    pkgs.lib.attrValues selectedApps
  );
  desktopEntries = pkgs.lib.listToAttrs (
    pkgs.lib.mapAttrsToList (_: app: {
      name = app.desktopId;
      value = app.desktopEntry;
    }) selectedApps
  );
  mimeAssociations = pkgs.lib.foldl' (acc: app: acc // app.mimeAssoc) { } (
    pkgs.lib.attrValues selectedApps
  );
}
