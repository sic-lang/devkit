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
  setup =
    source:
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
                files."example/file.txt" = source;
              };
            };
          };
      }
    ]).apps.setup-example.program;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        command = setup recommended;
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
  # Unlike a file of the Nix store, a file of the flake must be copied into it.
  local = {
    command = setup ./mkSetup.nix;
    output = [ "created" ];
    after = "cmp example/file.txt ${./mkSetup.nix}";
  };
}
