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
      makeWrapper ${nixGLBin} $out/bin/cursor --add-flags ${pkgs.code-cursor}/bin/cursor
    '';
  };

  ayugramPackage = pkgs.symlinkJoin {
    name = "ayugram-desktop-nixgl";
    paths = [ pkgs.ayugram-desktop ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/AyuGram
      makeWrapper ${nixGLBin} $out/bin/AyuGram --add-flags ${pkgs.ayugram-desktop}/bin/AyuGram
    '';
  };

  readestPackage = pkgs.symlinkJoin {
    name = "readest-nixgl";
    paths = [ pkgs.readest ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/readest
      makeWrapper ${nixGLBin} $out/bin/readest --add-flags ${pkgs.readest}/bin/readest
    '';
  };

  cursorExec = "${cursorPackage}/bin/cursor";
  ayugramExec = "${ayugramPackage}/bin/AyuGram";
  readestExec = "${readestPackage}/bin/readest";
in
{
  # Home Manager 需要知道您的基本配置
  home.username = "mingshi"; # 再次替换为您的用户名
  home.homeDirectory = "/home/mingshi"; # 再次替换为您的用户名
  
  
    nixpkgs.config = {
    allowUnfree = true;
  };

  # 要安装的软件包
  home.packages = with pkgs; [
    ayugramPackage
    cursorPackage
    fcitx5
    fcitx5-chinese-addons
    fcitx5-gtk
    hello
    pkgs.kdePackages.kate
    nix
    nix-du
    pdfstudioviewer
    podman-desktop
    qtscrcpy
    readestPackage
    vulkan-tools
    zoom-us
    zotero
    nixGLPackage
    # --- 特殊包 ---
    kdePackages.fcitx5-qt
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
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
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

  programs.zsh.initExtra = ''
    if [ "''${XDG_SESSION_TYPE:-}" = "wayland" ]; then
      export XMODIFIERS="@im=fcitx"
      export GTK_IM_MODULE=fcitx
      export QT_IM_MODULE=fcitx
      export SDL_IM_MODULE=fcitx
      export INPUT_METHOD=fcitx
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
    elif [ "''${XDG_SESSION_TYPE:-}" = "x11" ]; then
      export ELECTRON_OZONE_PLATFORM_HINT=x11
    else
      export ELECTRON_OZONE_PLATFORM_HINT=auto
    fi
  '';

  programs.zsh.shellAliases = {
    cursor = cursorExec;
    telegram = ayugramExec;
    AyuGram = ayugramExec;
    readest = readestExec;
  };

  # nixGL 包装后的启动脚本，确保命令行和 .desktop 都能加载系统的 GPU 驱动
  home.file.".local/bin/cursor" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${cursorExec} "$@"
    '';
    executable = true;
  };

  home.file.".local/bin/AyuGram" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${ayugramExec} "$@"
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

  xdg.enable = true;

  xdg.desktopEntries.cursor = {
    name = "Cursor";
    exec = cursorExec;
    terminal = false;
    type = "Application";
    comment = "Cursor (nixGL)";
    categories = [ "Development" "IDE" ];
    icon = "cursor";
  };

  xdg.desktopEntries.ayugram = {
    name = "Ayugram";
    exec = ayugramExec;
    terminal = false;
    type = "Application";
    comment = "Ayugram Desktop (nixGL)";
    categories = [ "Network" "InstantMessaging" ];
    icon = "ayugram-desktop";
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

  # 让 Home Manager 管理它自己
  programs.home-manager.enable = true;

  # 设置您的状态版本，这对于平滑升级很重要
  home.stateVersion = "23.11"; # 或者您开始使用的任何版本
}
