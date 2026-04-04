{
  lib,
  stdenv,
  fetchurl,
  libarchive,
  makeWrapper,
  keybinder3,
}:

let
  karingSource = (import ./sources/karing.nix { inherit fetchurl; }).x86_64-linux;
in
stdenv.mkDerivation rec {
  pname = "karing";
  inherit (karingSource) version src;

  nativeBuildInputs = [
    libarchive
    makeWrapper
  ];

  dontUnpack = true;

  installPhase = ''
        runHook preInstall

        workdir=$(mktemp -d)
        cd "$workdir"
        ${libarchive}/bin/bsdtar -xf $src

        mkdir -p $out/bin
        mkdir -p $out/libexec/karing
        mkdir -p $out/share/karing
        mkdir -p $out/share/applications
        mkdir -p $out/share/pixmaps

        cp -r usr/share/karing/. $out/share/karing/
        install -m 444 usr/share/applications/karing.desktop $out/share/applications/karing.desktop
        install -m 444 usr/share/pixmaps/karing.png $out/share/pixmaps/karing.png

        mv $out/share/karing/karingService $out/share/karing/karingService.bin
        cat > $out/share/karing/karingService <<'EOF'
    #!${stdenv.shell}
    set -eu

    pkexec_bin="@pkexec@"
    external_helper="/usr/local/libexec/karing/karingService-root"
    local_helper="$(dirname "$0")/karingService.bin"

    resolve_pkexec() {
      if [ -x "$pkexec_bin" ]; then
        printf '%s\n' "$pkexec_bin"
        return 0
      fi

      if command -v pkexec >/dev/null 2>&1; then
        command -v pkexec
        return 0
      fi

      return 1
    }

    helper_to_exec="$local_helper"
    if [ -x "$external_helper" ]; then
      helper_to_exec="$external_helper"
    fi

    if [ "$(id -u)" -eq 0 ]; then
      exec "$helper_to_exec" "$@"
    fi

    if [ -x "$external_helper" ]; then
      exec "$external_helper" "$@"
    fi

    if resolved_pkexec="$(resolve_pkexec)"; then
      exec env \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin \
        SHELL=/bin/sh \
        "$resolved_pkexec" "$helper_to_exec" "$@"
    fi

    exec "$helper_to_exec" "$@"
    EOF
        chmod 0755 $out/share/karing/karingService
        substituteInPlace $out/share/karing/karingService \
          --replace-fail '@pkexec@' '/usr/bin/pkexec'

        cat > $out/libexec/karing/sudo <<'EOF'
    #!${stdenv.shell}
    set -eu

    if [ "$#" -ge 3 ] && [ "$1" = "chown" ] && [ "$2" = "root:root" ]; then
      case "$3" in
        */share/karing/karingService)
          exit 0
          ;;
      esac
    fi

    if [ "$#" -ge 3 ] && [ "$1" = "chmod" ] && [ "$2" = "+sx" ]; then
      case "$3" in
        */share/karing/karingService)
          exit 0
          ;;
      esac
    fi

    exec /usr/bin/sudo "$@"
    EOF
        chmod 0755 $out/libexec/karing/sudo

        makeWrapper $out/share/karing/karing $out/bin/karing \
          --set SHELL /bin/sh \
          --prefix PATH : "$out/libexec/karing" \
          --prefix LD_LIBRARY_PATH : "$out/share/karing/lib:${keybinder3}/lib:/usr/lib64"

        substituteInPlace $out/share/applications/karing.desktop \
          --replace-fail 'Exec=karing %U' 'Exec=karing %U'

        runHook postInstall
  '';

  meta = {
    description = "Simple and powerful proxy utility supporting clash and sing-box routing rules";
    homepage = "https://karing.app";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "karing";
  };
}
