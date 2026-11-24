{
  consumer,
  flakeModules,
  lib,
  pkgs,
  ...
}:
let
  # The lint of a command whose template is the command line `command`.
  lint =
    command:
    (consumer [
      flakeModules.checks
      { perSystem.devkit.checks.example.command = command; }
    ]).checks.lint-check-example;
  # Builds the lint of `command`, which must fail with each line of `output` in its log.
  failure =
    name: command: output:
    pkgs.runCommand name { } ''
      log=${pkgs.testers.testBuildFailure (lint command)}/testBuildFailure.log
      cat "$log"
      ${lib.concatMapStrings (line: ''
        grep -qF -- ${lib.escapeShellArg line} "$log"
      '') output}
      touch "$out"
    '';
in
{
  clean = lint "if true; then\n  echo \"$1\"\nfi";
  shellcheck = failure "shellcheck" "echo $1" [ "SC2086" ];
  # A syntax error, which ShellCheck rejects without needing Bash.
  syntax = failure "syntax" "if true; then" [ "SC1073" ];
  shfmt = failure "shfmt" "if true;then\n  echo \"$1\"\nfi" [
    "--- check-example.orig"
    "+if true; then"
  ];
  # shfmt indents with indentSize spaces, from devkit's library.
  shfmt-tab = failure "shfmt-tab" "if true; then\n\techo \"$1\"\nfi" [ "+  echo \"$1\"" ];
}
