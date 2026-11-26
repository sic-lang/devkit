{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  helper = ../../../sources/modules/checks/tracked-files.nix;
  # The check-<name> app of a check that runs `command` on the files that `pathspecs` selects.
  program =
    name: arguments:
    (consumer [
      flakeModules.checks
      {
        perSystem =
          { pkgs, ... }:
          {
            devkit.checks.${name} = (import helper pkgs).check ({ packages = [ ]; } // arguments);
          };
      }
    ]).apps."check-${name}".program;
  # ls prints the name of each file that it receives, one on each line.
  list = program "list" { command = "ls -d"; };
  selected = program "selected" {
    pathspecs = [
      "*.a"
      "*.b"
    ];
    command = "ls -d";
  };
  failing = program "failing" { command = "false"; };
  text = pkgs.writeText "text" "text\n";
  listed = name: ''grep -qxF -- ${lib.escapeShellArg name} "$TMPDIR/output"'';
  unlisted = name: "if ${listed name}; then exit 1; fi";
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = "git add -A";
        command = list;
      }
      // arguments
      // {
        files = {
          "file.txt" = text;
        }
        // arguments.files or { };
      }
    );
in
lib.mapAttrs case {
  tracked.after = listed "file.txt";
  untracked = {
    before = "git add -A && cp ${text} untracked.txt";
    after = unlisted "untracked.txt";
  };
  deleted = {
    files."deleted.txt" = text;
    before = "git add -A && rm deleted.txt";
    after = unlisted "deleted.txt";
  };
  symbolic-link-to-file = {
    before = "ln -s file.txt link && git add -A";
    after = unlisted "link";
  };
  symbolic-link-to-directory = {
    before = "mkdir directory && ln -s directory link && git add -A";
    after = unlisted "link";
  };
  broken-symbolic-link = {
    before = "ln -s missing link && git add -A";
    after = unlisted "link";
  };
  submodule = {
    files."submodule/file.txt" = text;
    before = ''
      git add file.txt
      git update-index --add --cacheinfo 160000,${lib.strings.replicate 40 "1"},submodule
    '';
    after = unlisted "submodule";
  };
  # Git lists an unmerged path once for each stage of the merge.
  unmerged = {
    before = ''
      git config user.name name
      git config user.email name@example.com
      git add -A
      git commit -q -m base
      git checkout -q -b other
      echo other >file.txt
      git commit -q -a -m other
      git checkout -q -
      echo base >file.txt
      git commit -q -a -m base
      git merge -q other || true
    '';
    after = ''[ "$(grep -cxF file.txt "$TMPDIR/output")" -eq 1 ]'';
  };
  pathspecs = {
    files = {
      "file.a" = text;
      "file.b" = text;
    };
    command = selected;
    after = ''
      ${listed "file.a"}
      ${listed "file.b"}
      ${unlisted "file.txt"}
    '';
  };
  no-file-matches = import ../../libs/no-file.nix // {
    command = selected;
    after = listed "No file to check: Git tracks no regular file that matches *.a or *.b";
  };
  no-file = import ../../libs/no-file.nix // {
    before = "";
    after = listed "No file to check: Git tracks no regular file";
  };
  # The status of git ls-files when it cannot read the index.
  corrupt-index = {
    before = "git add -A && echo corrupt >.git/index";
    status = 128;
    after = ''
      if grep -qF "No file to check" "$TMPDIR/output"; then exit 1; fi
    '';
  };
  failing-command = {
    command = failing;
    status = import ../../libs/xargs-failure.nix;
  };
}
