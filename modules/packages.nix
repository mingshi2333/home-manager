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
      nixfmt
      nix-du
      nix-index
      nix-tree
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
