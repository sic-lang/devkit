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
          lib.mapAttrs (name: _: ./sources/modules + "/${name}") (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./sources/modules)
          )
          # The modules that take devkit's flake, to pin its commit.
          // lib.genAttrs [ "claude-code" "github-actions" ] (
            name:
            let
              path = ./sources/modules + "/${name}";
            in
            {
              # importApply gives the module a file but no key, so the key of its path makes a flake
              # that imports it twice get it once, as for the other modules, which are paths.
              key = toString path;
              imports = [ (flake-parts-lib.importApply path { inherit devkit; }) ];
            }
          );
        flakeModules = modules self;
        devkitLib = import ./sources/lib.nix;
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
        flake.lib = devkitLib;
        flake.flakeModules = flakeModules;
        perSystem =
          {
            config,
            pkgs,
            system,
            ...
          }:
          let
            inherit (config.devkit.formats) json;
          in
          {
            # A commit cannot hold its own hash, so devkit calls the workflow of its own commit.
            devkit.github-actions.flakeChecksWorkflow = "./.github/workflows/flake-checks.yml";
            devkit.files = {
              ".claude-plugin/marketplace.json".source = json.generate "marketplace.json" {
                name = devkitLib.marketplace;
                description = "Plugins for the repositories of the Sic programming language";
                owner.name = devkitLib.copyrightHolder;
                plugins = [
                  {
                    name = devkitLib.plugin;
                    source = "./";
                  }
                ];
              };
              ".claude-plugin/plugin.json".source = json.generate "plugin.json" {
                name = devkitLib.plugin;
                description = "Skills to adopt devkit in a repository and to use its modules";
                author.name = devkitLib.copyrightHolder;
                repository = "https://github.com/${devkitLib.repository}";
                inherit (devkitLib) license;
              };
            };
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
