{
  flakeModules,
  inputs,
  lib,
  pkgs,
  system,
}:
let
  args = {
    inherit flakeModules lib pkgs;
    repository = import ./repository.nix { inherit lib pkgs; };
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
      }
      # A flake without a formatter has none for the system.
      // {
        formatter = flake.formatter.${system} or null;
      };
  };
  prefixed = prefix: lib.mapAttrs' (case: lib.nameValuePair "${prefix}-${case}");
  module =
    name: _:
    let
      directory = ./modules + "/${name}";
      file =
        file: _:
        let
          cases = import (directory + "/${file}") args;
        in
        prefixed "test-${name}-${lib.removeSuffix ".nix" file}" cases;
    in
    lib.concatMapAttrs file (
      lib.filterAttrs (file: _: lib.hasSuffix ".nix" file) (builtins.readDir directory)
    );
in
prefixed "test-modules" (import ./alone.nix args)
// lib.concatMapAttrs module (builtins.readDir ./modules)
