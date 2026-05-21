{ config, pkgs, ... }:

let
  xdgDataDirs = "${config.home.homeDirectory}/.nix-profile/share:/nix/var/nix/profiles/default/share:${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share";
in

{
  home.sessionVariables = {
    EDITOR = "vim";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    GTK_USE_PORTAL = "1";
    WEBKIT_DISABLE_DMABUF_RENDERER = "1";
    XDG_DATA_DIRS = xdgDataDirs;
  };

  # XDG environment.d configuration for systemd user services
  # PATH must include both system paths and nix-profile/bin
  xdg.configFile."environment.d/05-nix-path.conf".text = ''
    PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:${config.home.homeDirectory}/.cache/.bun/bin:${config.home.homeDirectory}/.nix-profile/bin:/nix/var/nix/profiles/default/bin
  '';

  xdg.configFile."environment.d/10-xdg-data-dirs.conf".text = ''
    XDG_DATA_DIRS=${xdgDataDirs}
  '';

  xdg.configFile."environment.d/30-xdg-portal.conf".text = ''
    NIXOS_XDG_OPEN_USE_PORTAL=1
    GTK_USE_PORTAL=1
  '';

  xdg.configFile."environment.d/40-webkit-graphics.conf".text = ''
    WEBKIT_DISABLE_DMABUF_RENDERER=1
  '';
}
