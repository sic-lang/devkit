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
        imports = [ ./src/modules/reuse ];
        # The popular systems whose tools are all in the binary cache of nixpkgs: Linux on x86_64
        # and aarch64, and macOS on Apple silicon.
        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ];
        flake.flakeModules = lib.mapAttrs (name: _: ./src/modules + "/${name}") (
          lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./src/modules)
        );
        perSystem =
          { pkgs, system, ... }:
          {
            devkit.checks = {
              actionlint = {
                tools = [ pkgs.actionlint ];
                command = "actionlint";
              };
              yamllint = {
                tools = [ pkgs.yamllint ];
                command = "yamllint --strict .";
              };
            };
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
