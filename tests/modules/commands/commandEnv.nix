{
  consumer,
  flakeModules,
  lib,
  pkgs,
  repository,
  ...
}:
let
  example.EXAMPLE = "it's set";
  print = ''echo "EXAMPLE=''${EXAMPLE-unset}"'';
  inherit
    (consumer [
      flakeModules.checks
      {
        perSystem.devkit = {
          commandEnv = args: lib.optionalAttrs (lib.elem pkgs.hello args.packages) example;
          checks = {
            with-hello = {
              packages = [ pkgs.hello ];
              command = print;
            };
            without-hello.command = print;
          };
        };
      }
    ])
    apps
    ;
in
{
  with-package = repository {
    name = "with-package";
    command = apps.check-with-hello.program;
    output = [ "EXAMPLE=it's set" ];
  };
  without-package = repository {
    name = "without-package";
    command = apps.check-without-hello.program;
    output = [ "EXAMPLE=unset" ];
  };
  # The check command is built without packages, which commandEnv must still receive.
  all = repository {
    name = "all";
    command = apps.check.program;
    output = [
      "ok    with-hello"
      "ok    without-hello"
    ];
  };
}
