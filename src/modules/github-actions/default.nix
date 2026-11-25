{
  imports = [ ../checks ];

  perSystem =
    { pkgs, ... }:
    {
      # Without files, actionlint also checks the workflows that Git does not track.
      devkit.checks.actionlint = import ../checks/tracked-files.nix pkgs {
        pathspecs = [
          ".github/workflows/*.yaml"
          ".github/workflows/*.yml"
        ];
        command = "actionlint";
        packages = [ pkgs.actionlint ];
      };
    };
}
