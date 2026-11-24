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
  text = pkgs.writeText "text";
  line = length: text "${lib.strings.replicate length "a"}\n";
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = apps.setup-files.program;
        command = apps.check-editorconfig.program;
      }
      // arguments
    );
in
lib.mapAttrs case {
  clean.files."file.txt" = text "A clean line.\n";
  trailing-whitespace = {
    files."file.txt" = text "A line that ends with a space. \n";
    status = 1;
    output = [ "1: trailing whitespace" ];
  };
  odd-indentation = {
    files."file.txt" = text "a\n   b\n";
    status = 1;
    output = [ "wrong amount of left-padding spaces" ];
  };
  tab = {
    files."file.txt" = text "a\n\tb\n";
    status = 1;
    output = [ "wrong indent style found (tabs instead of spaces)" ];
  };
  crlf = {
    files."file.txt" = text "a\r\nb\r\n";
    status = 1;
    output = [ "not all lines have the correct end of line character" ];
  };
  no-final-newline = {
    files."file.txt" = text "a";
    status = 1;
    output = [ "wrong line endings or no final newline" ];
  };
  long-line = {
    files."file.txt" = line 101;
    status = 1;
    output = [ "1: line too long (101 instead of 100)" ];
  };
  longest-line.files."file.txt" = line 100;
  markdown-list.files."list.md" = text "1. a\n   b\n";
  long-markdown-line.files."file.md" = line 101;
  long-yaml-line.files = {
    "file.yaml" = line 101;
    "file.yml" = line 101;
  };
  license-text.files."LICENSES/X.txt" = text "a\n   b\n";
  long-license-line.files."LICENSES/X.txt" = line 101;
}
