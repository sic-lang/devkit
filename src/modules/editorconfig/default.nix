{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit = {
        files.".editorconfig" = {
          template = ./editorconfig.in;
          replacements.lineLength = toString (import ../../lib.nix).lineLength;
        };
        checks.editorconfig = {
          packages = [ pkgs.editorconfig-checker ];
          command = "editorconfig-checker";
        };
      };
    };
}
