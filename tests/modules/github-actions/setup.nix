{
  consumer,
  modules,
  pkgs,
  repository,
  ...
}:
let
  revision = "0123456789abcdef0123456789abcdef01234567";
  inherit (consumer [ (modules { rev = revision; }).github-actions ]) apps;
  # The workflow that the module writes, with `pullRequest` as the settings of its trigger.
  workflowWith =
    pullRequest:
    pkgs.writeText "checks.yml" ''
      jobs:
        flake:
          uses: sic-lang/devkit/.github/workflows/flake-checks.yml@${revision}
      name: Checks
      on:
        merge_group: {}
        pull_request:${pullRequest}
        push:
          branches:
            - main
    '';
  workflow = workflowWith " {}";
in
{
  writes = repository {
    name = "writes";
    command = apps.setup-files.program;
    output = [ "created .github/workflows/checks.yml" ];
    after = "cmp ${workflow} .github/workflows/checks.yml";
  };
  # The repository's settings add to a trigger of the module.
  merges = repository {
    name = "merges";
    command =
      (consumer [
        (modules { rev = revision; }).github-actions
        { perSystem.devkit.github-actions.settings.on.pull_request.branches = [ "main" ]; }
      ]).apps.setup-files.program;
    output = [ "created .github/workflows/checks.yml" ];
    after = "cmp ${workflowWith "\n    branches:\n      - main"} .github/workflows/checks.yml";
  };
  # The option defaults to null at a version of devkit that no commit holds.
  # Setting it here tests the same setup without the warning of that default.
  without-workflow =
    let
      inherit (modules { rev = revision; }) github-actions yaml;
      inherit
        (consumer [
          github-actions
          yaml
          { perSystem.devkit.github-actions.flakeChecksWorkflow = null; }
        ])
        apps
        ;
      workflow = pkgs.writeText "checks.yml" "Any content.\n";
    in
    repository {
      name = "without-workflow";
      files.".github/workflows/checks.yml" = workflow;
      before = "git add -A";
      command = apps.setup-files.program;
      output = [ "created .yamllint.yaml" ];
      after = ''
        cmp ${workflow} .github/workflows/checks.yml
        git add -A
        ${apps.check-files.program}
      '';
    };
}
