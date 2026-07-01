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

    # Note: nixGL is vendored locally (nixgl-noimpure.nix) so the upstream
    # flake input is intentionally NOT declared here.

    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
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
      ...
    }:
    let
      # System architecture
      system = "x86_64-linux";

      # Username - can be overridden if needed
      username = "mingshi";

      pkgs = import nixpkgs {
        inherit system;
        # Unfree packages (claude-desktop, spotify, wpsoffice-cn, karing) are
        # gated by home.nix's `nixpkgs.config.allowUnfree = true`, which is what
        # home-manager actually applies. A predicate on THIS pkgs set would be
        # dead: home-manager re-imports nixpkgs with the module's nixpkgs.config
        # and only takes pkgs.path/overlays/system from here.
        overlays = [
          # gearlever pulls dwarfs transitively (currently 0.14.0); its default
          # build fails against boost 1.89 (missing boost_system), so pin dwarfs'
          # boost to 1.87. NOT dead code — dwarfs is in the build closure via
          # gearlever. Re-test dropping this whenever bumping nixpkgs.
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

      # `nix fmt` and the CI format gate.
      formatter.${system} = pkgs.nixfmt;

      # `nix flake check` evaluates every output (incl. the full home config, so
      # eval errors surface) and builds these checks. Only the two pure
      # ripgrep-based boundary tests are sandbox-safe; the eval/build tests run
      # via `nix run .#test` (tests/ci.sh) and the live-desktop tests stay manual.
      checks.${system} = {
        source-boundaries =
          pkgs.runCommand "check-source-boundaries" { nativeBuildInputs = [ pkgs.ripgrep ]; }
            ''
              cp -r ${self} src && cd src
              bash tests/source-boundaries.sh
              touch $out
            '';
        karing-boundary =
          pkgs.runCommand "check-karing-boundary" { nativeBuildInputs = [ pkgs.ripgrep ]; }
            ''
              cp -r ${self} src && cd src
              bash tests/karing-package-boundary.sh
              touch $out
            '';
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nixfmt
          pkgs.shellcheck
          pkgs.ripgrep
          pkgs.jq
        ];
      };

      # `nix run .#test` — the CI-safe eval/build test tiers (not the live ones).
      apps.${system}.test = {
        type = "app";
        meta.description = "Run the CI-safe test tiers (tests/ci.sh) from the working tree";
        program = "${pkgs.writeShellScript "hm-ci-tests" ''
          exec ${pkgs.bash}/bin/bash tests/ci.sh
        ''}";
      };
    };
}
