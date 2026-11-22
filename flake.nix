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
        imports = [ ./modules/reuse ];
        # The popular systems whose tools are all in the binary cache of nixpkgs: Linux on x86_64
        # and aarch64, and macOS on Apple silicon.
        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-linux"
        ];
        flake.flakeModules = lib.mapAttrs (name: _: ./modules + "/${name}") (
          lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./modules)
        );
        # Each module, imported alone by a consumer, builds all its outputs: the use of reuse by
        # devkit does not test the modules that reuse imports without it.
        perSystem =
          { pkgs, system, ... }:
          {
            checks = lib.mapAttrs' (
              name: module:
              let
                consumer = inputs.flake-parts.lib.mkFlake { inherit inputs; } {
                  imports = [ module ];
                  systems = [ system ];
                };
                outputs =
                  lib.attrValues consumer.checks.${system}
                  ++ lib.attrValues consumer.devShells.${system}
                  ++ map (app: app.program) (lib.attrValues consumer.apps.${system});
              in
              lib.nameValuePair "module-${name}" (
                pkgs.writeText "module-${name}" (lib.concatLines (map toString outputs))
              )
            ) config.flake.flakeModules;
          };
      }
    );
}
