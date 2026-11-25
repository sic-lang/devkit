{
  consumer,
  flakeModules,
  repository,
  ...
}:
let
  inherit
    (consumer [
      flakeModules.envrc
      flakeModules.shell
    ])
    apps
    ;
in
{
  passes = repository {
    name = "passes";
    before = import ../../libs/setup-tracked.nix apps;
    command = apps.check.program;
    output = [
      "ok    files"
      "ok    shellcheck"
      "ok    shfmt"
    ];
  };
}
