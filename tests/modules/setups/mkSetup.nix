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
    arguments:
    (consumer [
      flakeModules.setups
      {
        perSystem =
          { config, ... }:
          {
            devkit.setups.example = {
              description = "Write the example";
              command = config.devkit.mkSetup (
                {
                  name = "setup-example";
                  mode = "644";
                  files."example/file.txt" = recommended;
                }
                // arguments
              );
            };
          };
      }
    ]).apps.setup-example.program;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        command = setup { };
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
      "kept example/file.txt, which differs from the file that setup-example writes"
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
  # Unlike a file from the Nix store, a file from the flake must be copied into it.
  local = {
    command = setup { files."example/file.txt" = ./mkSetup.nix; };
    output = [ "created" ];
    after = "cmp example/file.txt ${./mkSetup.nix}";
  };
  # A directory that only the setup's run gives, as the hooks directory of the clone.
  directory = {
    command = setup { directory = ''"$(git rev-parse --absolute-git-dir)"''; };
    output = [ "created" ];
    after = ''
      cmp .git/example/file.txt ${recommended}
      [ ! -e example ]
    '';
  };
}
