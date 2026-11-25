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
  clean = text "if true; then\n  echo a\nfi\n";
  unformatted = text "if true;then\n  echo a\nfi\n";
  tab = text "if true; then\n\techo a\nfi\n";
  failure = import ../../libs/xargs-failure.nix;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = "git add -A";
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
  nested = {
    files."directory/script.sh" = unformatted;
    status = failure;
    output = [ "--- directory/script.sh.orig" ];
  };
  space-in-name = {
    files."a script.sh" = unformatted;
    status = failure;
    output = [ "--- a script.sh.orig" ];
  };
  # The file's name starts with a dash, which shfmt must not read as an option.
  dash-in-name = {
    files."./-x.sh" = unformatted;
    status = failure;
    output = [ "--- -x.sh.orig" ];
  };
  untracked = {
    files."script.sh" = clean;
    before = "git add -A && install -m 644 ${unformatted} untracked.sh";
  };
  other-extension.files = {
    "script.sh" = clean;
    "script.bash" = unformatted;
  };
  # Without a script, xargs runs shfmt once without a file, so shfmt reads its empty input.
  no-script = {
    status = failure;
    output = [ "<standard input>" ];
  };
  # The indentation comes from devkit's library, whatever .editorconfig says.
  editorconfig-ignored = {
    files = {
      ".editorconfig" = text "root = true\n\n[*]\nindent_style = tab\n";
      "script.sh" = tab;
    };
    status = failure;
    output = [ "+  echo a" ];
  };
}
