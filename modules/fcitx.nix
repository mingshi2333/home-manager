{ config, pkgs, ... }:

{
  # Fcitx5 input method environment variables
  # Used across the system for consistent input method support
  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    INPUT_METHOD = "fcitx";
    GTK_IM_MODULE_FILE = "${config.home.homeDirectory}/.nix-profile/etc/gtk-3.0/immodules.cache";
    GTK_PATH = "${config.home.homeDirectory}/.nix-profile/lib/gtk-3.0";
  };

  # Export fcitx environment for systemd user services
  xdg.configFile."environment.d/99-fcitx5.conf".text = ''
    GTK_IM_MODULE=fcitx
    QT_IM_MODULE=fcitx
    XMODIFIERS=@im=fcitx
    SDL_IM_MODULE=fcitx
    INPUT_METHOD=fcitx
  '';
}
