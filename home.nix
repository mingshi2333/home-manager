{ config, pkgs, ... }:

{
  # Home Manager 需要知道您的基本配置
  home.username = "mingshi"; # 再次替换为您的用户名
  home.homeDirectory = "/home/mingshi"; # 再次替换为您的用户名

  # 要安装的软件包
  home.packages = with pkgs; [
    # 在这里添加更多您想要的软件包
    # 例如:
    # vscode
    # vlc
    # gimp
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
  };

  # 让 Home Manager 管理它自己
  programs.home-manager.enable = true;

  # 设置您的状态版本，这对于平滑升级很重要
  home.stateVersion = "23.11"; # 或者您开始使用的任何版本
}
