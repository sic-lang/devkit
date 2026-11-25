{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.github-actions ]) apps;
  text = pkgs.writeText "text";
  # The status of xargs when the command it runs fails.
  failure = 123;
  # A workflow whose job has the step `step`, given as the lines of a YAML mapping.
  workflow =
    step: text "on: push\njobs:\n  a:\n    runs-on: ubuntu-24.04\n    steps:\n      - ${step}\n";
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = "git add -A";
        command = apps.check-actionlint.program;
      }
      // arguments
    );
in
lib.mapAttrs case {
  valid.files.".github/workflows/valid.yml" = workflow ''run: echo "$1"'';
  # actionlint reads the .yaml extension as well.
  no-runs-on = {
    files.".github/workflows/invalid.yaml" =
      text "on: push\njobs:\n  a:\n    steps:\n      - run: echo\n";
    status = failure;
    output = [ ''"runs-on" section is missing in job "a"'' ];
  };
  # The check relies on actionlint to lint the scripts of the steps, which devkit would otherwise
  # need a check of its own for.
  # ShellCheck reports the unquoted variable of the step's script as SC2086.
  shellcheck = {
    files.".github/workflows/finding.yml" = workflow "run: echo $1";
    status = failure;
    output = [ "shellcheck reported issue in this script: SC2086" ];
  };
  # The same for the Python of the steps: pyflakes reports the undefined name.
  pyflakes = {
    files.".github/workflows/finding.yml" = workflow "shell: python\n        run: print(x)";
    status = failure;
    output = [ "pyflakes reported issue in this script" ];
  };
  untracked = {
    files.".github/workflows/valid.yml" = workflow ''run: echo "$1"'';
    before = "git add -A && cp ${workflow "run: echo $1"} .github/workflows/untracked.yml";
  };
  # actionlint finds no workflow directory, so a repository without workflows does not import the
  # module.
  no-workflows = {
    status = failure;
    output = [ "no project was found" ];
  };
}
