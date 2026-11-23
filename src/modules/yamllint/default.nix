{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit = {
        files.".yamllint.yaml" = {
          template = ./yamllint.yaml.in;
          replacements.lineLength = toString (import ../../lib.nix).lineLength;
        };
        checks.yamllint = {
          packages = [ pkgs.yamllint ];
          command = "yamllint --strict .";
        };
      };
    };
}
