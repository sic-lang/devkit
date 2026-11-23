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
  inherit
    (consumer [
      flakeModules.setups
      {
        perSystem =
          { config, ... }:
          {
            devkit.setups.example = {
              description = "Write the example";
              command = config.devkit.mkSetup {
                name = "setup-example";
                mode = "644";
                files."example/file.txt" = recommended;
              };
            };
          };
      }
    ])
    apps
    ;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        command = apps.setup-example.program;
      }
      // arguments
    );
in
lib.mapAttrs case {
  created = {
    output = [ "created" ];
    after = "cmp example/file.txt ${recommended}";
  };
  up-to-date = {
    files."example/file.txt" = recommended;
    output = [ "up to date" ];
  };
  kept = {
    files."example/file.txt" = other;
    status = 1;
    output = [
      "+The recommended text."
      "kept"
      "overwrite it with --force"
    ];
    after = "cmp example/file.txt ${other}";
  };
  forced = {
    files."example/file.txt" = other;
    arguments = [ "--force" ];
    output = [ "overwritten" ];
    after = "cmp example/file.txt ${recommended}";
  };
  bad-argument = {
    arguments = [ "--other" ];
    status = 2;
    output = [ "usage: setup-example [--force]" ];
    after = "[ ! -e example ]";
  };
}
