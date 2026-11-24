{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    {
      # nixpkgs' actionlint puts ShellCheck and pyflakes on its PATH, so the check needs no other
      # package to lint the scripts of the steps.
      devkit.checks.actionlint = {
        packages = [ pkgs.actionlint ];
        command = "actionlint";
      };
    };
}
