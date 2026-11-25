{ lib, ... }@args:
let
  inherit (import ../../libs/yaml.nix args) case failure text;
in
lib.mapAttrs case {
  # yamllint requires indentSize spaces, from devkit's library.
  two-spaces.files."file.yaml" = text "a:\n  b: 1\n";
  four-spaces = {
    files."file.yaml" = text "a:\n    b: 1\n";
    status = failure;
    output = [ "wrong indentation: expected 2 but found 4" ];
  };
}
