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
      {
        flake-parts-lib,
        lib,
        self,
        ...
      }:
      let
        # The modules, as a function of devkit's flake, so that the tests can give it any commit.
        # A module runs in the flake that imports it, whose self and inputs are not devkit's.
        modules =
          devkit:
          lib.mapAttrs (name: _: ./src/modules + "/${name}") (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./src/modules)
          )
          // {
            # importApply gives the module a file but no key, so the key of its path makes a flake
            # that imports it twice get it once, as for the other modules, which are paths.
            github-actions = {
              key = toString ./src/modules/github-actions;
              imports = [
                (flake-parts-lib.importApply ./src/modules/github-actions { inherit devkit; })
              ];
            };
          };
        flakeModules = modules self;
      in
      {
        imports = lib.attrVals [
          "commits"
          "editorconfig"
          "envrc"
          "github-actions"
          "nix"
          "licenses"
          "shell"
          "yaml"
        ] flakeModules;
        # The popular systems for which all the tools are in nixpkgs' binary cache.
        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ];
        flake.lib = import ./src/lib.nix;
        flake.flakeModules = flakeModules;
        perSystem =
          { pkgs, system, ... }:
          {
            # A commit cannot hold its own hash, so devkit calls the workflow of its own commit.
            devkit.github-actions.flakeChecksWorkflow = "./.github/workflows/flake-checks.yml";
            checks = import ./tests {
              inherit
                inputs
                lib
                modules
                pkgs
                system
                ;
            };
          };
      }
    );
}
