{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.yaml ]) apps;
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
  # yamllint limits lines to lineLength characters, from devkit's library.
  long-words = {
    files."file.yaml" = text "a: ${lib.concatStringsSep " " (lib.replicate 50 "b")}\n";
    status = 1;
    output = [ "line too long (102 > 100 characters)" ];
  };
  long-value.files."file.yaml" = text "a: ${lib.concatStrings (lib.replicate 100 "b")}\n";
}
