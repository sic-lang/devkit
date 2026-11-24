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
  # A workflow whose job has the step `step`, given as the lines of a YAML mapping.
  workflow =
    step: text "on: push\njobs:\n  a:\n    runs-on: ubuntu-24.04\n    steps:\n      - ${step}\n";
  case =
    name: arguments:
    repository (
      {
        inherit name;
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
    status = 1;
    output = [ ''"runs-on" section is missing in job "a"'' ];
  };
  # ShellCheck reports the unquoted variable of the step's script as SC2086.
  shellcheck = {
    files.".github/workflows/finding.yml" = workflow "run: echo $1";
    status = 1;
    output = [ "shellcheck reported issue in this script: SC2086" ];
  };
  # pyflakes reports the undefined name of the step's Python.
  pyflakes = {
    files.".github/workflows/finding.yml" = workflow "shell: python\n        run: print(x)";
    status = 1;
    output = [ "pyflakes reported issue in this script" ];
  };
  # actionlint finds no workflow directory, so a repository without workflows does not import the
  # module.
  no-workflows = {
    status = 3;
    output = [ "no project was found" ];
  };
}
