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
  # A workflow whose job runs the script `script`.
  workflow =
    script:
    text "on: push\njobs:\n  a:\n    runs-on: ubuntu-24.04\n    steps:\n      - run: ${script}\n";
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
  valid.files.".github/workflows/valid.yml" = workflow ''echo "$1"'';
  no-runs-on = {
    files.".github/workflows/invalid.yml" =
      text "on: push\njobs:\n  a:\n    steps:\n      - run: echo\n";
    status = 1;
    output = [ ''"runs-on" section is missing in job "a"'' ];
  };
  # ShellCheck reports the unquoted variable of the step's script as SC2086.
  shellcheck = {
    files.".github/workflows/finding.yml" = workflow "echo $1";
    status = 1;
    output = [ "shellcheck reported issue in this script: SC2086" ];
  };
  # actionlint finds no workflow directory, so a repository without workflows does not import the
  # module.
  no-workflows = {
    status = 3;
    output = [ "no project was found" ];
  };
}
