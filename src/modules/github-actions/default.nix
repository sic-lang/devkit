# devkit's flake, whose commit the generated workflow pins.
{ devkit }:
{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
  inherit (import ../../lib.nix) repository;
in
{
  imports = [
    ../checks
    ../files
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      inherit (config.devkit.github-actions) flakeChecksWorkflow;
    in
    {
      options.devkit.github-actions.flakeChecksWorkflow = mkOption {
        description = ''
          The reference to devkit's reusable workflow `flake-checks.yml` that the generated
          workflow `.github/workflows/checks.yml` calls, or null to generate no workflow. It
          defaults to the workflow at the commit of devkit that the flake locks, or to null if no
          commit holds that version of devkit.
        '';
        type = types.nullOr types.str;
        default =
          if devkit ? rev then
            "${repository}/.github/workflows/flake-checks.yml@${devkit.rev}"
          else
            lib.warn (
              "devkit is at a version that no commit holds, such as a working tree with changes,"
              + " so the github-actions module does not generate .github/workflows/checks.yml"
            ) null;
      };

      config.devkit = {
        files.".github/workflows/checks.yml" = lib.mkIf (flakeChecksWorkflow != null) {
          template = ./checks.yml.in;
          replacements = { inherit flakeChecksWorkflow; };
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
