{ config, pkgs, ... }:

let
  karing = pkgs.callPackage ../packages/karing.nix { };
in

{
  home.packages =
    config.local.nixgl.appPackages
    ++ (with pkgs; [
      onedrivegui
      kdePackages.kate
      nix
      # nixfmt / nix-du / nix-index / nix-tree were dropped from the permanent
      # profile (~373 MB, referenced by no script). Run them on demand instead:
      #   nix run nixpkgs#nix-tree   nix run nixpkgs#nix-du   nix run nixpkgs#nix-index
      # nixfmt is available via `nix fmt` (flake formatter) and the devShell.
      xdg-utils
      vulkan-tools
      nsc
      mamba-cpp
      micromamba
      pixi
      vivid
      spotify
      karing
      config.local.nixgl.package
    ]);
}
