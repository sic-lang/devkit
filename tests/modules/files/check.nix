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
  check =
    file:
    (consumer [
      flakeModules.files
      { perSystem.devkit.files."example/file.txt" = file; }
    ]).apps.check-files.program;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        command = check { template = generated; };
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
  # A source is copied as it is, even with what reads as a placeholder.
  verbatim =
    let
      source = pkgs.writeText "file.txt" "The @verbatim@ text.\n";
    in
    {
      command = check { inherit source; };
      files."example/file.txt" = source;
    };
  replaced = {
    command = check {
      template = pkgs.writeText "file.txt.in" "The @adjective@ text.\n";
      replacements.adjective = "generated";
    };
    files."example/file.txt" = generated;
  };
}
