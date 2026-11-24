{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit = {
        files.".editorconfig" = import ./file.nix;
        checks.editorconfig = {
          packages = [ pkgs.editorconfig-checker ];
          command = "editorconfig-checker";
        };
      };
    };
}
