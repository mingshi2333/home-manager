{
  lib,
  stdenv,
  fetchurl,
  libarchive,
  makeWrapper,
  keybinder3,
}:

let
  karingSource = (import ../sources/karing.nix { inherit fetchurl; }).x86_64-linux;
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
    mkdir -p $out/share/karing
    mkdir -p $out/share/applications
    mkdir -p $out/share/pixmaps

    cp -r usr/share/karing/. $out/share/karing/
    # Upstream RPM ships crashpad_handler mode 0644 (karing/karingService are
    # 0755). sentry-native posix_spawn()s it on every app start; EACCES trips
    # Crashpad's FATAL CHECK (spawn_subprocess.cc) and dumped a SIGTRAP core
    # per launch (21 coredumps May-Jun 2026). Restore the exec bit so the
    # handler spawns instead of trapping. Deleting it would NOT help — the
    # spawn would FATAL identically with ENOENT.
    chmod 755 $out/share/karing/lib/crashpad_handler
    install -m 444 usr/share/applications/karing.desktop $out/share/applications/karing.desktop
    install -m 444 usr/share/pixmaps/karing.png $out/share/pixmaps/karing.png

    makeWrapper $out/share/karing/karing $out/bin/karing \
      --prefix LD_LIBRARY_PATH : "$out/share/karing/lib:${keybinder3}/lib:/usr/lib64"

    if ! grep -qx 'Exec=karing %U' $out/share/applications/karing.desktop; then
      echo "unexpected Karing desktop Exec line" >&2
      exit 1
    fi

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
