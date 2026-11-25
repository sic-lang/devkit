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
  template = ../../../src/modules/github-actions/checks.yml.in;
  reference = "sic-lang/devkit/.github/workflows/flake-checks.yml@${revision}";
in
{
  writes = repository {
    name = "writes";
    command = apps.setup-files.program;
    output = [ "created .github/workflows/checks.yml" ];
    after = ''
      sed 's|@flakeChecksWorkflow@|${reference}|' ${template} | cmp - .github/workflows/checks.yml
    '';
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
