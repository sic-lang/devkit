{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    {
      # nixpkgs' actionlint runs ShellCheck on the scripts of the steps, and pyflakes on their
      # Python.
      devkit.checks.actionlint = {
        packages = [ pkgs.actionlint ];
        command = "actionlint";
      };
    };
}
