# The generated workflow passes the checks of the modules that a repository with workflows imports.
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
