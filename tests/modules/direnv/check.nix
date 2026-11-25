{
  consumer,
  flakeModules,
  repository,
  ...
}:
let
  # The shell module checks .envrc as a shell script, so the generated file must pass its checks.
  inherit
    (consumer [
      flakeModules.direnv
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
