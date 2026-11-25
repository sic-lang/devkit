{
  description = "Development kit for the repositories of the Sic programming language";

  inputs = {
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { config, lib, ... }:
      {
        imports = [
          ./src/modules/commits
          ./src/modules/editorconfig
          ./src/modules/github-actions
          ./src/modules/licenses
          ./src/modules/nix
          ./src/modules/shell
          ./src/modules/yaml
        ];
        # The popular systems for which all the tools are in nixpkgs' binary cache.
        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ];
        flake.lib = import ./src/lib.nix;
        flake.flakeModules = lib.mapAttrs (name: _: ./src/modules + "/${name}") (
          lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./src/modules)
        );
        perSystem =
          { pkgs, system, ... }:
          {
            checks = import ./tests {
              inherit (config.flake) flakeModules;
              inherit
                inputs
                lib
                pkgs
                system
                ;
            };
          };
      }
    );
}
