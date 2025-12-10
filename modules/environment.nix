{ config, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "vim";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    GTK_USE_PORTAL = "1";
    XDG_DATA_DIRS = "${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # XDG environment.d configuration for systemd user services
  # PATH must include both nix-profile/bin AND system paths for plasmashell
  xdg.configFile."environment.d/05-nix-path.conf".text = ''
    PATH=${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
  '';

  xdg.configFile."environment.d/10-xdg-data-dirs.conf".text = ''
    XDG_DATA_DIRS=${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:/usr/local/share:/usr/share
  '';

  xdg.configFile."environment.d/20-electron-wayland.conf".text = ''
    ELECTRON_OZONE_PLATFORM_HINT=wayland
    NIXOS_OZONE_WL=1
  '';

  xdg.configFile."environment.d/30-xdg-portal.conf".text = ''
    NIXOS_XDG_OPEN_USE_PORTAL=1
    GTK_USE_PORTAL=1
  '';
}
