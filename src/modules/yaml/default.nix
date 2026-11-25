let
  shared = import ../../lib.nix;
in
{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit = {
        files.".yamllint.yaml" = {
          template = ./yamllint.yaml.in;
          replacements = {
            indentSize = toString shared.indentSize;
            lineLength = toString shared.lineLength;
          };
        };
        # Given a directory, yamllint also checks the files that Git does not track.
        checks.yamllint = import ../checks/tracked-files.nix pkgs {
          pathspecs = [
            "*.yaml"
            "*.yml"
          ];
          command = "yamllint --strict";
          packages = [ pkgs.yamllint ];
        };
      };
    };
}
