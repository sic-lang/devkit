{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.editorconfig ]) apps;
  case =
    name:
    { text, ... }@arguments:
    repository (
      removeAttrs arguments [ "text" ]
      // {
        inherit name;
        files."file.txt" = pkgs.writeText "file.txt" text;
        before = apps.setup-files.program;
        command = apps.check-editorconfig.program;
      }
    );
in
lib.mapAttrs case {
  clean.text = "A clean line.\n";
  trailing-whitespace = {
    text = "A line that ends with a space. \n";
    status = 1;
    output = [ "1: trailing whitespace" ];
  };
}
