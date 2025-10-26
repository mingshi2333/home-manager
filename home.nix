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

  # AyuGram 暂时禁用，因为:
  # 1. 官方不提供 Linux 预编译二进制
  # 2. nixpkgs 中的包因 Qt::CorePrivate 依赖问题无法构建
  # 
  # 推荐的安装方式:
  # 方式 1: 使用 Flatpak (推荐)
  #   flatpak install flathub io.github.ayugram.ayugram
  #   或添加 flathub: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  #
  # 方式 2: 使用官方 Telegram Desktop (nixpkgs 中可用)
  #   home.packages = with pkgs; [ telegram-desktop ];
  #
  # 方式 3: 等待上游修复后重新启用 pkgs.ayugram-desktop

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
    # ayugramPackage  # 暂时禁用，等待上游修复 Qt::CorePrivate 构建错误
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
    # telegram = ayugramExec;
    # AyuGram = ayugramExec;
    readest = readestExec;
    podman-desktop = podmanDesktopExec;
    zotero = zoteroExec;
  };

  # nixGL 包装后的启动脚本，确保命令行和 .desktop 都能加载系统的 GPU 驱动
  home.file.".local/bin/cursor" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${cursorExec} "$@"
    '';
    executable = true;
  };

  # home.file.".local/bin/AyuGram" = {
  #   text = ''
  #     #!${pkgs.bash}/bin/bash
  #     exec ${ayugramExec} "$@"
  #   '';
  #   executable = true;
  # };

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

  # xdg.desktopEntries.ayugram = {
  #   name = "Ayugram";
  #   exec = ayugramExec;
  #   terminal = false;
  #   type = "Application";
  #   comment = "Ayugram Desktop (nixGL)";
  #   categories = [ "Network" "InstantMessaging" ];
  #   icon = "ayugram-desktop";
  # };

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

  # 让 Home Manager 管理它自己
  programs.home-manager.enable = true;

  # 设置您的状态版本，这对于平滑升级很重要
  home.stateVersion = "23.11"; # 或者您开始使用的任何版本
}
