{ config, pkgs, nixglApps, dedupApps, ... }:

{
  imports = [
    ../modules/plasma.nix
    ../modules/lenovo-legion.nix
    (import ../modules/desktop-entries.nix {
      inherit
        config
        pkgs
        nixglApps
        dedupApps
        ;
    })
  ];
}
