# The helpers that the test files of the yaml module share.
{
  consumer,
  flakeModules,
  pkgs,
  repository,
  ...
}:
let
  inherit (consumer [ flakeModules.yaml ]) apps;
in
rec {
  text = pkgs.writeText "text";
  failure = import ./xargs-failure.nix;
  setup = import ./setup-tracked.nix apps;
  case =
    name: arguments:
    repository (
      {
        inherit name;
        before = setup;
        command = apps.check-yamllint.program;
      }
      // arguments
    );
}
