# devkit's flake, whose commit the generated workflow pins.
{ devkit }:
{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
  commit =
    devkit.rev or (throw (
      "devkit.github-actions.flakeChecks pins flake-checks.yml to the commit of devkit that the"
      + " flake locks, but devkit's flake has none, as when it is a path or a Git working tree"
      + " with changes: lock devkit at a commit"
    ));
in
{
  imports = [
    ../checks
    ../files
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    {
      options.devkit.github-actions.flakeChecks = mkOption {
        description = ''
          The reference to devkit's reusable workflow `flake-checks.yml` that the generated
          workflow `.github/workflows/checks.yml` calls. It defaults to the workflow at the commit
          of devkit that the flake locks.
        '';
        type = types.str;
        default = "sic-lang/devkit/.github/workflows/flake-checks.yml@${commit}";
      };

      config.devkit = {
        files.".github/workflows/checks.yml" = {
          template = ./checks.yml.in;
          replacements = { inherit (config.devkit.github-actions) flakeChecks; };
        };
        # Without files, actionlint also checks the workflows that Git does not track.
        checks.actionlint = (import ../checks/tracked-files.nix pkgs).check {
          pathspecs = [
            ".github/workflows/*.yaml"
            ".github/workflows/*.yml"
          ];
          command = "actionlint";
          packages = [ pkgs.actionlint ];
        };
      };
    }
  );
}
