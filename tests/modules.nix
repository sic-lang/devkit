# devkit's own use of the reuse module does not test the modules that reuse imports on their own,
# so each module is tested alone here.
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
