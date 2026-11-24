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
        checks.yamllint = {
          packages = [ pkgs.yamllint ];
          command = "yamllint --strict .";
        };
      };
    };
}
