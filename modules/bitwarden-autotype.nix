{
  config,
  pkgs,
  ...
}:

let
  rofiRbwConfig = ''
    selector=fuzzel
    clipboarder=wl-copy
    typer=ydotool
    typing-start-delay=0.5
    typing-key-delay=20
    clear-after=20
  '';

  rofiRbwMenu = pkgs.writeShellScript "rofi-rbw-menu" ''
    set -euo pipefail

    export PATH="${
      pkgs.lib.makeBinPath [
        pkgs.fuzzel
        pkgs.rbw
        pkgs.rofi-rbw
        pkgs.wl-clipboard
        pkgs.xdotool
        pkgs.ydotool
      ]
    }:$PATH"

    choice=$(
      printf '%s\n' \
        "Login - username/password" \
        "Login + TOTP - same page" \
        "Copy TOTP - paste yourself" \
        "Type TOTP - current field" \
        "X11 Login - fallback" |
        fuzzel --dmenu -p "Bitwarden"
    )

    case "$choice" in
      "Login - username/password")
        exec rofi-rbw
        ;;
      "Login + TOTP - same page")
        exec rofi-rbw --target username --target tab --target password --target tab --target totp
        ;;
      "Copy TOTP - paste yourself")
        exec rofi-rbw --action copy --target totp
        ;;
      "Type TOTP - current field")
        exec rofi-rbw --target totp
        ;;
      "X11 Login - fallback")
        exec rofi-rbw --typer xdotool --selector fuzzel --clipboarder wl-copy --typing-start-delay 0.3 --typing-key-delay 10
        ;;
    esac
  '';

  rofiRbwDesktopEntry = ''
    [Desktop Entry]
    Type=Application
    Version=1.5
    Name=Bitwarden Auto-Type Menu
    GenericName=Bitwarden Auto-Type Menu
    Comment=Choose a Bitwarden auto-type action
    Exec=${rofiRbwMenu}
    Terminal=false
    Categories=Utility;Security;
    NoDisplay=true
    Keywords=Bitwarden;rbw;Password;Auto-Type;
    X-KDE-Shortcuts=Ctrl+Alt+B
  '';

  rofiRbwXwaylandDesktopEntry = ''
    [Desktop Entry]
    Type=Application
    Version=1.5
    Name=Bitwarden Auto-Type XWayland
    GenericName=Bitwarden Auto-Type XWayland
    Comment=Open rofi-rbw for XWayland/X11 auto-type
    Exec=rofi-rbw --typer xdotool --selector fuzzel --clipboarder wl-copy --typing-start-delay 0.3 --typing-key-delay 10
    Terminal=false
    Categories=Utility;Security;
    NoDisplay=true
    Keywords=Bitwarden;rbw;Password;Auto-Type;XWayland;X11;
    X-KDE-Shortcuts=Ctrl+Alt+Shift+B
  '';

  rofiRbwTotpDesktopEntry = ''
    [Desktop Entry]
    Type=Application
    Version=1.5
    Name=Bitwarden Auto-Type Same-Page TOTP
    GenericName=Bitwarden Auto-Type Same-Page TOTP
    Comment=Open rofi-rbw for username, password, and same-page TOTP auto-type
    Exec=rofi-rbw --target username --target tab --target password --target tab --target totp
    Terminal=false
    Categories=Utility;Security;
    NoDisplay=true
    Keywords=Bitwarden;rbw;Password;Auto-Type;TOTP;
    X-KDE-Shortcuts=Ctrl+Alt+O
  '';

  rofiRbwDesktopFile = pkgs.writeText "rofi-rbw-autotype.desktop" rofiRbwDesktopEntry;
  rofiRbwXwaylandDesktopFile = pkgs.writeText "rofi-rbw-autotype-xwayland.desktop" rofiRbwXwaylandDesktopEntry;
  rofiRbwTotpDesktopFile = pkgs.writeText "rofi-rbw-autotype-totp.desktop" rofiRbwTotpDesktopEntry;
in

{
  home.packages = with pkgs; [
    rbw
    rofi-rbw
    fuzzel
    wl-clipboard
    xdotool
    ydotool
    pinentry-qt
  ];

  xdg.configFile."rofi-rbw.rc".text = rofiRbwConfig;
  # rbw/config.json holds the account email and self-hosted server URL, so it
  # is kept OUT of the repo (and the Nix store) to avoid publishing them.
  # Maintain the real config at ~/.secrets/rbw-config.json; this symlinks to it
  # out-of-store, leaving the file writable so `rbw config set` keeps working.
  xdg.configFile."rbw/config.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.secrets/rbw-config.json";
    force = true;
  };

  systemd.user.services.ydotool = {
    Unit = {
      Description = "ydotoold input automation daemon";
      Documentation = [ "man:ydotoold(8)" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
      Restart = "always";
      KillMode = "process";
      TimeoutSec = 180;
    };

    Install.WantedBy = [ "default.target" ];
  };

  home.activation.configureRofiRbwShortcut = config.lib.dag.entryAfter [ "installPackages" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.local/share/applications"
    $DRY_RUN_CMD rm -f "$HOME/.local/share/applications/rofi-rbw-autotype.desktop"
    $DRY_RUN_CMD install -m 0644 \
      "${rofiRbwDesktopFile}" \
      "$HOME/.local/share/applications/rofi-rbw-autotype.desktop"
    $DRY_RUN_CMD rm -f "$HOME/.local/share/applications/rofi-rbw-autotype-xwayland.desktop"
    $DRY_RUN_CMD install -m 0644 \
      "${rofiRbwXwaylandDesktopFile}" \
      "$HOME/.local/share/applications/rofi-rbw-autotype-xwayland.desktop"
    $DRY_RUN_CMD rm -f "$HOME/.local/share/applications/rofi-rbw-autotype-totp.desktop"
    $DRY_RUN_CMD install -m 0644 \
      "${rofiRbwTotpDesktopFile}" \
      "$HOME/.local/share/applications/rofi-rbw-autotype-totp.desktop"

    if command -v kwriteconfig6 >/dev/null 2>&1; then
      $DRY_RUN_CMD kwriteconfig6 \
        --file "$HOME/.config/kglobalshortcutsrc" \
        --group services \
        --group rofi-rbw-autotype.desktop \
        --key _launch \
        "Ctrl+Alt+B,none,Bitwarden Auto-Type"

      $DRY_RUN_CMD kwriteconfig6 \
        --file "$HOME/.config/kglobalshortcutsrc" \
        --group services \
        --group rofi-rbw-autotype-xwayland.desktop \
        --key _launch \
        "Ctrl+Alt+Shift+B,none,Bitwarden Auto-Type XWayland"

      $DRY_RUN_CMD kwriteconfig6 \
        --file "$HOME/.config/kglobalshortcutsrc" \
        --group services \
        --group rofi-rbw-autotype-totp.desktop \
        --key _launch \
        "Ctrl+Alt+O,none,Bitwarden Auto-Type Same-Page TOTP"
    fi

    if [ -z "''${DRY_RUN_CMD:-}" ]; then
      if command -v kbuildsycoca6 >/dev/null 2>&1; then
        kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
      fi

      systemctl --user restart plasma-kglobalaccel.service >/dev/null 2>&1 || true

      if command -v busctl >/dev/null 2>&1; then
        busctl --user call \
          org.kde.kglobalaccel \
          /kglobalaccel \
          org.kde.KGlobalAccel \
          doRegister \
          as \
          4 \
          rofi-rbw-autotype.desktop \
          _launch \
          "Bitwarden Auto-Type" \
          "Bitwarden Auto-Type" >/dev/null 2>&1 || true

        busctl --user call \
          org.kde.kglobalaccel \
          /kglobalaccel \
          org.kde.KGlobalAccel \
          doRegister \
          as \
          4 \
          rofi-rbw-autotype-xwayland.desktop \
          _launch \
          "Bitwarden Auto-Type XWayland" \
          "Bitwarden Auto-Type XWayland" >/dev/null 2>&1 || true

        busctl --user call \
          org.kde.kglobalaccel \
          /kglobalaccel \
          org.kde.KGlobalAccel \
          doRegister \
          as \
          4 \
          rofi-rbw-autotype-totp.desktop \
          _launch \
          "Bitwarden Auto-Type Same-Page TOTP" \
          "Bitwarden Auto-Type Same-Page TOTP" >/dev/null 2>&1 || true

        busctl --user call \
          org.kde.kglobalaccel \
          /kglobalaccel \
          org.kde.KGlobalAccel \
          setShortcut \
          asaiu \
          4 \
          rofi-rbw-autotype.desktop \
          _launch \
          "Bitwarden Auto-Type" \
          "Bitwarden Auto-Type" \
          1 \
          201326658 \
          0 >/dev/null 2>&1 || true

        busctl --user call \
          org.kde.kglobalaccel \
          /kglobalaccel \
          org.kde.KGlobalAccel \
          setShortcut \
          asaiu \
          4 \
          rofi-rbw-autotype-xwayland.desktop \
          _launch \
          "Bitwarden Auto-Type XWayland" \
          "Bitwarden Auto-Type XWayland" \
          1 \
          234881090 \
          0 >/dev/null 2>&1 || true

        busctl --user call \
          org.kde.kglobalaccel \
          /kglobalaccel \
          org.kde.KGlobalAccel \
          setShortcut \
          asaiu \
          4 \
          rofi-rbw-autotype-totp.desktop \
          _launch \
          "Bitwarden Auto-Type Same-Page TOTP" \
          "Bitwarden Auto-Type Same-Page TOTP" \
          1 \
          201326671 \
          4 >/dev/null 2>&1 || true
      fi
    fi
  '';
}
