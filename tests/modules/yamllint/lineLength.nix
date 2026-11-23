{
  consumer,
  flakeModules,
  lib,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.yamllint ]) apps;
in
{
  shared = repository {
    name = "shared";
    command = apps.setup-files.program;
    output = [ "created .yamllint.yaml" ];
    after = "grep -qx ${lib.escapeShellArg "    max: 100"} .yamllint.yaml";
  };
}
