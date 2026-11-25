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
  # Without a commit of devkit, the apps that need the generated files fail to evaluate, but the
  # check of the workflows does not.
  no-revision =
    let
      inherit (consumer [ (modules { }).github-actions ]) apps;
      evaluates = app: (builtins.tryEval apps.${app}.program).success;
    in
    assert !evaluates "setup-files" && !evaluates "check-files" && evaluates "check-actionlint";
    pkgs.writeText "no-revision" "";
}
