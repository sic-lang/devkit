{
  consumer,
  flakeModules,
  lib,
  repository,
  ...
}:
let
  # jq and yq receive indentSize, from devkit's library, which equals their default, so each case
  # reads it from the command that builds a file rather than from the file's indentation.
  case =
    format:
    let
      path = "file.${format}";
      inherit
        (consumer [
          flakeModules.files
          {
            perSystem =
              { config, ... }:
              {
                devkit.files.${path}.source = config.devkit.formats.${format}.generate path {
                  a = 1;
                };
              };
          }
        ])
        files
        ;
    in
    repository {
      name = "${format}-indent";
      command = "grep -qF -- '--indent 2' <<<";
      arguments = [ files.${path}.source.buildCommand ];
    };
in
lib.genAttrs [ "json" "yaml" ] case
