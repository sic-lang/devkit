{
  imports = [ ../files ];

  perSystem =
    { pkgs, ... }:
    {
      devkit = {
        files.".yamllint.yaml".template = ./yamllint.yaml;
        checks.yamllint = {
          tools = [ pkgs.yamllint ];
          command = "yamllint --strict .";
        };
      };
    };
}
