{
  imports = [ ../files ];

  perSystem =
    { config, pkgs, ... }:
    {
      devkit = {
        files.".yamllint.yaml" = {
          template = ./yamllint.yaml.in;
          replacements.lineLength = toString config.devkit.lineLength;
        };
        checks.yamllint = {
          tools = [ pkgs.yamllint ];
          command = "yamllint --strict .";
        };
      };
    };
}
