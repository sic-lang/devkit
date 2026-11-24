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
    after = "grep -qx 'root = true' .editorconfig";
  };
}
