{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    gitignore,
  }: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);

    package = forEachSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
        pkgs.callPackage ./package.nix {
          inherit gitignore;
          pname = "nx-panic-repro";
        }
    );
  in {
    # for `nix flake check`
    checks = forEachSystem (system: {
      package = package.${system}.check;
    });

    devShells =
      forEachSystem
      (system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        default = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks.${system};

          # Extra inputs can be added here
          nativeBuildInputs = with pkgs; [
            gnused
            nodejs
            prefetch-npm-deps
          ];
        };
      });
  };
}
