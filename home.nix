{ config, pkgs, ... }:

let
  nixglPackages = pkgs.callPackage ./nixgl-noimpure.nix { };
  nixGLPackage = nixglPackages.auto.nixGLDefault;
  nixGLBin = "${nixGLPackage}/bin/nixGL";

  cursorPackage = pkgs.symlinkJoin {
    name = "code-cursor-nixgl";
    paths = [ pkgs.code-cursor ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/cursor
      makeWrapper ${nixGLBin} $out/bin/cursor \
        --add-flags ${pkgs.code-cursor}/bin/cursor \
        --prefix LD_LIBRARY_PATH : ${pkgs.fcitx5-gtk}/lib \
        --set GTK_IM_MODULE fcitx \
        --set QT_IM_MODULE fcitx \
        --set XMODIFIERS "@im=fcitx" \
        --set SDL_IM_MODULE fcitx \
        --set ELECTRON_OZONE_PLATFORM_HINT x11
    '';
  };

  # Telegram Desktop with nixGL wrapper
  telegramPackage = pkgs.symlinkJoin {
    name = "telegram-desktop-nixgl";
    paths = [ pkgs.telegram-desktop ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # telegram-desktop 的可执行文件是 Telegram
      rm $out/bin/Telegram 2>/dev/null || true
      makeWrapper ${nixGLBin} $out/bin/telegram-desktop \
        --add-flags ${pkgs.telegram-desktop}/bin/Telegram \
        --prefix LD_LIBRARY_PATH : ${pkgs.fcitx5-gtk}/lib \
        --set GTK_IM_MODULE fcitx \
        --set QT_IM_MODULE fcitx \
        --set XMODIFIERS "@im=fcitx" \
        --set SDL_IM_MODULE fcitx \
        --set QT_QPA_PLATFORM xcb
      # 创建别名
      ln -sf $out/bin/telegram-desktop $out/bin/Telegram
    '';
  };

  readestPackage = pkgs.symlinkJoin {
    name = "readest-nixgl";
    paths = [ pkgs.readest ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/readest
      makeWrapper ${nixGLBin} $out/bin/readest \
        --add-flags ${pkgs.readest}/bin/readest \
        --prefix LD_LIBRARY_PATH : ${pkgs.fcitx5-gtk}/lib \
        --set GTK_IM_MODULE fcitx \
        --set QT_IM_MODULE fcitx \
        --set XMODIFIERS "@im=fcitx" \
        --set SDL_IM_MODULE fcitx
    '';
  };

  podmanDesktopPackage = pkgs.symlinkJoin {
    name = "podman-desktop-nixgl";
    paths = [ pkgs.podman-desktop ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/podman-desktop
      makeWrapper ${nixGLBin} $out/bin/podman-desktop \
        --add-flags ${pkgs.podman-desktop}/bin/podman-desktop \
        --prefix LD_LIBRARY_PATH : ${pkgs.fcitx5-gtk}/lib \
        --set GTK_IM_MODULE fcitx \
        --set QT_IM_MODULE fcitx \
        --set XMODIFIERS "@im=fcitx" \
        --set SDL_IM_MODULE fcitx \
        --set ELECTRON_OZONE_PLATFORM_HINT x11
    '';
  };

  zoteroPackageWrapped = pkgs.symlinkJoin {
    name = "zotero-nixgl";
    paths = [ pkgs.zotero ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/zotero
      makeWrapper ${nixGLBin} $out/bin/zotero \
        --add-flags ${pkgs.zotero}/bin/zotero \
        --prefix LD_LIBRARY_PATH : ${pkgs.fcitx5-gtk}/lib \
        --set GTK_IM_MODULE fcitx \
        --set QT_IM_MODULE fcitx \
        --set XMODIFIERS "@im=fcitx" \
        --set SDL_IM_MODULE fcitx
    '';
  };

  # fcitxQtPatch = pkgs.writeText "fcitx5-qt6-gui-private.patch"
  #   (builtins.concatStringsSep "\n" [
  #     "diff --git a/qt6/CMakeLists.txt b/qt6/CMakeLists.txt"
  #     "index 7b0c3d0..8475d2a 100644"
  #     "--- a/qt6/CMakeLists.txt"
  #     "+++ b/qt6/CMakeLists.txt"
  #     "@@ -1,5 +1,8 @@"
  #     ""
  #     "find_package(Qt6 \${REQUIRED_QT6_VERSION} CONFIG REQUIRED Core DBus Widgets)"
  #     "find_package(Qt6Gui \${REQUIRED_QT6_VERSION} REQUIRED Private)"
  #     "+if(NOT TARGET Qt6::GuiPrivate)"
  #     "+  find_package(Qt6GuiPrivate \${REQUIRED_QT6_VERSION} REQUIRED)"
  #     "+endif()"
  #     "if (ENABLE_QT6_WAYLAND_WORKAROUND)"
  #     "  find_package(Qt6WaylandClient \${REQUIRED_QT6_VERSION} REQUIRED Private)"
  #     "  find_package(Qt6WaylandGlobalPrivate \${REQUIRED_QT6_VERSION} REQUIRED)"
  #     ""
  #   ]);

  cursorExec = "${cursorPackage}/bin/cursor";
  telegramExec = "${telegramPackage}/bin/telegram-desktop";
  readestExec = "${readestPackage}/bin/readest";
  podmanDesktopExec = "${podmanDesktopPackage}/bin/podman-desktop";
  zoteroExec = "${zoteroPackageWrapped}/bin/zotero";
in
{
  # Home Manager 需要知道您的基本配置
  home.username = "mingshi"; # 再次替换为您的用户名
  home.homeDirectory = "/home/mingshi"; # 再次替换为您的用户名
  nixpkgs.config = {
    allowUnfree = true;
  };

  # nixpkgs.overlays = [
  #   (final: prev: {
  #     kdePackages = prev.kdePackages.overrideScope (self: super: {
  #       fcitx5-qt = super.fcitx5-qt.overrideAttrs (old: {
  #         patches = (old.patches or []) ++ [ fcitxQtPatch ];
  #       });
  #     });
  #   })
  # ];

  # 要安装的软件包
  home.packages = with pkgs; [
    telegramPackage
    cursorPackage
    onedrivegui
    pkgs.kdePackages.kate
    nix
    nix-du
    pdfstudioviewer
    podmanDesktopPackage
    qtscrcpy
    readestPackage
    xdg-utils
    vulkan-tools
    zoom-us
    zoteroPackageWrapped
    nixGLPackage
    # --- 特殊包 ---
    nsc
  ];

  # 您可以管理 dotfiles
  # 例如, 创建一个文件 ~/.config/htop/htoprc
  # home.file.".config/htop/htoprc".text = ''
  #   # htop 配置内容
  #   show_program_path=0
  # '';

  # 您还可以让 Home Manager 管理整个配置文件
  # home.file.".config/my-app/config.json".source = ./config.json;


  # 设置环境变量
  home.sessionVariables = {
    EDITOR = "vim";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
    # Make Nix xdg-open use system portal (fixes opening links/PDFs)
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    GTK_USE_PORTAL = "1";
    # Prefer Nix-provided gtk immodules cache and paths to avoid host /usr mismatches
    GTK_IM_MODULE_FILE = "${config.home.homeDirectory}/.nix-profile/etc/gtk-3.0/immodules.cache";
    GTK_PATH = "${config.home.homeDirectory}/.nix-profile/lib/gtk-3.0";
    # Ensure KDE/Wayland sees HM-provided .desktop files in ~/.nix-profile/share
    XDG_DATA_DIRS = "${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share";
    ELECTRON_OZONE_PLATFORM_HINT = "x11";
  };

  xdg.configFile."environment.d/99-fcitx5.conf" = {
    text = ''
      GTK_IM_MODULE=fcitx
      QT_IM_MODULE=fcitx
      XMODIFIERS=@im=fcitx
      SDL_IM_MODULE=fcitx
      INPUT_METHOD=fcitx
    '';
  };

  # Force Electron apps to XWayland at the display-manager level (works for Wayland + X11)
  xdg.configFile."environment.d/20-electron-x11.conf" = {
    text = ''
      ELECTRON_OZONE_PLATFORM_HINT=x11
      # For Nix-wrapped Chromium/Electron apps, ensure wrappers don’t switch to Wayland
      NIXOS_OZONE_WL=0
    '';
  };

  # Make XDG_DATA_DIRS available early to Plasma/Wayland and systemd --user
  xdg.configFile."environment.d/10-xdg-data-dirs.conf" = {
    text = ''
      XDG_DATA_DIRS=${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share
    '';
  };

  programs.zsh.initExtra = ''
    export XMODIFIERS="@im=fcitx"
    export GTK_IM_MODULE=fcitx
    export QT_IM_MODULE=fcitx
    export SDL_IM_MODULE=fcitx
    export INPUT_METHOD=fcitx
    # Force all Electron apps to use XWayland (X11)
    export ELECTRON_OZONE_PLATFORM_HINT=x11
  '';

  programs.zsh.shellAliases = {
    cursor = cursorExec;
    telegram = telegramExec;
    readest = readestExec;
    podman-desktop = podmanDesktopExec;
    zotero = zoteroExec;
    # Home Manager 便捷命令
    hms = "cd ~/.config/home-manager && home-manager switch";
    hmu = "cd ~/.config/home-manager && nix flake update && home-manager switch";
    hmr = "cd ~/.config/home-manager && home-manager switch --rollback";
  };

  # nixGL 包装后的启动脚本，确保命令行和 .desktop 都能加载系统的 GPU 驱动
  home.file.".local/bin/cursor" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${cursorExec} "$@"
    '';
    executable = true;
  };

  home.file.".local/bin/telegram" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${telegramExec} "$@"
    '';
    executable = true;
  };

  home.file.".local/bin/readest" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${readestExec} "$@"
    '';
    executable = true;
  };

  home.file.".local/bin/podman-desktop" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${podmanDesktopExec} "$@"
    '';
    executable = true;
  };

  home.file.".local/bin/zotero" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${zoteroExec} "$@"
    '';
    executable = true;
  };

  xdg.enable = true;

  # Mirror system default apps for links/PDF via Home Manager
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "microsoft-edge-beta.desktop" ];
      "x-scheme-handler/https" = [ "microsoft-edge-beta.desktop" ];
      "application/pdf" = [ "microsoft-edge-beta.desktop" ];
    };
  };

  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;

  # Ensure xdg-open inside Nix uses desktop portal on Fedora/KDE/GNOME
  xdg.configFile."environment.d/30-xdg-portal.conf" = {
    text = ''
      NIXOS_XDG_OPEN_USE_PORTAL=1
      GTK_USE_PORTAL=1
    '';
  };

  # Autostart and configure fcitx5 via Home Manager inputMethod module
  # 暂时禁用，因为 fcitx5-qt6 在 nixpkgs unstable 中有构建问题
  # 请使用系统的 fcitx5 安装
  # i18n.inputMethod = {
  #   enable = true;
  #   type = "fcitx5";
  #   fcitx5.addons = with pkgs; [
  #     fcitx5-gtk
  #     fcitx5-chinese-addons
  #   ];
  # };

  xdg.desktopEntries.cursor = {
    name = "Cursor";
    exec = cursorExec;
    terminal = false;
    type = "Application";
    comment = "Cursor (nixGL)";
    categories = [ "Development" "IDE" ];
    icon = "cursor";
  };

  xdg.desktopEntries.telegram = {
    name = "Telegram Desktop";
    exec = telegramExec;
    terminal = false;
    type = "Application";
    comment = "Telegram Desktop (nixGL)";
    categories = [ "Network" "InstantMessaging" ];
    icon = "telegram";
  };

  xdg.desktopEntries."readest-nixgl" = {
    name = "Readest (nixGL)";
    exec = "${config.home.homeDirectory}/.local/bin/readest %F";
    terminal = false;
    type = "Application";
    comment = "Readest (nixGL)";
    categories = [ "Office" "Utility" ];
    icon = "readest";
    mimeType = [
      "application/epub+zip"
      "application/x-mobipocket-ebook"
      "application/vnd.amazon.ebook"
      "application/vnd.amazon.mobi8-ebook"
      "application/x-fictionbook+xml"
      "application/vnd.comicbook+zip"
      "application/pdf"
    ];
  };

  xdg.desktopEntries.podman_desktop = {
    name = "Podman Desktop (nixGL)";
    exec = podmanDesktopExec;
    terminal = false;
    type = "Application";
    comment = "Podman Desktop (nixGL, X11)";
    categories = [ "Development" "Utility" "X-Virtualization" ];
    icon = "podman-desktop";
  };

  xdg.desktopEntries.zotero = {
    name = "Zotero (nixGL)";
    exec = zoteroExec;
    terminal = false;
    type = "Application";
    comment = "Zotero (nixGL)";
    categories = [ "Office" "Utility" ];
    icon = "zotero";
  };

  # 自动刷新 desktop files 和 KDE 缓存
  home.activation.refreshDesktopDatabase = config.lib.dag.entryAfter ["writeBoundary"] ''
    # 复制所有 desktop 文件到 ~/.local/share/applications/
    $DRY_RUN_CMD mkdir -p $HOME/.local/share/applications
    
    # 复制 home-manager 生成的 desktop 文件
    if [ -d "$HOME/.nix-profile/share/applications" ]; then
      $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -av --ignore-existing \
        "$HOME/.nix-profile/share/applications/"*.desktop \
        "$HOME/.local/share/applications/" 2>/dev/null || true
    fi
    
    # 刷新 desktop database
    if [ -x "${pkgs.desktop-file-utils}/bin/update-desktop-database" ]; then
      $DRY_RUN_CMD ${pkgs.desktop-file-utils}/bin/update-desktop-database \
        "$HOME/.local/share/applications" 2>/dev/null || true
    fi
    
    # 刷新 KDE 缓存 (如果在 KDE 环境)
    if command -v kbuildsycoca6 &> /dev/null; then
      $DRY_RUN_CMD kbuildsycoca6 2>/dev/null || true
    elif command -v kbuildsycoca5 &> /dev/null; then
      $DRY_RUN_CMD kbuildsycoca5 2>/dev/null || true
    fi
  '';

  # 让 Home Manager 管理它自己
  programs.home-manager.enable = true;

  # 设置您的状态版本，这对于平滑升级很重要
  home.stateVersion = "23.11"; # 或者您开始使用的任何版本
}
