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
        # The tests of tests/, each file a set of flake checks named after its path.
        perSystem =
          { pkgs, system, ... }:
          let
            args = {
              inherit (config.flake) flakeModules;
              inherit lib pkgs;
              consumer =
                modules:
                let
                  flake = inputs.flake-parts.lib.mkFlake { inherit inputs; } {
                    imports = modules;
                    systems = [ system ];
                  };
                in
                lib.mapAttrs (_: output: output.${system}) {
                  inherit (flake) apps checks devShells;
                };
            };
            tests =
              prefix: path: type:
              let
                entry = name: tests "${prefix}-${lib.removeSuffix ".nix" name}" (path + "/${name}");
              in
              if type == "directory" then
                lib.concatMapAttrs entry (builtins.readDir path)
              else
                lib.mapAttrs' (test: lib.nameValuePair "${prefix}-${test}") (import path args);
          in
          {
            checks = tests "test" ./tests "directory";
          };
      }
    );
}
