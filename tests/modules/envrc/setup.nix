{
  consumer,
  flakeModules,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.envrc ]) apps;
  template = ../../../src/modules/envrc/envrc.in;
in
{
  writes = repository {
    name = "writes";
    command = apps.setup-files.program;
    output = [ "created .envrc" ];
    after = "cmp ${template} .envrc";
  };
}
