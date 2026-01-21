{
  description = "Personal home-manager configuration with modular structure";

  inputs = {
    # Using nixos-unstable for latest packages
    # Note: Unstable is preferred to avoid package breakage from version locks
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager for declarative user environment management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixGL for OpenGL/Vulkan on non-NixOS
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixgl,
      ...
    }:
    let
      # System architecture
      system = "x86_64-linux";

      # Username - can be overridden if needed
      username = "mingshi";

      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Home Manager Configuration
      homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Extra arguments passed to all modules
        extraSpecialArgs = {
          inherit username;
        };

        modules = [
          # Host-specific entry point
          ./hosts/mingshi/home.nix
        ];
      };
    };
}
