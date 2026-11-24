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
  alone = import ./alone.nix args;
  directories = builtins.readDir ./modules;
  # The cases of a module: its import alone, and those of each file of its directory, if it has one.
  # Each case is named after its module, file and case, so that a failure names it.
  cases =
    module:
    let
      directory = ./modules + "/${module}";
      named = name: test: test.overrideAttrs { name = "test-${module}-${name}"; };
      file =
        file: _:
        let
          case =
            case: test:
            let
              name = "${lib.removeSuffix ".nix" file}-${case}";
            in
            lib.nameValuePair name (named name test);
        in
        lib.mapAttrs' case (import (directory + "/${file}") args);
    in
    {
      alone = named "alone" alone.${module};
    }
    // lib.optionalAttrs (directories ? ${module}) (
      lib.concatMapAttrs file (
        lib.filterAttrs (file: _: lib.hasSuffix ".nix" file) (builtins.readDir directory)
      )
    );
  # A directory of tests whose module does not exist would be ignored, as after a rename of the
  # module.
  orphans = lib.attrNames (lib.removeAttrs directories (lib.attrNames flakeModules));
in
assert lib.assertMsg (orphans == [ ])
  "tests/modules has directories with no module in src/modules: ${lib.concatStringsSep ", " orphans}";
# One check per module, which builds all its cases, so that the tests of a module run together.
lib.mapAttrs' (
  module: _: lib.nameValuePair "test-${module}" (pkgs.linkFarm "test-${module}" (cases module))
) flakeModules
