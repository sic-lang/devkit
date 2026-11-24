{
  consumer,
  flakeModules,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.editorconfig ]) apps;
in
{
  writes = repository {
    name = "writes";
    command = apps.setup-files.program;
    output = [ "created .editorconfig" ];
    after = "sed s/@lineLength@/100/ ${../../../src/modules/editorconfig/editorconfig.in} | cmp - .editorconfig";
  };
}
