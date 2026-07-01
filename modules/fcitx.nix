{ config, pkgs, ... }:

let
  fcitxEnv = import ./fcitx-env.nix;
  fcitx5Gtk = pkgs.fcitx5-gtk;
  # GTK3 immodules cache combining stock GTK3 IMs with the fcitx5 GTK3 module.
  # Installed into the profile (so it exists at
  # ~/.nix-profile/etc/gtk-3.0/immodules.cache) for *per-app* consumption by
  # nix-packaged GTK3 apps that need fcitx (see zotero's extraEnv in
  # nixgl-apps.nix). It must NOT be exported session-wide via
  # GTK_IM_MODULE_FILE: GTK2 also honors that variable, and host GTK2 apps
  # (e.g. Pinta via mono/gtk-sharp2) then dlopen the GTK3-built im-fcitx5.so —
  # 'FcitxIMContext class size smaller than GtkIMContext' + buffer overflow +
  # SIGABRT on the first GtkEntry realize (5 coredumps May-Jun 2026). Host GTK3
  # apps read /usr/lib64/gtk-3.0/3.0.0/immodules.cache by default and need no
  # override; GTK4 apps do not use immodules.cache at all.
  gtk3ImmodulesCache =
    pkgs.runCommand "gtk3-immodules-cache"
      {
        nativeBuildInputs = [
          pkgs.gtk3.dev
          fcitx5Gtk
        ];
      }
      ''
        mkdir -p $out/etc/gtk-3.0
        gtk-query-immodules-3.0 \
          ${pkgs.gtk3}/lib/gtk-3.0/3.0.0/immodules/*.so \
          ${fcitx5Gtk}/lib/gtk-3.0/3.0.0/immodules/*.so \
          > $out/etc/gtk-3.0/immodules.cache
      '';
in
{
  home.packages = [ gtk3ImmodulesCache ];

  home.sessionVariables = fcitxEnv;

  xdg.configFile."environment.d/99-fcitx5.conf".text =
    pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "${name}=${value}") fcitxEnv)
    + "\n";
}
