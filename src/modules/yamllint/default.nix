{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit = {
        files.".yamllint.yaml" = ./yamllint.yaml;
        checks.yamllint = {
          tools = [ pkgs.yamllint ];
          command = "yamllint --strict .";
        };
      };
    };
}
