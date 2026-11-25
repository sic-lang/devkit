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
        # Without files, editorconfig-checker also checks the files that Git does not track.
        checks.editorconfig = (import ../checks/tracked-files.nix pkgs).check {
          command = "editorconfig-checker";
          packages = [ pkgs.editorconfig-checker ];
        };
      };
    };
}
