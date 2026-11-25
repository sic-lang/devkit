{
  consumer,
  flakeModules,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.direnv ]) apps;
  envrc = pkgs.writeText "envrc" "# shellcheck shell=bash\nuse flake\n";
in
{
  writes = repository {
    name = "writes";
    command = apps.setup-files.program;
    output = [ "created .envrc" ];
    after = "cmp ${envrc} .envrc";
  };
}
