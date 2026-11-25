{ lib, ... }@args:
let
  inherit (import ../../libs/yaml.nix args)
    case
    failure
    setup
    text
    ;
  clean = text "a:\n  b: 1\n";
  wrong = text "a:\n    b: 1\n";
in
lib.mapAttrs case {
  yml = {
    files."file.yml" = wrong;
    status = failure;
    output = [ "file.yml" ];
  };
  nested = {
    files."directory/file.yaml" = wrong;
    status = failure;
    output = [ "directory/file.yaml" ];
  };
  untracked = {
    files."file.yaml" = clean;
    before = "${setup} && cp ${wrong} untracked.yaml";
  };
  other-extension.files."file.txt" = wrong;
}
