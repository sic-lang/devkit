{
  consumer,
  flakeModules,
  lib,
  pkgs,
  ...
}:
let
  # The script of a check whose command line is `command`.
  script =
    command:
    (consumer [
      flakeModules.checks
      { perSystem.devkit.checks.example.command = command; }
    ]).commands.check-example.command.run;
  # Builds the script of `command`, which must fail with each line of `output` in its log.
  failure =
    name: command: output:
    pkgs.runCommand name { } ''
      log=${pkgs.testers.testBuildFailure (script command)}/testBuildFailure.log
      cat "$log"
      ${lib.concatMapStrings (line: ''
        grep -qF -- ${lib.escapeShellArg line} "$log"
      '') output}
      touch "$out"
    '';
in
{
  clean = script "if true; then\n  echo \"$1\"\nfi";
  shellcheck = failure "shellcheck" "echo $1" [ "SC2086" ];
  syntax = failure "syntax" "if true; then" [ "syntax error" ];
  shfmt = failure "shfmt" "if true;then\n  echo \"$1\"\nfi" [
    "--- check-example.orig"
    "+if true; then"
  ];
  # shfmt indents with indentSize spaces, from devkit's library.
  shfmt-tab = failure "shfmt-tab" "if true; then\n\techo \"$1\"\nfi" [ "+  echo \"$1\"" ];
}
