let
  shared = import ../../lib.nix;
in
{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit = {
        files.".editorconfig" = {
          template = ./editorconfig.in;
          replacements = {
            indentSize = toString shared.indentSize;
            lineLength = toString shared.lineLength;
          };
        };
        checks.editorconfig = {
          packages = [ pkgs.editorconfig-checker ];
          command = "editorconfig-checker";
        };
      };
    };
}
