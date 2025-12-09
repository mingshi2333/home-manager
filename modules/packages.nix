{ config, pkgs, nixglApps, nixGLPackage, ... }:

{
  home.packages =
    nixglApps.packages
    ++ (with pkgs; [
      # Office and productivity
      wpsoffice-cn
      onedrivegui
      pdfstudioviewer

      # Text editors
      kdePackages.kate

      # Nix tools
      nix
      nixfmt
      nix-du

      # Utilities
      qtscrcpy
      xdg-utils
      vulkan-tools
      nsc

      # Communication and media
      zoom-us
      spotify

      # nixGL package
      nixGLPackage
    ]);
}
