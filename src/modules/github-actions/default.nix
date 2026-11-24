{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    {
      devkit.checks.actionlint = {
        packages = [ pkgs.actionlint ];
        command = "actionlint";
      };
    };
}
