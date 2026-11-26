{
  inputs,
  lib,
  modules,
  pkgs,
  system,
}:
let
  # The modules of devkit at a fixed commit, since devkit's own flake has none when its working tree
  # has changes.
  flakeModules = modules { rev = lib.strings.replicate 40 "0"; };
  args = {
    inherit
      flakeModules
      lib
      modules
      pkgs
      ;
    repository = import ./libs/repository.nix { inherit lib pkgs; };
    consumer =
      modules:
      let
        flake = inputs.flake-parts.lib.mkFlake { inherit inputs; } {
          imports = modules;
          systems = [ system ];
          # Gives in allSystems the generated files and the commands, which a case may build.
          debug = true;
        };
      in
      lib.mapAttrs (_: output: output.${system}) {
        inherit (flake) apps checks devShells;
      }
      # A flake without a formatter has none for the system, and one without the files or commands
      # module no generated files or commands.
      // {
        formatter = flake.formatter.${system} or null;
        files = flake.allSystems.${system}.devkit.files or { };
        commands = flake.allSystems.${system}.devkit.commands or { };
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
  orphans = lib.concatStringsSep ", " (
    lib.attrNames (lib.removeAttrs directories (lib.attrNames flakeModules))
  );
in
assert lib.assertMsg (
  orphans == ""
) "tests/modules has directories with no module in src/modules: ${orphans}";
# One check per module, which builds all its cases: the CI runs a job per test-<module> check, and
# each job sets up a machine and installs Nix, which a check per case would repeat for every case.
lib.mapAttrs' (
  module: _: lib.nameValuePair "test-${module}" (pkgs.linkFarm "test-${module}" (cases module))
) flakeModules
