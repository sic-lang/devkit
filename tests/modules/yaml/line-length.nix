{ lib, ... }@args:
let
  inherit (import ../../libs/yaml.nix args) case failure text;
in
lib.mapAttrs case {
  # yamllint limits lines to lineLength characters, from devkit's library.
  long-words = {
    files."file.yaml" = text "a: ${lib.concatStringsSep " " (lib.replicate 50 "b")}\n";
    status = failure;
    output = [ "line too long (102 > 100 characters)" ];
  };
  long-value.files."file.yaml" = text "a: ${lib.concatStrings (lib.replicate 100 "b")}\n";
}
