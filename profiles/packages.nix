{ config, pkgs, nixglApps, nixGLPackage, ... }:

import ../modules/packages.nix {
  inherit
    config
    pkgs
    nixglApps
    nixGLPackage
    ;
}
