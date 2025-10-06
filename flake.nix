{
  description = "My personal NixOS configuration flake";

  inputs = {
    # Nixpkgs (Nix Packages collection)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # 您需要管理的系统架构
      system = "x86_64-linux";
      # 您的用户名
      username = "mingshi";
    in
    {
      # Home Manager Configuration
      homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
        }; # 可选，用于传递额外参数
        modules = [
          # 在这里引入您的 home.nix 文件
          ./home.nix
        ];
      };
    };
}