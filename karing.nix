{
  lib,
  stdenv,
  fetchurl,
  libarchive,
  makeWrapper,
  keybinder3,
}:

let
  source = (import ./karing-sources.nix { inherit fetchurl; }).x86_64-linux;
in
stdenv.mkDerivation rec {
  pname = "karing";
  inherit (source) version src;

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
    install -m 444 usr/share/applications/karing.desktop $out/share/applications/karing.desktop
    install -m 444 usr/share/pixmaps/karing.png $out/share/pixmaps/karing.png

    makeWrapper $out/share/karing/karing $out/bin/karing \
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
