# The generated workflow passes the check of the module and that of the yaml module, which checks
# every YAML file.
{
  consumer,
  flakeModules,
  lib,
  repository,
  ...
}:
let
  inherit
    (consumer [
      flakeModules.github-actions
      flakeModules.yaml
    ])
    apps
    ;
  case =
    name:
    repository {
      inherit name;
      before = import ../../libs/setup-tracked.nix apps;
      command = apps."check-${name}".program;
    };
in
lib.genAttrs [ "actionlint" "yamllint" ] case
