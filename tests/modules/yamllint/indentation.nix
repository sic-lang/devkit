{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.yamllint ]) apps;
  text = pkgs.writeText "text";
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = apps.setup-files.program;
        command = apps.check-yamllint.program;
      }
      // arguments
    );
in
lib.mapAttrs case {
  # yamllint requires indentSize spaces, from devkit's library.
  two-spaces.files."file.yaml" = text "a:\n  b: 1\n";
  four-spaces = {
    files."file.yaml" = text "a:\n    b: 1\n";
    status = 1;
    output = [ "wrong indentation: expected 2 but found 4" ];
  };
}
