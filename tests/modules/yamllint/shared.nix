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
  values = repository {
    name = "values";
    command = apps.setup-files.program;
    output = [ "created .yamllint.yaml" ];
    after = ''
      grep -qx ${lib.escapeShellArg "    spaces: 2"} .yamllint.yaml
      grep -qx ${lib.escapeShellArg "    max: 100"} .yamllint.yaml
    '';
  };
}
