{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  case =
    name:
    { settings, max }:
    let
      inherit
        (consumer [
          flakeModules.yamllint
          { perSystem.devkit = settings; }
        ])
        apps
        ;
    in
    repository {
      inherit name;
      command = apps.setup-files.program;
      output = [ "created .yamllint.yaml" ];
      after = "grep -qx ${lib.escapeShellArg "    max: ${toString max}"} .yamllint.yaml";
    };
in
lib.mapAttrs case {
  default = {
    settings = { };
    max = 100;
  };
  shared = {
    settings.lineLength = 80;
    max = 80;
  };
  own = {
    settings = {
      lineLength = 80;
      yamllint.lineLength = 120;
    };
    max = 120;
  };
}
