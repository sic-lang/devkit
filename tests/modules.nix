# The use of reuse by devkit does not test alone the modules that reuse imports.
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
      )
    )
  )
) flakeModules
