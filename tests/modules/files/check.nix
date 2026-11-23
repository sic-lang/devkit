{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  generated = pkgs.writeText "file.txt" "The generated text.\n";
  other = pkgs.writeText "other" "Another text.\n";
  inherit
    (consumer [
      flakeModules.files
      { perSystem.devkit.files."example/file.txt" = generated; }
    ])
    apps
    ;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        command = apps.check-files.program;
      }
      // arguments
    );
in
lib.mapAttrs case {
  up-to-date.files."example/file.txt" = generated;
  missing = {
    status = 1;
    output = [ "example/file.txt is missing: run setup-files to write it" ];
  };
  differs = {
    files."example/file.txt" = other;
    status = 1;
    output = [
      "+The generated text."
      "example/file.txt differs from the generated one above"
    ];
  };
}
