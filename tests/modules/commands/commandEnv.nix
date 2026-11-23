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
          commandEnv = args: lib.optionalAttrs (lib.elem pkgs.hello args.tools) example;
          checks = {
            with-hello = {
              tools = [ pkgs.hello ];
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
  with-tool = repository {
    name = "with-tool";
    command = apps.check-with-hello.program;
    output = [ "EXAMPLE=it's set" ];
  };
  without-tool = repository {
    name = "without-tool";
    command = apps.check-without-hello.program;
    output = [ "EXAMPLE=unset" ];
  };
  # The check command is built without tools.
  all = repository {
    name = "all";
    command = apps.check.program;
    output = [
      "ok    with-hello"
      "ok    without-hello"
    ];
  };
}
