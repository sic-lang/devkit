{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit = {
        files.".editorconfig".template = ./editorconfig.in;
        checks.editorconfig = {
          packages = [ pkgs.editorconfig-checker ];
          command = "editorconfig-checker";
        };
      };
    };
}
