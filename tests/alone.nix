# devkit imports every module, so its own use would not show that a module misses an import that
# another module provides.
# Each module is therefore imported alone here, and everything that it gives the flake is built.
{
  consumer,
  flakeModules,
  lib,
  pkgs,
  ...
}:
lib.mapAttrs (
  name: module:
  let
    outputs = consumer [ module ];
  in
  pkgs.writeText name (
    lib.concatLines (
      map toString (
        lib.attrValues outputs.checks
        ++ lib.attrValues outputs.devShells
        ++ map (app: app.program) (lib.attrValues outputs.apps)
        ++ lib.optional (outputs.formatter != null) outputs.formatter
      )
    )
  )
) flakeModules
