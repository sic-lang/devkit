{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  recommended = pkgs.writeText "file.txt" "The recommended text.\n";
  other = pkgs.writeText "other" "Another text.\n";
  # Two setups, a and b, which run in that order and write the files a and b.
  setup =
    (consumer [
      flakeModules.setups
      {
        perSystem =
          { config, ... }:
          {
            devkit.setups = lib.genAttrs [ "a" "b" ] (name: {
              description = "Write ${name}";
              command = config.devkit.mkSetup {
                name = "setup-${name}";
                mode = "644";
                files.${name} = recommended;
              };
            });
          };
      }
    ]).apps.setup.program;
  # The contributor answers each question with a line of answers.
  case =
    name:
    { answers, ... }@arguments:
    repository (
      {
        inherit name;
        command = "printf '%s\\n' ${lib.escapeShellArgs answers} | ${setup}";
      }
      // removeAttrs arguments [ "answers" ]
    );
in
lib.mapAttrs case {
  confirmed = {
    answers = [
      "y"
      "Y"
    ];
    output = [
      "created a"
      "created b"
    ];
    after = ''
      cmp a ${recommended}
      cmp b ${recommended}
    '';
  };
  # Any answer other than yes skips the setup, even with no answer.
  skipped = {
    answers = [ "n" ];
    after = ''
      test ! -e a
      test ! -e b
    '';
  };
  # A failed setup does not stop the others.
  failed = {
    files.a = other;
    answers = [
      "y"
      "y"
    ];
    status = 1;
    output = [ "kept a" ];
    after = ''
      cmp a ${other}
      cmp b ${recommended}
    '';
  };
  # The arguments go to each setup.
  forced = {
    files.a = other;
    answers = [ "y" ];
    arguments = [ "--force" ];
    output = [ "overwritten a" ];
    after = ''
      cmp a ${recommended}
      test ! -e b
    '';
  };
}
