{ config, pkgs, ... }:

let
  fcitxEnv = import ./fcitx-env.nix;
  fcitx5Gtk = pkgs.fcitx5-gtk;
  gtk3ImmodulesCache = pkgs.runCommand "gtk3-immodules-cache" {
    nativeBuildInputs = [ pkgs.gtk3.dev fcitx5Gtk ];
  } ''
    mkdir -p $out/etc/gtk-3.0
    gtk-query-immodules-3.0 \
      ${pkgs.gtk3}/lib/gtk-3.0/3.0.0/immodules/*.so \
      ${fcitx5Gtk}/lib/gtk-3.0/3.0.0/immodules/*.so \
      > $out/etc/gtk-3.0/immodules.cache
  '';
in
{
  home.sessionVariables = fcitxEnv // {
    GTK_IM_MODULE_FILE = "${gtk3ImmodulesCache}/etc/gtk-3.0/immodules.cache";
    GTK_PATH = "${fcitx5Gtk}/lib/gtk-3.0";
  };

  xdg.configFile."environment.d/99-fcitx5.conf".text =
    pkgs.lib.concatStringsSep "\n" (
      pkgs.lib.mapAttrsToList (name: value: "${name}=${value}") fcitxEnv
    )
    + "\n"
    + "GTK_IM_MODULE_FILE=${gtk3ImmodulesCache}/etc/gtk-3.0/immodules.cache\n"
    + "GTK_PATH=${fcitx5Gtk}/lib/gtk-3.0\n";
}
