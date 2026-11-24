{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  # shfmt takes its indentation from the .editorconfig that the editorconfig module writes.
  inherit
    (consumer [
      flakeModules.editorconfig
      flakeModules.shell
    ])
    apps
    ;
  text = pkgs.writeText "text";
  clean = text "if true; then\n  echo a\nfi\n";
  unformatted = text "if true;then\n  echo a\nfi\n";
  tab = text "if true; then\n\techo a\nfi\n";
  setup = "${apps.setup-files.program} && git add -A";
  # The status of xargs when the command it runs fails.
  failure = 123;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = setup;
        command = apps.check-shfmt.program;
      }
      // arguments
    );
in
lib.mapAttrs case {
  clean.files = {
    ".envrc" = clean;
    "script.sh" = clean;
  };
  unformatted = {
    files."script.sh" = unformatted;
    status = failure;
    output = [
      "--- script.sh.orig"
      "+if true; then"
    ];
  };
  envrc = {
    files.".envrc" = unformatted;
    status = failure;
    output = [ "--- .envrc.orig" ];
  };
  tab = {
    files."script.sh" = tab;
    status = failure;
    output = [ "+  echo a" ];
  };
  untracked = {
    files."script.sh" = clean;
    before = "${setup} && install -m 644 ${unformatted} untracked.sh";
  };
  no-script.status = failure;
}
// {
  # Without .editorconfig, shfmt indents with tabs.
  no-editorconfig = repository {
    name = "no-editorconfig";
    files."script.sh" = tab;
    before = "git add -A";
    command = (consumer [ flakeModules.shell ]).apps.check-shfmt.program;
  };
}
