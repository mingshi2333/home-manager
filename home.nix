{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./modules/nixgl-runtime.nix
    ./modules/home-manager-commands.nix
    ./profiles/base.nix
    ./profiles/gui.nix
    ./profiles/packages.nix
  ];

  programs.home-manager.enable = true;
}
