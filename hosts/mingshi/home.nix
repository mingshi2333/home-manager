{ ... }:

{
  home.username = "mingshi";
  home.homeDirectory = "/home/mingshi";
  home.stateVersion = "23.11";

  imports = [
    ../../home.nix
  ];
}
