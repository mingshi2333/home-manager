{ config, pkgs, ... }:

let
  fcitxEnv = import ./fcitx-env.nix;
in
{
  home.sessionVariables = fcitxEnv // {
    GTK_IM_MODULE_FILE = "${config.home.homeDirectory}/.nix-profile/etc/gtk-3.0/immodules.cache";
    GTK_PATH = "${config.home.homeDirectory}/.nix-profile/lib/gtk-3.0";
  };

  xdg.configFile."environment.d/99-fcitx5.conf".text =
    pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList (name: value: "${name}=${value}") fcitxEnv
    )
    + "\n";
}
