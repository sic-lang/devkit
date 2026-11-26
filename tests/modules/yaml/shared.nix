{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.yaml ]) apps;
  # The modules of a repository that adds `settings` to yamllint's configuration.
  adding = settings: [
    flakeModules.yaml
    { perSystem.devkit.yaml.settings = settings; }
  ];
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
  # The repository's settings are written with those of the module.
  merges = repository {
    name = "merges";
    command =
      (consumer (adding {
        ignore = "vendor/";
      })).apps.setup-files.program;
    output = [ "created .yamllint.yaml" ];
    after = ''
      grep -qx ${lib.escapeShellArg "ignore: vendor/"} .yamllint.yaml
      grep -qx ${lib.escapeShellArg "    spaces: 2"} .yamllint.yaml
    '';
  };
  # A setting that the module sets to another value fails the evaluation of the flake.
  conflict =
    assert
      !(builtins.tryEval
        (consumer (adding {
          rules.indentation.spaces = 4;
        })).apps.setup-files.program
      ).success;
    pkgs.emptyFile;
}
