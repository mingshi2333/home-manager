{
  description = "Personal home-manager configuration with modular structure";

  inputs = {
    # nixpkgs follows nixos-unstable branch for up-to-date packages.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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

    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "nixgl/flake-utils";
    };

    claude-desktop-debian = {
      # Pinned: the local patches in patches/claude-desktop-*.patch target this
      # exact upstream revision. Leaving it floating lets `hms-update` bump it to
      # a tree where the patches no longer apply and the build breaks. Bump this
      # rev deliberately together with refreshing the patches.
      url = "github:aaddrick/claude-desktop-debian/2d1d0c59ffb94c0de8a0c5627d03c28099599792";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
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
        # Claude Desktop ships under an unfree license; allow just that package
        # (we build it locally from a patched aaddrick source in nixgl-apps.nix).
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-desktop" ];
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
      packages.${system}.home-manager = home-manager.packages.${system}.home-manager;

      # Home Manager Configuration
      homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Extra arguments passed to all modules
        extraSpecialArgs = {
          inherit username;
          codexDesktopLinux = inputs.codex-desktop-linux;
          claudeDesktopDebian = inputs.claude-desktop-debian;
        };

        modules = [
          # Host-specific entry point
          ./hosts/mingshi/home.nix
        ];
      };
    };
}
