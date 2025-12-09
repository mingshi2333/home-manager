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
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # System architecture
      system = "x86_64-linux";

      # Username - can be overridden if needed
      username = "mingshi";
    in
    {
      # Home Manager Configuration
      homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};

        # Extra arguments passed to all modules
        extraSpecialArgs = {
          inherit username;
        };

        modules = [
          # Main configuration file (imports all modular configs)
          ./home.nix
        ];
      };
    };
}
