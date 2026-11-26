# devkit's flake, whose commit the generated workflow pins.
{ devkit }:
{ flake-parts-lib, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ../checks
    ../files
  ];

  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, pkgs, ... }:
    let
      inherit (config.devkit.github-actions) flakeChecksWorkflow settings;
      inherit (config.devkit.formats) yaml;
    in
    {
      options.devkit.github-actions.settings = mkOption {
        description = ''
          The workflow `.github/workflows/checks.yml`, which the module writes with devkit's own
          settings when it generates the workflow.
        '';
        type = yaml.type;
        default = { };
      };

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
            "sic-lang/devkit/.github/workflows/flake-checks.yml@${devkit.rev}"
          else
            lib.warn (
              "devkit is at a version that no commit holds, such as a working tree with changes,"
              + " so the github-actions module does not generate .github/workflows/checks.yml"
            ) null;
      };

      config.devkit = {
        github-actions.settings = lib.mkIf (flakeChecksWorkflow != null) {
          name = "Checks";
          on = {
            merge_group = null;
            pull_request = null;
            push.branches = [ "main" ];
          };
          jobs.flake.uses = flakeChecksWorkflow;
        };
        files.".github/workflows/checks.yml" = lib.mkIf (flakeChecksWorkflow != null) {
          source = yaml.generate "checks.yml" settings;
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
