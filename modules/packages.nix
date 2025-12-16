{
  config,
  pkgs,
  nixglApps,
  nixGLPackage,
  ...
}:

{
  home.packages =
    nixglApps.packages
    ++ (with pkgs; [
      # Office and productivity
      wpsoffice-cn
      onedrivegui

      # Text editors
      kdePackages.kate

      # Nix tools
      nix
      nixfmt
      nix-du
      nix-index # Fast file and package search
      nix-tree # Visualize dependency trees

      # Utilities
      xdg-utils
      vulkan-tools
      nsc
      mamba-cpp
      micromamba
      #      carapace
      pixi
      vivid

      # Communication and media
      spotify

      # nixGL package
      nixGLPackage
    ]);
}
