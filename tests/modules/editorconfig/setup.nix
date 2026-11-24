{
  consumer,
  flakeModules,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.editorconfig ]) apps;
  template = ../../../src/modules/editorconfig/editorconfig.in;
in
{
  writes = repository {
    name = "writes";
    command = apps.setup-files.program;
    output = [ "created .editorconfig" ];
    after = "sed 's/@indentSize@/2/; s/@lineLength@/100/' ${template} | cmp - .editorconfig";
  };
}
