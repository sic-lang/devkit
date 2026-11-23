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
  # The check of example/file.txt generated as file says.
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
  # A file of the flake rather than of the Nix store: this test itself.
  local = {
    command = check { template = ./check.nix; };
    files."example/file.txt" = ./check.nix;
  };
  # Split so that this file, the template of the local case, has no placeholder.
  replaced = {
    command = check {
      template = pkgs.writeText "file.txt.in" "The @adjective${"@"} text.\n";
      replacements.adjective = "generated";
    };
    files."example/file.txt" = generated;
  };
}
