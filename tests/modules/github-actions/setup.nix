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
  # At a version of devkit that no commit holds, the setup writes the other generated files and
  # leaves the committed workflow alone.
  no-revision =
    let
      inherit (modules { }) github-actions yaml;
      inherit
        (consumer [
          github-actions
          yaml
        ])
        apps
        ;
      workflow = pkgs.writeText "checks.yml" "Any content.\n";
    in
    repository {
      name = "no-revision";
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
