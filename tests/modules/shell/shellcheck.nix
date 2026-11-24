{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.shell ]) apps;
  text = pkgs.writeText "text";
  clean = text "#!/usr/bin/env bash\necho \"$1\"\n";
  # ShellCheck reports the unquoted variable as SC2086.
  finding = text "#!/usr/bin/env bash\necho $1\n";
  envrc = text "# shellcheck shell=bash\nuse flake\n";
  # The status of xargs when the command it runs fails.
  failure = 123;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = "git add -A";
        command = apps.check-shellcheck.program;
      }
      // arguments
    );
in
lib.mapAttrs case {
  clean.files = {
    ".envrc" = envrc;
    "script.sh" = clean;
  };
  finding = {
    files."script.sh" = finding;
    status = failure;
    output = [ "In script.sh line 2:" ];
  };
  envrc = {
    files.".envrc" = text "use flake\n";
    status = failure;
    output = [ "SC2148" ];
  };
  nested = {
    files."directory/script.sh" = finding;
    status = failure;
    output = [ "In directory/script.sh line 2:" ];
  };
  space-in-name = {
    files."a script.sh" = finding;
    status = failure;
    output = [ "In a script.sh line 2:" ];
  };
  untracked = {
    files."script.sh" = clean;
    before = "git add -A && install -m 644 ${finding} untracked.sh";
  };
  other-extension.files = {
    "script.sh" = clean;
    "script.bash" = finding;
  };
  no-script = {
    status = failure;
    output = [ "No files specified." ];
  };
}
