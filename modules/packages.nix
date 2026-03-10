{ config, pkgs, ... }:

{
  home.packages =
    config.local.nixgl.appPackages
    ++ (with pkgs; [
      wpsoffice-cn
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
      config.local.nixgl.package
    ]);
}
