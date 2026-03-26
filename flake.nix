{
  description = "Personal home-manager configuration with modular structure";

  inputs = {
    # Temporary pin: nixos-unstable currently regresses electron_39, which breaks hmu/hms via podman-desktop.
    nixpkgs.url = "github:nixos/nixpkgs/a499dfba7b52aac86504356512836550e9d49a5a";

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

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # Temporary workaround: dwarfs-0.12.4 fails with boost 1.89 (missing boost_system).
          (final: prev: {
            dwarfs = prev.dwarfs.override {
              boost = prev.boost187;
            };
          })
        ];
      };
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
