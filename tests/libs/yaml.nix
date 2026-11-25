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
  # Git tracks the files of a case, and the generated .yamllint.yaml.
  setup = "${apps.setup-files.program} && git add -A";
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
