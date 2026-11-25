{
  consumer,
  flakeModules,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.direnv ]) apps;
  template = ../../../src/modules/direnv/envrc.in;
in
{
  writes = repository {
    name = "writes";
    command = apps.setup-files.program;
    output = [ "created .envrc" ];
    after = "cmp ${template} .envrc";
  };
}
