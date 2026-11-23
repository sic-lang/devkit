{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [ ../files ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      cfg = config.devkit;
    in
    {
      options.devkit.yamllint.lineLength = mkOption {
        description = "The maximum line length of YAML files.";
        type = types.ints.positive;
        default = cfg.lineLength;
        defaultText = lib.literalExpression "config.devkit.lineLength";
      };

      config.devkit = {
        files.".yamllint.yaml" = pkgs.replaceVars ./yamllint.yaml.in {
          lineLength = toString cfg.yamllint.lineLength;
        };
        checks.yamllint = {
          tools = [ pkgs.yamllint ];
          command = "yamllint --strict .";
        };
      };
    }
  );
}
